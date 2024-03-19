#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
require() {
    deps(){
        __require "$@"
    }
    __nnf "$@" || usage "require" "$?" "$@" && return 1    
}
(
    export -f require
)
