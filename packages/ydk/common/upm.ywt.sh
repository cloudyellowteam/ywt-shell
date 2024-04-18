#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
# universal package manager
# https://github.com/sigoden/upt/tree/main
upm(){
    install(){
        echo "install"
    }
    __nnf "$@" || usage "upm" "$?"  "$@" && return 1
}
(
    export -f upm
)