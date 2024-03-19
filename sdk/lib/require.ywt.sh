#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
require() {
    deps() {
        local DEPENDENCIES=("$@")
        for DEPENDENCY in "${DEPENDENCIES[@]}"; do
            if ! __is command "${DEPENDENCY}"; then
                __debug "required ${DEPENDENCY} (command not found)"
                YWT_MISSING_DEPENDENCIES+=("${DEPENDENCY}")                
            fi
        done
        [ "${#YWT_MISSING_DEPENDENCIES[@]}" -eq 0 ] && return 0
        local MSG="Missing dependencies: ${YWT_MISSING_DEPENDENCIES[*]}"
        __log error "$MSG" && return 1
        return 1
    }
    __nnf "$@" || usage "require" "$?" "$@" && return 1
}
(
    export -f require
)
