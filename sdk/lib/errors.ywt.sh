#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
errors() {
    code() {
        local code=${1:?} && [ -z "$code" ] && echo "Invalid error code" | logger error && return 1
        local message=${2:?} && [ -z "$message" ] && echo "Invalid error message" | logger error && return 1
        echo "{
            \"code\": \"$code\",
            \"message\": \"$message\"
        }"
    }
    _throw() {
        local ERROR_CODE=${1:$?} && shift
        local MESSAGE=${1:-"An error occurred"} && shift
        _fail "$ERROR_CODE" "$MESSAGE"
    }
    __nnf "$@" || usage "errors" "$?" "styles" "$@" && return 1
    return 0
}
(
    export -f errors
)
