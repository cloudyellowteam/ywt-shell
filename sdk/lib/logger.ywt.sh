#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
logger() {
    error() {
        log "error" "$*"
    }
    warn() {
        log "warn" "$*"
    }
    info() {
        log "info" "$*"
    }
    debug() {
        log "debug" "$*"
    }
    _log_level() {
        local LEVEL=${1:-info} && [[ ! $LEVEL =~ ^(debug|info|warn|error)$ ]] && LEVEL=info
        local COLOR=white
        case $LEVEL in
        debug) COLOR=cyan ;;
        info) COLOR=green ;;
        warn) COLOR=yellow ;;
        error) COLOR=red ;;
        esac
        LEVEL=$(printf "%-5s" "$LEVEL")
        echo -n "$(colors colorize "yellow" "[$RAPD_CMD_NAME]") "
        echo -n "$(colors colorize "bright-black" "[$$]" "fg") "
        # echo -n "$(style "underline" "[$(etime)]" "fg") "
        echo -n "$(colors colorize "blue" "[$(date +"%Y-%m-%d %H:%M:%S")]" "fg") "
        echo -n "$(colors colorize "$COLOR" "$(colors style bold "[${LEVEL^^}]")" "fg") "
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
        local IS_JSON=${3:-false}
        _log_level "$1"
        [[ $IS_JSON == false ]] && _log_message "$2"
        [[ $IS_JSON == true ]] && jq -cC . <<<"$(_log_message "$2")"
        # elapsed time
        echo -n " $(colors colorize "bright-black" "[$(colors style "underline" "$(etime)")]" "fg")"
    }

    usage() {
        echo "usage from logger $*"
    }
    if nnf "$@"; then return 0; fi
    usage "$?" "$@" && return 1
}
(
    export -f logger
)
