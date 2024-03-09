#!/bin/bash
# shellcheck disable=SC2044,SC2155,SC2317
process() {
    info() {
        local PID="$$"
        local FILE="$RAPD_CMD_FILE"
        echo "{
            \"pid\": \"$PID\",
            \"file\": \"$FILE\",        
            \"args\": \"$*\",
            \"args_len\": \"$#\"
        }"
    }
    usage(){
        echo "usage from process $*"
    }
    nnf "$@" || usage "$?" "$@" && return 1
}
(
    export -f process
)
