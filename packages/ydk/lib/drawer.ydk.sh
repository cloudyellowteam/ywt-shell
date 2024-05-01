#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:drawer() {
    ydk:try "$@" 4>&1
    return $?
}
# drawer() {
#     box(){
#         local TITLE="$1" && shift
#         local CONTENT="$1" && shift
#         echo -n "┌"
#         for ((i=0; i<${#TITLE}+2; i++)); do
#             echo -n "─"
#         done
#         echo "┐"
#         echo "│ $TITLE │"
#         echo -n "└"
#         for ((i=0; i<${#TITLE}+2; i++)); do
#             echo -n "─"
#         done
#         echo "┘"
#         echo -n "$CONTENT"
#         echo -n "└"
#         for ((i=0; i<${#TITLE}+2; i++)); do
#             echo -n "─"
#         done
#         echo "┘"
#     }
#     __nnf "$@" && return "$?"
# }