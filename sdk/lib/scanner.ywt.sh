#!/usr/bin/env bash
# shellcheck disable=SC2317,SC2120,SC2155,SC2044
scanner() {
    local SCANNER_NAME="$1" && shift && SCANNER_NAME="${SCANNER_NAME,,}" && SCANNER_NAME="${SCANNER_NAME// /-}" && SCANNER_NAME="${SCANNER_NAME//./-}" && SCANNER_NAME="${SCANNER_NAME//:/-}" && SCANNER_NAME="${SCANNER_NAME//\//-}"
    local SCANNER_UID="$(mktemp -u -t XXXXXXXXXXXXXX -p /tmp)" && SCANNER_UID="$(basename "$SCANNER_UID")" && SCANNER_UID="${SCANNER_UID//./-}"
    local SCANNER_ID="$(echo -n "$SCANNER_NAME" | base64)${SCANNER_UID}"
    local SCANNER_OUTPUT="/tmp/scanner-${SCANNER_UID}.ywt"
    __scanner:result() {
        {
            echo -n "{"
            if [ ! -f "$SCANNER_OUTPUT" ]; then
                echo -n "\"format\":\"text\","
                echo -n "\"content\":\"No output\","
            elif jq . "$SCANNER_OUTPUT" >/dev/null 2>&1; then
                echo -n "\"format\":\"json\","
                echo -n "\"content\":$(jq . "$SCANNER_OUTPUT"),"
            else
                echo -n "\"format\":\"text\","
                local SCANNER_CONTENT="$(
                    {
                        cat "$SCANNER_OUTPUT"
                    } | sed 's/"/\\"/g' |
                        awk '{ printf "%s\\n", $0 }' |
                        awk '{ gsub("\t", "\\t", $0); print $0 }' |
                        sed 's/^/  /'
                )"
                echo -n "\"content\":\"$SCANNER_CONTENT\","
            fi
            echo -n "\"end\":$(date +%s)"
            echo -n "}"
        } | jq -c .
    }
    __scanner:cli() {
        local SCANNER_METADATA="$1" && shift
        ! __is json "$SCANNER_METADATA" && SCANNER_METADATA="$(__scanner:"${SCANNER_NAME}" metadata)"
        local DOCKER_ARGS=(
            "--rm"
            "--name" "ywt-scanners-${SCANNER_UID}"
            "-v" "$(pwd):/ywt-workdir"
            "-v" "/var/run/docker.sock:/var/run/docker.sock"
            "-v" "/tmp:/tmp"
            "ywt-sca:latest"
        )
        local SCANNER_ATTEMPTS=()
        local SCANNER_ENGINES=(host docker npx)
        for SCANNER_ENGINE in "${SCANNER_ENGINES[@]}"; do
            [ "$(jq -r '.engines[]' <<<"$SCANNER_METADATA" | grep -c "$SCANNER_ENGINE")" -eq 0 ] && continue
            # echo "SCANNER_ENGINE: $SCANNER_ENGINE"
            if [ "$SCANNER_ENGINE" == "host" ] &&
                [ "$(jq -r '.engines[]' <<<"$SCANNER_METADATA" | grep -c "$SCANNER_ENGINE")" -gt 0 ] &&
                __is command "$SCANNER_NAME"; then
                SCANNER_ENGINE="host"
                "$SCANNER_NAME" "$@" &>"$SCANNER_OUTPUT"
                break
            elif [ "$SCANNER_ENGINE" == "docker" ] && __is command docker; then
                SCANNER_ENGINE="docker"
                docker run "${DOCKER_ARGS[@]}" "$SCANNER_NAME" "$@" &>"$SCANNER_OUTPUT"
                break
            elif [ "$SCANNER_ENGINE" == "npx" ] && __is command npx; then
                SCANNER_ENGINE="npx"
                npx "$SCANNER_NAME" "$@" &>"$SCANNER_OUTPUT"
                break
            else
                SCANNER_ATTEMPTS+=("$SCANNER_ENGINE")
                continue
            fi
        done
        local SCANNER_EXIT_CODE=$?
        {
            echo -n "{"
            echo -n "\"engine\":\"$SCANNER_ENGINE\","
            echo -n "\"exit_code\":$SCANNER_EXIT_CODE,"
            echo -n "\"args\":\"$*\","
            echo -n "\"data\":$(__scanner:result),"
            if [ "$SCANNER_EXIT_CODE" -ne 0 ]; then
                echo -n "\"error\":\"$SCANNER_ENGINE not found\""
            else
                echo -n "\"success\":true"
            fi
            # if [ "${#SCANNER_ATTEMPTS[@]}" -gt 0 ]; then
            #     echo -n "\"error\":\"${SCANNER_ATTEMPTS[*]} not found\""
            # else
            #     echo -n "\"success\":true"
            # fi
            echo -n "}"
        } | jq -c .
        return 0
    }
    __scanner:info() {
        {
            echo -n "{"
            echo -n "\"id\":\"$SCANNER_ID\","
            echo -n "\"output\":\"${SCANNER_OUTPUT}\""
            # echo -n "\"start\":${SCANNER_START_AT:-$(date +%s)}"
            # echo -n "\"docker-args\":\"${DOCKER_ARGS[*]}\""
            echo -n "}"
        } | jq -c .
    }
    __scanner:api() {
        local SCANNER_API=(activate metadata version)
        {
            local SCANNER_API_IMPLEMENTED=true
            echo -n "{"
            for SCANNER_API in "${SCANNER_API[@]}"; do
                if ! __is function "${SCANNER_NAME}:${SCANNER_API}"; then
                    echo -n "\"${SCANNER_API}\":false,"
                    SCANNER_API_IMPLEMENTED=false
                else
                    echo -n "\"${SCANNER_API}\":true,"
                fi
            done #| sed 's/,$//'
            echo -n "\"implemented\":$SCANNER_API_IMPLEMENTED"
            echo -n "}"
        }

    }
    __scanner:state() {
        {
            if ! __is function "__scanner:${SCANNER_NAME}"; then
                echo -n "{"
                echo -n "\"error\":\"${SCANNER_NAME} not implemented\","
                echo -n "\"code\":100"
                echo -n "}"
                return 1
            elif ! __scanner:"${SCANNER_NAME}" activate >"$SCANNER_OUTPUT"; then
                echo -n "{"
                echo -n "\"error\":\"${SCANNER_NAME} can't be activated\","
                echo -n "\"code\":101"
                echo -n "}"
                return 1
            else
                {
                    echo -n "{"
                    echo -n "\"activated\":true"
                    echo -n "}"
                    __scanner:api "$@"
                } | jq -sc '
                    .[0] as $state |
                    .[1] as $api |
                    {
                        activated: $state.activated,
                        api: $api
                    }
                '
                return 0
            fi
        } | jq -c .
    }
    __scanner:metadata() {
        local SCANNER_METADATA=$({
            __scanner:info "$@"
            __scanner:state "$@"
        } | jq -sc '
            .[0] as $info |
            .[1] as $state |
            {
                info: $info,
                state: $state
            }
        ')
        jq -r .state.api.implemented <<<"$SCANNER_METADATA" | grep -q false && {
            echo "$SCANNER_METADATA" | jq -c '.state.error="API not implemented"'
            return 1
        }
        ! jq -r .state.error <<<"$SCANNER_METADATA" | grep -q "null" && {
            echo "$SCANNER_METADATA" | jq -c #'.state.error="Scanner not activated"'
            return 1
        }
        {
            jq -cr .info <<<"$SCANNER_METADATA"
            jq -cr .state <<<"$SCANNER_METADATA"
            __scanner:"${SCANNER_NAME}" metadata "$@"
            __scanner:"${SCANNER_NAME}" version "$@"
        } | jq -s '
            .[0] as $info |
            .[1] as $state |
            .[2] as $metadata |
            .[3] as $version |
            {
                info: $info,
                validation: {
                    available: $version.success,
                    engine: $version.engine,
                    $state
                },
                metadata: $metadata,
                version: $version
            }
        '
        return 0
        # if __is function "__scanner:${SCANNER_NAME}"; then
        #     if __scanner:"${SCANNER_NAME}" activate >"$SCANNER_OUTPUT"; then
        #         {
        #             __scanner:info "$@"
        #             __scanner:api "$@"
        #             __scanner:"${SCANNER_NAME}" metadata "$@"
        #             __scanner:"${SCANNER_NAME}" version "$@"
        #         } | jq -s '
        #             .[0] as $info |
        #             .[1] as $api |
        #             .[2] as $metadata |
        #             .[3] as $version |
        #             {
        #                 info: $info,
        #                 api: $api,
        #                 metadata: $metadata,
        #                 version: $version,
        #                 state: {
        #                     available: $version.success,
        #                     engine: $version.engine,
        #                 }
        #             }
        #         '
        #         return 0
        #     else
        #         __scanner:info "$@"
        #         __scanner:api "$@"
        #         {
        #             echo -n "{"
        #             echo -n "\"error\":\"${SCANNER_NAME} not implemented\""
        #             echo -n "}"
        #         } | jq -c '
        #             .[0] as $info |
        #             .[1] as $api |
        #             .[2] as $error |
        #             {
        #                 info: $info,
        #                 api: $api,
        #                 error: $error
        #             }
        #         '
        #         return 1
        #     fi
        # else
        #     {
        #         echo -n "{"
        #         echo -n "\"error\":\"${SCANNER_NAME} not found\""
        #         echo -n "}"
        #     } | jq -c .
        #     return 1
        # fi
    }
    run() {
        local SCANNER_START_AT="$(date +%s)"
        local DOCKER_ARGS=(
            "--rm"
            "--name" "ywt-scanners-${SCANNER_UID}"
            "-v" "$(pwd):/ywt-workdir"
            "-v" "/var/run/docker.sock:/var/run/docker.sock"
            "-v" "/tmp:/tmp"
            "ywt-sca:latest"
        )
        local SCANNER="$(__scanner:info)"
        case "$SCANNER_NAME" in
        cloc)
            local SCANNER_METADATA=$(__scanner:cloc metadata)
            local SCANNER_RESULT=$(__scanner:cloc scan "$@")
            ;;
        esac
        jq -n \
            --argjson scanner "$SCANNER" \
            --argjson metadata "$SCANNER_METADATA" \
            --argjson result "$SCANNER_RESULT" '
            {
                scanner: {
                    id: $scanner.scanner,
                    metadata: $metadata,
                },
                report: {
                    output: $scanner.output,
                    start: $scanner.start,
                    end: $result.data.end,
                    elapsed: ($result.data.end - $scanner.start),
                    error: $result.error,
                    $result
                }
            }
        '
    }
    __scanner:metadata "$@"

}
scanner:v1() {
    local SCANNER_NAME="$1" && shift && SCANNER_NAME="${SCANNER_NAME,,}" && SCANNER_NAME="${SCANNER_NAME// /-}" && SCANNER_NAME="${SCANNER_NAME//./-}" && SCANNER_NAME="${SCANNER_NAME//:/-}" && SCANNER_NAME="${SCANNER_NAME//\//-}"
    local RESULT_FILE="$(mktemp -u -t ywt-XXXXXX --suffix=".$SCANNER_NAME" -p /tmp)"
    local SCANNER_UID="$(basename "$RESULT_FILE")" && SCANNER_UID="${SCANNER_UID//./-}"
    local DOCKER_ARGS=(
        "--rm"
        "--name" "${SCANNER_UID}"
        "-v" "$(pwd):/ywt-workdir"
        "-v" "/var/run/docker.sock:/var/run/docker.sock"
        "ywt-sca:latest"
    )
    case "$SCANNER_NAME" in
    network-hsts)
        __scanner:network:hsts "$@"
        ;;
    cloc)
        __scanner:cloc "$@"
        ;;
    trivy)
        __scanner:trivy "$@"
        ;;
    trufflehog)
        __scanner:trufflehog "$@"
        ;;
    *)
        __nnf "$@" || usage "tests" "$?" "$@" && return 1
        ;;
    esac
}
(
    export -f scanner
)
