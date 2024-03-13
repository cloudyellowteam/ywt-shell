#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
logger() {
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
        # echo -n "$(style "underline" "[$(etime)]" "fg") "
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
    log() {
        _log_level "$1"
        _log_message "$2"
        # elapsed time
        echo " $(colors apply "bright-black" "[$(styles "underline" "$(etime)")]" "fg")"
    }
    json() {
        _log_level "$1"
        jq -cC . <<<"$(_log_message "$2")"
    }
    local LEVEL=${1}
    if [[ $LEVEL =~ ^(debug|info|warn|error|success)$ ]]; then
        # ARGS=("${@:2}")
        shift && LEVEL="log ${LEVEL}"
        log "${LEVEL}" "$@" && return 0
    elif [[ $LEVEL == "json" ]]; then
        shift && LEVEL="json ${LEVEL}"
        json "${LEVEL}" "$@" && return 0
    elif _nnf "$@"; then
        return 0
        usage "$?" "logger" "$@" && return 1
    else
        usage 1 "logger" "$@" && return 1
    fi
}
(
    export -f logger
)
