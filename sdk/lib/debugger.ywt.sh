#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
debugger() {
    YWT_LOG_CONTEXT="debugger"
    watch() {
        (tail -f "$YWT_FIFO") && wait        
    }
    _verbose() {
        echo "$1" 1>&2
    }
    if __nnf "$@"; then return 0; fi
    usage "$?" "debugger" "$@" && return 1
}
