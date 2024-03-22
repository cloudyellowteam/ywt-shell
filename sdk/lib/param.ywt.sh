#!/usr/bin/env bash
# shellcheck disable=SC2317,SC2120,SC2155,SC2044
param() {
    YWT_LOG_CONTEXT="PARAM"
    get() {
        # [-n|--name] PARAM_NAME
        # [-d|--default] DEFAULT_VALUE
        # [-r|required]
        # [-t|--type] TYPE
        # [-s|--store] STORE_FILE
        # [-c|--config] CONFIG_FILE
        # [-f|--from] ENV, FLAGS, CONFIG, PARAMS
        # [-m|--message] MESSAGE
        local PARAM_NAME DEFAULT_VALUE REQUIRED TYPE STORE_FILE CONFIG_FILE
        local CONFIG_PREFIX="YWT_CONFIG_"
        local ARGS=()
        while [ "$#" -gt 0 ]; do
            case "$1" in
            -n | --name)
                PARAM_NAME="$2"
                shift 2
                ;;
            -d | --default)
                DEFAULT_VALUE="$2"
                shift 2
                ;;
            -r | --required)
                REQUIRED=true
                shift
                ;;
            -t | --type)
                TYPE="$2"
                shift 2
                ;;
            -s | --store)
                STORE_FILE="$2"
                [ ! -f "$STORE_FILE" ] && echo "Store file not found: $STORE_FILE" | Logger error && return 1
                ! __is rw "$STORE_FILE" && echo "Store file is not writable: $STORE_FILE" | Logger error && return 1
                shift 2
                ;;
            -c | --config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -f | --from)
                CONFIG_PREFIX="$2"
                shift 2
                ;;
            -m | --message)
                MESSAGE="$2"
                shift 2
                ;;
            *)
                ARGS+=("$1")
                shift
                ;;
            esac
        done
        # set -- "${ARGS[@]}"
        local CONFIG_VALUE="$(eval echo "\$${CONFIG_PREFIX}${PARAM_NAME^^}")"
        local PARAM_VALUE="$(jq -r '.params["'"${PARAM_NAME}"'"] // empty' <<<"$YWT_CONFIG")"
        local FLAG_VALUE="$(jq -r '.flags["'"${PARAM_NAME}"'"] // empty' <<<"$YWT_CONFIG" 2>/dev/null)"
        local ENV_VALUE="$(jq -r '.env["'"${PARAM_NAME}"'"] // empty' <<<"$YWT_CONFIG" 2>/dev/null)"
        local PROCESS_ENV_VALUE="$(eval echo "\$${PARAM_NAME^^}")"
        local STORE_VALUE="" #$(store get "$PARAM_NAME")
        local VALUE="${!PARAM_NAME}"
        local VALUE_KEY="raw"
        if [ -z "$VALUE" ]; then
            if [ -n "$CONFIG_VALUE" ]; then
                VALUE="$CONFIG_VALUE"
                VALUE_KEY="config"
            elif [ -n "$FLAG_VALUE" ]; then
                VALUE="$FLAG_VALUE"
                VALUE_KEY="flag"
            elif [ -n "$STORE_VALUE" ]; then
                VALUE="$STORE_VALUE"
                VALUE_KEY="store"
            elif [ -n "$PARAM_VALUE" ]; then
                VALUE="$PARAM_VALUE"
                VALUE_KEY="param"
            elif [ -n "$DEFAULT_VALUE" ]; then
                VALUE="$DEFAULT_VALUE"
                VALUE_KEY="default"
            elif [ -n "$ENV_VALUE" ]; then
                VALUE="$ENV_VALUE"
                VALUE_KEY="env"
            elif [ -n "$PROCESS_ENV_VALUE" ]; then
                VALUE="$PROCESS_ENV_VALUE"
                VALUE_KEY="process"
            fi
        fi
        local ERROR=
        [ -z "$VALUE" ] && [ "$REQUIRED" == true ] && ERROR="Parameter $PARAM_NAME is required to ${FUNCNAME[2]:-"unknow"}"
        if [ -n "$TYPE" ]; then
            case "$TYPE" in
            date)
                if ! date -d "$VALUE" >/dev/null 2>&1; then
                    ERROR="Parameter $PARAM_NAME must be a valid date"
                fi
                ;;
            url)
                if ! [[ "$VALUE" =~ ^https?:// ]]; then
                    ERROR="Parameter $PARAM_NAME must be a valid URL"
                fi
                ;;
            json)
                if ! jq -e . >/dev/null 2>&1 <<<"$VALUE"; then
                    ERROR="Parameter $PARAM_NAME must be a valid JSON"
                fi
                ;;
            int)
                if ! [[ "$VALUE" =~ ^[0-9]+$ ]]; then
                    ERROR="Parameter $PARAM_NAME must be an integer"
                fi
                ;;
            float)
                if ! [[ "$VALUE" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
                    ERROR="Parameter $PARAM_NAME must be a float"
                fi
                ;;
            bool)
                if ! [[ "$VALUE" =~ ^(true|false)$ ]]; then
                    ERROR="Parameter $PARAM_NAME must be a boolean"
                fi
                ;;
            *) ;;
            esac
        fi
        local VALID=$(if [ -z "$ERROR" ]; then echo "true"; else echo "false"; fi)
        # [ -n "$ERROR" ] && echo "$ERROR" | logger error
        local METADATA="$({
            echo -n "{"
            echo -n "\"error\":\"$ERROR\","
            echo -n "\"message\":\"${MESSAGE:-""}\","
            echo -n "\"valid\":$VALID,"
            echo -n "\"name\":\"$PARAM_NAME\","
            echo -n "\"default\":\"$DEFAULT_VALUE\","
            echo -n "\"required\":${REQUIRED:-false},"
            echo -n "\"type\":\"$TYPE\","
            echo -n "\"store\":\"$STORE_FILE\","
            echo -n "\"config\":\"$CONFIG_FILE\"",
            echo -n "\"from\":\"${VALUE_KEY}\","
            echo -n "\"value\":\"$VALUE\","
            echo -n "\"values\":{"
            echo -n "\"config\":\"$CONFIG_VALUE\","
            echo -n "\"param\":\"$PARAM_VALUE\","
            echo -n "\"flag\":\"$FLAG_VALUE\","
            echo -n "\"env\":\"$ENV_VALUE\","
            echo -n "\"process\":\"$PROCESS_ENV_VALUE\","
            echo -n "\"store\":\"$STORE_VALUE\","
            echo -n "\"raw\":\"$VALUE\""
            echo -n "}"
            echo -n "}"
        } | jq -cr '.')"
        echo -n "${METADATA}" | jq -cr '.'
        # echo "$VALUE"
        [ -z "$ERROR" ] && return 0
        return 1
    }
    validate(){
        if ! jq -e . >/dev/null 2>&1 <<<"$1"; then
            echo "Invalid JSON ${1}" | logger error
            return 1
        fi
        local ERRORS=$(jq -r '. | to_entries[] | select(.value.valid == false) | .value.error | select(. != null)' <<<"$1")
        if ! __is nil "$ERRORS"; then
            local LEN=0
            echo "Invalid parameters" | logger error
            while IFS= read -r line; do
                echo "$line" | logger error
                LEN=$((LEN + 1))
            done <<<"$ERRORS"
            echo "(${LEN}) Invalid parameters" | logger error
            return 1
        fi
        return 0
    }
    case "$1" in
    get)
        shift
        get "$@"

        ;;
    validate)
        shift
        validate "$@"
        ;;
    *) __nnf "$@" || usage "param" "$?" "$@" && return 1 ;;
    esac
    return $?

}
(
    export -f param
)
