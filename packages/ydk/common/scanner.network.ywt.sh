#!/usr/bin/env bash
# shellcheck disable=SC2317,SC2120,SC2155,SC2044
__scanner:network:hsts() {
    local TARGET="$1" && shift
    local SCANNER="$({
        echo -n "{"
        echo -n "\"scanner\":\"ywt-network-hsts\","
        echo -n "\"type\":\"url\","
        echo -n "\"format\":\"json\","
        echo -n "\"output\":\"$RESULT_FILE\","
        echo -n "\"start\":\"$(date +%s)\","
        echo -n "\"engines\":["
        echo -n "\"host\","
        echo -n "\"docker\""
        echo -n "]"
    })"
    if [ -z "$TARGET" ]; then
        SCANNER+=",\"error\":\"target not found\""
    else
        local URI=$(parse url "$TARGET")
        if __is nil jq -r .uri <<<"$URI"; then
            SCANNER+=",\"error\":\"invalid target\""
        else
            SCANNER+="$({
                echo -n ",\"target\":\"$TARGET\""
                echo -n ",\"uri\": $URI"
            })"
        fi

        local HSTS_HEADER=$(curl -s -I "${TARGET}" | tr '[:upper:]' '[:lower:]' | grep -i "strict-transport-security")
        if [ -z "${HSTS_HEADER}" ]; then
            SCANNER+=",\"hsts\":false"
        else
            SCANNER+=",\"hsts\":true"
            local HSTS_MAX_AGE=$(echo "${HSTS_HEADER}" | grep -oP "max-age=\d+" | cut -d'=' -f2)
            local HSTS_INCLUDE_SUBDOMAINS=$(echo "${HSTS_HEADER}" | grep -oP "includeSubDomains")
            local HSTS_PRELOAD=$(echo "${HSTS_HEADER}" | grep -oP "preload")
            SCANNER+="$({
                echo -n ",\"maxAge\":${HSTS_MAX_AGE:-0}"
                echo -n ",\"includeSubDomains\":${HSTS_INCLUDE_SUBDOMAINS:-false}"
                echo -n ",\"preload\":${HSTS_PRELOAD:-false}"
            })"
            echo -n ",\"result\":["
            {
                if [ "${HSTS_MAX_AGE}" -lt 10886400 ]; then
                    echo -n "\"HSTS max-age is less than 10886400.\","
                fi
                if [ -z "${HSTS_INCLUDE_SUBDOMAINS}" ]; then
                    echo -n "\"HSTS includeSubDomains is not enabled.\","
                fi
                if [ -z "${HSTS_PRELOAD}" ]; then
                    echo -n "\"HSTS preload is not enabled.\","
                fi
            } | sed 's/,$//'
            echo -n "]"

        fi
    fi
    echo "${SCANNER}, \"end\":\"$(date +%s)\"}" | jq -c .
}
