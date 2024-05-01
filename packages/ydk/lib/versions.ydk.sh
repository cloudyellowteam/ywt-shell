#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:versions() {
    ydk:try "$@" 4>&1
    return $?
}

# versions() {
#     semver(){
#         echo "semver"
#     }
#     bump(){
#         echo "bump"
#     }
#     compare(){
#         echo "compare"
#     }
#     __nnf "$@" || usage "version" "$?"  "$@" && return 1
# }
# (
#     export -f versions
# )