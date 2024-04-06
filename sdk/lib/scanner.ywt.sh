#!/usr/bin/env bash
# shellcheck disable=SC2317,SC2120,SC2155,SC2044
scanner() {
    __scanner:info() {
        if [ -n "$SCANNER_INFO" ]; then
            echo -n "$SCANNER_INFO" | jq -c .
            return 0
        fi
        local SCANNER_NAME="$1" && shift && SCANNER_NAME="${SCANNER_NAME,,}" && SCANNER_NAME="${SCANNER_NAME// /-}" && SCANNER_NAME="${SCANNER_NAME//./-}" && SCANNER_NAME="${SCANNER_NAME//:/-}" && SCANNER_NAME="${SCANNER_NAME//\//-}"
        local SCANNER_UID="$(mktemp -u -t XXXXXXXXXXXXXX -p /tmp)" && SCANNER_UID="$(basename "$SCANNER_UID")" && SCANNER_UID="${SCANNER_UID//./-}"
        local SCANNER_ID="$(echo -n "$SCANNER_NAME.$SCANNER_UID" | base64)"        
        local SCANNER_OUTPUT="/tmp/scanner-$SCANNER_UID.ywt"
        local SCANNER_INFO=$(jq -n \
            --arg name "$SCANNER_NAME" \
            --arg uid "$SCANNER_UID" \
            --arg id "$SCANNER_ID" \
            --arg output "$SCANNER_OUTPUT" \
            '{
                name: $name,
                uid: $uid,
                id: $id,
                output: $output
            }'
        )
        echo -n "$SCANNER_INFO" | jq -c .
        # echo -n "{"
        # echo -n "\"name\":\"$SCANNER_NAME\","
        # echo -n "\"uid\":\"$SCANNER_UID\","
        # echo -n "\"id\":\"$SCANNER_ID\","
        # echo -n "\"output\":\"$SCANNER_OUTPUT\""
        # echo -n "}"
        return 0
    }
    __scanner:list() {
        declare -F |
            grep -oP "__scanner:\K\w+" |
            jq -R . |
            jq -s . |
            jq -rc '
                map(
                    select(
                        . as $name |
                        "info list exists validate api activate validate registry inspect result  cli run definition network" |
                        split(" ") | 
                        map(select(. == $name)) | length == 0
                    )
                ) |
                sort |
                .[]                
            '
        return 0
    }
    __scanner:exists() {
        local SCANNER_NAME="$1" && shift
        __scanner:list | grep -q "$SCANNER_NAME" && return 0
        return 1
    }
    __scanner:validate:api() {
        local SCANNER_API=(cli version activate metadata result summary)
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
            done
            echo -n "\"implemented\":$SCANNER_API_IMPLEMENTED"
            echo -n "}"
        }
    }
    __scanner:activate() {
        local SCANNER_NAME="$1" && shift
        if ! __scanner:exists "$SCANNER_NAME"; then
            echo -n "{"
            echo -n "\"error\":\"${SCANNER_NAME} not implemented\","
            echo -n "\"code\":100"
            echo -n "}"
            return 1
        elif ! __scanner:"${SCANNER_NAME}" activate >/dev/null 2>&1; then
            echo -n "{"
            echo -n "\"error\":\"${SCANNER_NAME} can't be activated\","
            echo -n "\"code\":101"
            echo -n "}"
            return 1
        else
            echo -n "{"
            echo -n "\"active\":true,"
            echo -n "\"enabled\":true,"
            echo -n "\"api\":" && __scanner:validate:api "$SCANNER_NAME" | jq -c .
            echo -n "}"
            return 0
        fi
    }
    __scanner:validate() {
        local SCANNER_NAME="$1" && shift
        local SCANNER_ACTIVATION=$(__scanner:activate "$SCANNER_NAME")
        jq -r .api.implemented <<<"$SCANNER_ACTIVATION" | grep -q false && {
            echo "$SCANNER_ACTIVATION" | jq -c '.error="API fully not implemented"'
            return 1
        }
        ! jq -r .error <<<"$SCANNER_ACTIVATION" | grep -q "null" && {
            echo "$SCANNER_ACTIVATION" | jq -c #'.state.error="Scanner not activated"'
            return 1
        }
        echo -n "$SCANNER_ACTIVATION" | jq -c ".valid=true"
        return 0
    }
    __scanner:registry() {
        {
            while read -r SCANNER_NAME; do
                echo -n "{"
                echo -n "\"header\":" && __scanner:info "$SCANNER_NAME" | jq -c .
                echo -n ","
                local SCANNER_VALIDATION=$(__scanner:validate "$SCANNER_NAME")
                echo -n "\"state\":" && echo -n "$SCANNER_VALIDATION" | jq -c .
                echo -n ","
                if jq -r .valid <<<"$SCANNER_VALIDATION" | grep -q true; then
                    echo -n "\"metadata\":" && __scanner:"${SCANNER_NAME}" metadata | jq -c .
                else
                    echo -n "\"metadata\":{}"
                fi
                echo -n "}"
            done < <(__scanner:list)
        } | jq -cs .
        return 0
    }
    __scanner:inspect() {
        local SCANNER_NAME="$1" && shift
        local SCANNER_DEFINITION=$({
            __scanner:registry | jq -c '
                map(
                    select(.state.valid == true) |
                    select(.header.name == "'"$SCANNER_NAME"'")
                )
                | .[0]
            '
        })
        if [ -z "$SCANNER_DEFINITION" ] || [ "$SCANNER_DEFINITION" == "null" ]; then
            {
                echo -n "{"
                echo -n "\"error\":\"${SCANNER_NAME} not found\","
                echo -n "\"code\":404"
                echo -n "}"
            } | jq -c .
            return 1
        fi
        echo -n "$SCANNER_DEFINITION" | jq -c .
        return 0
    }
    __scanner:result() {
        local SCANNER_NAME="$1" && shift
        local SCANNER_OUTPUT="$1" && shift
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
        local SCANNER_ARGS=()
        while [ $# -gt 0 ]; do
            case "$1" in
            -o | --output)
                local SCANNER_OUTPUT="$2"
                shift 2
                ;;
            *)
                SCANNER_ARGS+=("$1")
                shift
                ;;
            esac
        done
        set -- "${SCANNER_ARGS[@]}" && unset SCANNER_ARGS
        local SCANNER_METADATA="$1" && shift
        ! __is json "$SCANNER_METADATA" && SCANNER_METADATA="$(__scanner:inspect "$SCANNER_METADATA")"
        if [ -z "$SCANNER_METADATA" ] || [ "$SCANNER_METADATA" == "null" ] || [ "$(jq -r .error <<<"$SCANNER_METADATA")" != "null" ]; then
            echo "$SCANNER_METADATA" | jq -c . | logger error
            return 1
        fi

        local SCANNER_NAME="$(jq -r .header.name <<<"$SCANNER_METADATA")"
        local SCANNER_UID="$(jq -r .header.uid <<<"$SCANNER_METADATA")"
        [ -z "$SCANNER_OUTPUT" ] &&  local SCANNER_OUTPUT="$(jq -r .header.output <<<"$SCANNER_METADATA")"
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
            ! jq -r '.metadata.engines[]' <<<"$SCANNER_METADATA" | grep -c "$SCANNER_ENGINE" >/dev/null 2>&1 && continue
            if [ "$SCANNER_ENGINE" == "host" ] && __is command "$SCANNER_NAME"; then
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
            echo -n "\"data\":$(__scanner:result "$SCANNER_NAME" "$SCANNER_OUTPUT"),"
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
    __scanner:run() {
        local SCANNER_START_AT="$(date +%s)"
        local SCANNER_NAME="$1" && shift
        local SCANNER_METADATA=$(__scanner:inspect "$SCANNER_NAME")
        if [ -z "$SCANNER_METADATA" ] || [ "$SCANNER_METADATA" == "null" ] || [ "$(jq -r .error <<<"$SCANNER_METADATA")" != "null" ]; then
            echo "$SCANNER_METADATA" | jq -c . | logger error
            return 1
        fi
        local SCANNER_NAME="$(jq -r .header.name <<<"$SCANNER_METADATA")"
        local SCANNER_OUTPUT="$(jq -r .header.output <<<"$SCANNER_METADATA")"
        local SCANNER_RUN_OUTPUT="${SCANNER_OUTPUT//.ywt/.result}.ywt"
        {
            echo "$SCANNER_METADATA" #| jq -c .
            __scanner:"${SCANNER_NAME}" cli --output "$SCANNER_OUTPUT" "$@" #&>"$SCANNER_OUTPUT"
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
                    output: $metadata.header.output,
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
    __scanner:definition() {
        local SCANNER_NAME="$1" && shift
        local SCANNER_DEFINITION=$(__scanner:inspect "$SCANNER_NAME")
        if [ -z "$SCANNER_DEFINITION" ] || [ "$SCANNER_DEFINITION" == "null" ] || [ "$(jq -r .error <<<"$SCANNER_DEFINITION")" != "null" ]; then
            echo "$SCANNER_DEFINITION" | jq -c . | logger error
            return 1
        fi
        {
            echo -n "$SCANNER_DEFINITION"
            __scanner:"${SCANNER_NAME}" version "$@"
        } | jq -sc '
            {
                definition: .[0],
                version: .[1]
            }
        '
        return 0
    }
    inspect() {
        # local SCANNER_NAME="$1" && shift
        # __scanner:cli cloc --version
        # __scanner:"${SCANNER_NAME}" version "$@"
        __scanner:definition "$@" | jq '.'
        return 0
    }
    list() {
        __scanner:registry | jq -c '
            del(.[].header.output)  |
            map(select(.state.valid == true))          
        '
        return 0
    }
    if ! __scanner:exists "$1"; then
        __nnf "$@" && return "$?"
    else 
        if [ "$2" == "asset" ]; then
            local SCANNER_NAME="$1" && shift
            __scanner:"${SCANNER_NAME}" "$@"
            return $?
        else 
            __scanner:run "$@" | jq .
            return 0
        fi
    fi
}