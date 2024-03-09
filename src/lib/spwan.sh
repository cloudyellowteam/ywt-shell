#!/bin/bash
# shellcheck disable=SC2044,SC2155,SC2317
spwan() {
    [ -z "$RAPD_PIDS" ] && declare -a RAPD_PIDS && readonly RAPD_PIDS
    run() {
        local CMD="$*"
        $CMD &
        RAPD_PIDS+=($!)
        echo $!
        return 0
    }
    usage() {
        echo "usage from spwan $*"
    }
    nnf "$@" || usage "$?" "$@" && return 1
}
(
    export -f spwan
)
