#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:spwan() {
    ydk:try "$@"
    return $?
}

# spwan() {
#     [ -z "$YWT_PIDS" ] && declare -a YWT_PIDS && readonly YWT_PIDS
#     run() {
#         local CMD="$*"
#         $CMD &
#         YWT_PIDS+=($!)
#         echo $!
#         return 0
#     }
#     __nnf "$@" || usage "spwan" "$?" "$@" && return 1
# }
# (
#     export -f spwan
# )
