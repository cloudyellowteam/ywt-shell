#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:debugger() {
    ydk:try "$@"
    return $?
}
# debugger() {
#     YWT_LOG_CONTEXT="debugger"
#     watch() {
#         __require tail wait kill        
#         (tail -f "$FIFO") && wait && kill "$!"
#     }
#     _verbose() {
#         echo "$1" 1>&2
#     }
#     if __nnf "$@"; then return 0; fi
#     usage "debugger" "$?" "debugger" "$@" && return 1
# }
