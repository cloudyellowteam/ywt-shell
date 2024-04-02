#!/usr/bin/env bash
# shellcheck disable=SC2317,SC2120,SC2155,SC2044
scanner() {
    local SCANNER_ACTION="$1" && shift
    local SCANNER_NAME="$SCANNER_ACTION" && SCANNER_NAME="${SCANNER_NAME,,}" && SCANNER_NAME="${SCANNER_NAME// /-}" && SCANNER_NAME="${SCANNER_NAME//./-}" && SCANNER_NAME="${SCANNER_NAME//:/-}" && SCANNER_NAME="${SCANNER_NAME//\//-}"
    local SCANNER_UID="$(mktemp -u -t XXXXXXXXXXXXXX -p /tmp)" && SCANNER_UID="$(basename "$SCANNER_UID")" && SCANNER_UID="${SCANNER_UID//./-}"
    local SCANNER_ID="$(echo -n "$SCANNER_NAME" | base64)${SCANNER_UID}"
    local SCANNER_OUTPUT="/tmp/scanner-${SCANNER_UID}.ywt"
    __scanner:result() {
        {
            echo -n "{"
            if [ ! -f "$SCANNER_OUTPUT" ]; then
                echo -n "\"format\":\"text\","
                echo -n "\"content\":\"No output\","
            elif jq -e . "$SCANNER_OUTPUT" >/dev/null 2>&1; then
                echo -n "\"format\":\"json\","
                echo -n "\"content\":"
                __scanner:"${SCANNER_NAME}" result "$SCANNER_OUTPUT"
                # jq -c . "$SCANNER_OUTPUT"
                echo -n ","
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
        local SCANNER_NAME="$1" && shift
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
    __scanner:validate() {
        jq -r .state.api.implemented <<<"$1" | grep -q false && {
            echo "$1" | jq -c '.state.error="API not implemented"'
            return 1
        }
        ! jq -r .state.error <<<"$1" | grep -q "null" && {
            echo "$1" | jq -c #'.state.error="Scanner not activated"'
            return 1
        }
        return 0
    }
    __scanner:metadata() {
        local SCANNER_METADATA=$({
            __scanner:info "$SCANNER_NAME"
            __scanner:state "$SCANNER_NAME"
        } | jq -sc '
            .[0] as $info |
            .[1] as $state |
            {
                info: $info,
                state: $state
            }
        ')
        if ! __scanner:validate "$SCANNER_METADATA"; then
            return 1
        fi
        {
            jq -cr .info <<<"$SCANNER_METADATA"
            jq -cr .state <<<"$SCANNER_METADATA"
            __scanner:"${SCANNER_NAME}" metadata "$@"
            __scanner:"${SCANNER_NAME}" version "$@"
        } | jq -sc '
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
    }
    __scanner:run() {
        local SCANNER_START_AT="$(date +%s)"
        # local SCANNER_METADATA=$(__scanner:metadata "$@")
        # local SCANNER_RESULT=$(__scanner:"${SCANNER_NAME}" cli "$@")
        local SCANNER_RUN_OUTPUT="${SCANNER_OUTPUT//.ywt/.result}.ywt"
        {
            __scanner:metadata "$@"
            __scanner:"${SCANNER_NAME}" cli "$@"
            __scanner:"${SCANNER_NAME}" summary "$SCANNER_OUTPUT"
        } >"$SCANNER_RUN_OUTPUT"
        # cat "$SCANNER_RUN_OUTPUT" && return 0
        jq -cs \ '
            .[0] as $metadata |
            .[1] as $result |
            .[2] as $summary |
            {
                scanner: $metadata,
                report: {
                    output: $metadata.info.output,
                    start: '"$SCANNER_START_AT"',
                    end: $result.data.end,
                    elapsed: ($result.data.end - '"$SCANNER_START_AT"'),
                    error: $result.error,
                    $result
                },
                summary: $summary
            }
        ' "$SCANNER_RUN_OUTPUT"
        return 0
    }
    __scanner:list:functions() {
        declare -F |
            grep -oP "__scanner:\K\w+" |
            jq -R . |
            jq -s . |
            jq -rc '
                map(
                    select(
                        . as $name |
                        "result cli info api state metadata run network list validate" |
                        split(" ") | 
                        map(select(. == $name)) | length == 0
                    )
                ) |
                sort |
                .[]                
            '
        return 0
    }
    list() {
        {
            while read -r S_NAME; do
                echo -n "{"
                echo -n "\"name\":\"$S_NAME\","
                echo -n "\"info\":"
                __scanner:info "$S_NAME"
                echo -n ","
                echo -n "\"state\":"
                __scanner:state "$S_NAME"
                echo -n "}"
            done < <(__scanner:list:functions)
        } | jq -s .
        return 0
    }
    inspect(){
        local SCANNER_NAME="$1" && shift
        __scanner:metadata "$SCANNER_NAME" "$@"
        return 0
    }
    case "$SCANNER_NAME" in
    inspect)
        inspect "$@"
        ;;
    list)
        list | jq -c .
        return 0
        ;;
    *)
        __scanner:run "$@"
        return "$?"
        ;;
    esac
    return 0
}
# scanner:v1() {
#     local SCANNER_NAME="$1" && shift && SCANNER_NAME="${SCANNER_NAME,,}" && SCANNER_NAME="${SCANNER_NAME// /-}" && SCANNER_NAME="${SCANNER_NAME//./-}" && SCANNER_NAME="${SCANNER_NAME//:/-}" && SCANNER_NAME="${SCANNER_NAME//\//-}"
#     local RESULT_FILE="$(mktemp -u -t ywt-XXXXXX --suffix=".$SCANNER_NAME" -p /tmp)"
#     local SCANNER_UID="$(basename "$RESULT_FILE")" && SCANNER_UID="${SCANNER_UID//./-}"
#     local DOCKER_ARGS=(
#         "--rm"
#         "--name" "${SCANNER_UID}"
#         "-v" "$(pwd):/ywt-workdir"
#         "-v" "/var/run/docker.sock:/var/run/docker.sock"
#         "ywt-sca:latest"
#     )
#     case "$SCANNER_NAME" in
#     network-hsts)
#         __scanner:network:hsts "$@"
#         ;;
#     cloc)
#         __scanner:cloc "$@"
#         ;;
#     trivy)
#         __scanner:trivy "$@"
#         ;;
#     trufflehog)
#         __scanner:trufflehog "$@"
#         ;;
#     *)
#         __nnf "$@" || usage "tests" "$?" "$@" && return 1
#         ;;
#     esac
# }
# (
#     export -f scanner
# )
