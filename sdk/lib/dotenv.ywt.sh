#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
dotenv() {
    YWT_LOG_CONTEXT="DOTENV"
    load() {
        local FILE=${1}
        [ ! -f "$FILE" ] && logger error "File $FILE not found" && return 1
        local CONTENT=$(cat "$FILE") && CONTENT=$(envsubst "$FILE")
        [ -z "$CONTENT" ] && logger info "File $FILE is empty" && return 0
        # append new line to content
        CONTENT="$CONTENT"$'\n'
        local NS=${YWT_PROJECT_NAMESPACE:-YWT} && [ -n "$2" ] && NS="${NS}_${2^^}"
        local INJECT=${3:-false}
        local JSON="{"
        while IFS= read -r LINE || [ -n "$LINE" ]; do
            IFS='=' read -r KEY VALUE <<<"$LINE"
            [[ -z "$LINE" || -z "$KEY" || "$KEY" =~ ^#.*$ || "$VAR" =~ ^#.*$ ]] && continue
            [[ $INJECT == true ]] && export "${NS^^}_${KEY}"="$VALUE" # || echo "${NS^^}_${KEY}=$VALUE" >>"$YWT_PATH_TMP/.env" # eval "export ${NS^^}_${VAR}"
            JSON="$JSON\"${NS^^}_${KEY}\":\"${VALUE}\","
            local MASKED=$(echo "$VALUE" | sed -E 's/./*/g')
            __debug "Dotenv: ${NS^^}_${KEY}=$MASKED - ${FILE}"
        done <<<"$CONTENT"
        JSON="${JSON%,}"
        JSON="$JSON}"
        echo "$JSON"
        return 0
    }
    __nnf "$@" || usage "$?" "$@" && return 1
}
(
    export -f dotenv
)
