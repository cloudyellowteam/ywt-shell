#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
logger() {
    # __debug "logger" "$@"
    # YWT_LOG_CONTEXT=${YWT_LOG_CONTEXT:-logger}
    _is_log_level() {
        local LEVEL=${1:-info} && [[ ! $LEVEL =~ ^(debug|info|warn|error|success)$ ]] && LEVEL=info
        local LOG_LEVEL=${YWT_LOG_LEVEL:-info}
        [[ $LOG_LEVEL == "debug" ]] && [[ $LEVEL == "debug" ]] && return 0
        [[ $LOG_LEVEL == "info" ]] && [[ $LEVEL == "info" ]] && return 0
        [[ $LOG_LEVEL == "warn" ]] && [[ $LEVEL == "warn" ]] && return 0
        [[ $LOG_LEVEL == "error" ]] && [[ $LEVEL == "error" ]] && return 0
        [[ $LOG_LEVEL == "success" ]] && [[ $LEVEL == "success" ]] && return 0
        return 1
    }
    _log_level() {
        local LEVEL=${1:-info} && [[ ! $LEVEL =~ ^(debug|info|warn|error|success)$ ]] && LEVEL=info
        local COLOR=white
        local ICON=""
        case $LEVEL in
        debug)
            COLOR=cyan
            ICON="🐞"
            ;;
        info)
            COLOR=green
            ICON="📗"
            ;;
        warn)
            COLOR=yellow
            ICON="🔔"
            ;;
        error)
            COLOR=red
            ICON="🚨"
            ;;
        success)
            COLOR=green
            ICON="✅"
            ;;
        esac
        LEVEL=$(printf "%-5s" "$LEVEL") #YWT_LOG_CONTEXT
        echo -n "$(colors apply "yellow" "[${YWT_CMD_NAME^^}]") "
        echo -n "$(colors apply "bright-black" "[$$]" "fg") "
        # echo -n "$(style "underline" "[$(__etime)]" "fg") "
        echo -n "$(colors apply "blue" "[$(date +"%Y-%m-%d %H:%M:%S")]" "fg") "
        echo -n "$(colors apply "$COLOR" "$(styles bold "[${LEVEL^^}]")" "fg") "
        [[ "${YWT_LOG_CONTEXT^^}" != "${YWT_CMD_NAME^^}" ]] && echo -n "$(colors apply "blue" "[${YWT_LOG_CONTEXT^^}]") "
        [ -n "$ICON" ] && echo -n "$(colors apply "$COLOR" "$ICON" "fg")"
        echo -n " "
    }
    _log_message() {
        local MESSAGE=${1:-}
        local LINES=()
        [[ -n "$MESSAGE" ]] && LINES+=("$MESSAGE")
        [[ -p /dev/stdin ]] && while read -r LINE; do LINES+=("$LINE"); done <&0
        MESSAGE="${LINES[*]//$'\n'/$'\n' }"
        echo -n "$MESSAGE"
    }
    _log:level(){
        local LEVEL=${1:-info} && [[ ! $LEVEL =~ ^(debug|info|warn|error|success)$ ]] && LEVEL=info
        local COLOR=white
        local ICON=""
        case $LEVEL in
        debug)
            COLOR=cyan
            ICON="🐞"
            ;;
        info)
            COLOR=green
            ICON="📗"
            ;;
        warn)
            COLOR=yellow
            ICON="🔔"
            ;;
        error)
            COLOR=red
            ICON="🚨"
            ;;
        success)
            COLOR=green
            ICON="✅"
            ;;
        esac
        {
            echo -n "{"
            echo -n "\"level\": \"${LEVEL}\","
            echo -n "\"icon\": \"${ICON}\","
            echo -n "\"color\": \"${COLOR}\""
            echo -n "}"
        } | jq -c .
    }
    _log:message(){
        local MESSAGE=${1:-}
        local LINES=()
        [[ -n "$MESSAGE" ]] && LINES+=("$MESSAGE")
        [[ -p /dev/stdin ]] && while read -r LINE; do LINES+=("$LINE"); done <&0
        MESSAGE="${LINES[*]//$'\n'/$'\n' }"
        
        MESSAGE=$(echo "$MESSAGE" | sed -r "s/\x1B\[[0-9;]*[mK]//g")
        echo -n "$MESSAGE"
    }
    log() {
        local LOG_LEVEL="$(_log:level "$1")"
        local LOG_MESSAGE="$(_log:message "$2")"
        jq -cn \
            --argjson level "$LOG_LEVEL" \
            --argjson config "$YWT_CONFIG" \
            --arg message "${LOG_MESSAGE:-}" \
            '{
                "@timestamp": (now | todate),
                "@version": $config.yellowteam.version,                
                "tags": ["'"ywt:${YWT_LOG_CONTEXT,,}:context"'"],
                "path": "",
                "host": "'"$(hostname)"'",
                "type": "'"${YWT_LOG_CONTEXT,,}-log"'",
                "package": "\($config.yellowteam.name):\($config.yellowteam.version):\($config.yellowteam.license)",
                "color": $level.color,
                "icon": $level.icon,
                "pid": "'$$'",
                "ppid": "'$PPID'",
                "cmd": "'"$YWT_CMD_NAME"'",
                "name": "'"$YWT_CMD_NAME"'",
                "context": "'"${YWT_LOG_CONTEXT,,}"'",
                "signal": $level.icon,
                "level": $level.level,
                "message": $message,
                "etime": "'"$(__etime)"'"
            }'
        return 0

        # [ "$1" == "debug" ] && __debug "logger:" "$@" && return 0
        # _log_level "$1"
        # _log_message "$2"
        # # elapsed time
        # echo " $(colors apply "bright-black" "[$(styles "underline" "$(__etime)")]" "fg")"
    }
    json() {
        _log_level "$1"
        jq -cC . <<<"$(_log_message "$2")"
    }
    local LEVEL=${1}
    if [[ $LEVEL =~ ^(debug|info|warn|error|success)$ ]]; then
        # ARGS=("${@:2}")
        # shift # && LEVEL="log ${LEVEL}"
        log "${1}" "${@:2}" && return 0
    elif [[ $LEVEL == "json" ]]; then
        shift # && LEVEL="json ${LEVEL}"
        json "${LEVEL}" "$@" && return 0
    elif __nnf "$@"; then
        return 0
        usage "$?" "logger" "$@" && return 1
    else
        usage 1 "logger" "$@" && return 1
    fi
}
(
    export -f logger
)
