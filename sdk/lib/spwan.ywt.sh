#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
spwan() {
    [ -z "$YWT_PIDS" ] && declare -a YWT_PIDS && readonly YWT_PIDS
    run() {
        local CMD="$*"
        $CMD &
        YWT_PIDS+=($!)
        echo $!
        return 0
    }
    nnf "$@" || usage "$?" "$@" && return 1
}
(
    export -f spwan
)
