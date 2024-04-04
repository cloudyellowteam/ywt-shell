#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317

# if ! __is command envsubst; then
#     __debug "envsubst not found, injecting polyfill..."
if ! command -v envsubst >/dev/null 2>&1; then
    # __debug "envsubst not found, injecting polyfill..."
    envsubst() {
        export YWT_LOG_CONTEXT="ENVSUBST"
        local FILE_PATH="$1"
        [ -z "$FILE_PATH" ] && __log error "File path not defined" && return 1
        [ ! -f "$FILE_PATH" ] && __log error "File not found" && return 1
        while IFS= read -r LINE || [ -n "$LINE" ]; do
            while [[ "$LINE" =~ (\$\{([a-zA-Z_][a-zA-Z_0-9]*)\}) ]]; do
                local FULL_MATCH=${BASH_REMATCH[1]}
                local VAR_NAME=${BASH_REMATCH[2]}
                local VAR_VALUE=${!VAR_NAME:-}
                LINE=${LINE//$FULL_MATCH/$VAR_VALUE}
            done
            echo "$LINE"
        done <"$FILE_PATH"
        return 0
    }
    (
        export -f envsubst
    )
fi
