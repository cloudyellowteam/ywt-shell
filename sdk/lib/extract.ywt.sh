#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
extract() {
    json() {
        local TEXT="$1"
        [ -z "$TEXT" ] && while read -r line; do TEXT+="$line"; done
        echo "$TEXT" | sed -n '/{/,$p' | jq -sR 'fromjson? | select(.)'
    }
    __nnf "$@" || usage "$?" "extract" "$@" && return 1
}
(
    export -f extract
)
