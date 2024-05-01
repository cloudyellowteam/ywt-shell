#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:resources() {
    ydk:try "$@" 4>&1
    return $?
}

# resources() {
#     __find() {
#         local TYPE=${1:-} && [ -z "$TYPE" ] && echo "Resource type not defined" && return 1
#         local RESOURCE_PATH && RESOURCE_PATH=$(jq -r ".$TYPE" <<<"$YWT_PATHS")
#         [ ! -d "$RESOURCE_PATH" ] && echo "Resource $TYPE not found" && return 1
#         find "$RESOURCE_PATH" -mindepth 1 -maxdepth 1 -type d -printf '%P\n' | jq -R -s -c 'split("\n") | map(select(length > 0))'
#     }
#     __nnf "$@" || usage "resources" "$?" "$@" && return 1
# 
# }
# (
#     export -f resources
# )
