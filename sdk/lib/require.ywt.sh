#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
require() {
    dependencies() {
        local DEPENDENCIES=("$@")
        for DEPENDENCY in "${DEPENDENCIES[@]}"; do
            if ! command -v "${DEPENDENCY}" >/dev/null 2>&1; then
                logger error "required ${DEPENDENCY} (command not found)"
                return 1
            fi
        done
        return 0
    } 
    if [ -n "$(type -t "$1")" ] && [ "$(type -t "$1")" != function ]; then
        dependencies "$1" && return $?
    else
        _nnf "$@" || usage "$?" "builder" "$@" && return 1
        return 0
    fi
}
(
    export -f require
)
