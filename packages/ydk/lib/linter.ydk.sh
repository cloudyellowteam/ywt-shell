#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:linter() {
    ydk:try "$@"
    return $?
}

# linter() {
#     lint(){
#         echo "lint"
#         # docker run --rm -v "$(pwd):/mnt" koalaman/shellcheck:latest shellcheck yourscript.sh
#     }
#     __nnf "$@" || usage "linter" "$?" "$@" && return 1    
# }
# (
#     export -f linter
# )
