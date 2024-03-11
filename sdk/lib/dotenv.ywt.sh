#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
dotenv() {
    load() {
        local FILE=${1}
        [ ! -f "$FILE" ] && logger error "File $FILE not found" && return 1
        # check if envsubst is available
        local CONTENT=$(cat "$FILE")
        # if ! command -v envsubst >/dev/null 2>&1; then
        #     logger warn "envsubst not found, using cat"
        #     local CONTENT=$(cat "$FILE")
        # else
        #     local CONTENT=$(envsubst "$@" <"$FILE") && [ -z "$CONTENT" ] && CONTENT=$(cat "$FILE")
        # fi
        [ -z "$CONTENT" ] && logger info "File $FILE is empty" && return 0
        local NS=${RAPD_PROJECT_NAMESPACE:-RAPD} && [ -n "$2" ] && NS="${NS}_${2^^}"
        local INJECT=${3:-false}
        local QUIET=${4:-true}
        local JSON="{"
        # logger info "Reading env file $file"
        # trap 'handle_error' ERR
        while IFS= read -r LINE || [ -n "$LINE" ]; do
            IFS='=' read -r KEY VALUE <<<"$LINE"
            [[ -z "$LINE" || -z "$KEY" || "$KEY" =~ ^#.*$ || "$VAR" =~ ^#.*$ ]] && continue
            [[ $INJECT == true ]] && export "${NS^^}_${KEY}"="$VALUE" # || echo "${NS^^}_${KEY}=$VALUE" >>"$RAPD_PATH_TMP/.env" # eval "export ${NS^^}_${VAR}"
            JSON="$JSON\"${NS^^}_${KEY}\":\"${VALUE}\","
            [[ $QUIET == false ]] && logger debug "Setting ${NS^^}_${KEY}=$VALUE"
        done <<<"$CONTENT"
        JSON="${JSON%,}"
        JSON="$JSON}"
        echo "$JSON"
    }
    usage() {
        echo "usage from dotenv $*"
    }
    nnf "$@" || usage "$?" "$@" && return 1
}
(
    export -f dotenv
)
