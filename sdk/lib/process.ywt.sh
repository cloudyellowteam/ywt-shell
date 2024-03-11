#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
process() {
    local RAPD_IS_BINARY=false
    LC_ALL=C grep -a '[^[:print:][:space:]]' "$RAPD_CMD_FILE" >/dev/null && RAPD_IS_BINARY=true
    local RAPD_CMD_PROCESS=$$ && readonly RAPD_CMD_PROCESS
    local RAPD_CMD_FILE=$0 && readonly RAPD_CMD_FILE
    local RAPD_CMD_ARGS=$* && readonly RAPD_CMD_ARGS
    local RAPD_CMD_ARGS_LEN=$# && readonly RAPD_CMD_ARGS_LEN
    info() {
        local PID="$$"
        local FILE="$RAPD_CMD_FILE"
        echo "{
            \"pid\": \"$PID\",
            \"file\": \"$FILE\",        
            \"args\": \"$*\",
            \"args_len\": \"$#\",
            \"name\": \"$RAPD_CMD_NAME\",
            \"initialized\": \"$RAPD_INITIALIZED\",
            \"binary\": \"$RAPD_IS_BINARY\"
        }"
    }
    usage() {
        echo "usage from process $*"
    }
    nnf "$@" || usage "$?" "$@" && return 1
}
(
    export -f process
)
