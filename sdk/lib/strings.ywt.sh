#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
strings() {
    mask() {
        local STR="$1" && [ -z "$STR" ] && STR="$(cat)" && [ -z "$STR" ] && return 1
        local MASK="${2:-*}"
        local LENGTH="${#STR}"
        local MASK_LEN="${#MASK}"
        local MASKED=""
        for ((i = 0; i < LENGTH; i++)); do
            [ "$i" -lt 1 ] && MASKED+="${STR:i:1}" && continue
            [ "$i" -eq $((LENGTH - 1)) ] && MASKED+="${STR:i:1}" && continue
            MASKED+="${MASK:i%MASK_LEN:1}"
        done
        echo "$MASKED"
    }
    __nnf "$@" || usage "$?" "tests" "$@" && return 1
}
(
    export -f strings
)
