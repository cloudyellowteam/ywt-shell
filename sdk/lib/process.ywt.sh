#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
process() {
    local YWT_IS_BINARY=false
    LC_ALL=C grep -a '[^[:print:][:space:]]' "$YWT_CMD_FILE" >/dev/null && YWT_IS_BINARY=true
    local YWT_CMD_PROCESS=$$ && readonly YWT_CMD_PROCESS
    local YWT_CMD_FILE=$0 && readonly YWT_CMD_FILE
    local YWT_CMD_ARGS=$* && readonly YWT_CMD_ARGS
    local YWT_CMD_ARGS_LEN=$# && readonly YWT_CMD_ARGS_LEN
    info() {
        local PID="$$"
        local FILE="$YWT_CMD_FILE"
        echo "{
            \"pid\": \"$PID\",
            \"file\": \"$FILE\",        
            \"args\": \"$*\",
            \"args_len\": \"$#\",
            \"name\": \"$YWT_CMD_NAME\",
            \"initialized\": \"$YWT_INITIALIZED\",
            \"binary\": \"$YWT_IS_BINARY\"
        }"
    }
    nnf "$@" || usage "$?" "$@" && return 1
}
(
    export -f process
)
