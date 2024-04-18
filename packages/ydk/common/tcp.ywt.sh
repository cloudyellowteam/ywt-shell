#!/usr/bin/env bash
# shellcheck disable=SC2317,SC2120,SC2155,SC2044
tcp() {
    request() {
        local HOST="${1}"
        local PORT="${2}"
        local DATA="${3}" # '{"key": "value"}'
        local REQUEST="$({
            echo "GET / HTTP/1.1"
            echo "Host: ${HOST}"
            echo "Connection: close"
            echo "User-Agent: curl/7.64.1"
            echo "Accept: */*"
            echo "Content-Type: application/json"
            echo "Content-Length: ${#DATA}"
            echo ""
            echo "${DATA}"        
        })"
        if __is command nc; then
            local RESPONSE=$(echo -e "${REQUEST}" | nc -w 3 "${HOST}" "${PORT}")
        elif __is command telnet; then
            local RESPONSE=$(echo -e "${REQUEST}" | telnet "${HOST}" "${PORT}")
        elif __is command bash; then
            exec 4<>/dev/tcp/"${HOST}"/"${PORT}"
            echo -e "${REQUEST}" >&4
            local RESPONSE=$(cat <&4)
            exec 4>&-
        else
            echo "No network tools found" | logger error
            return 1
        fi
        [ -z "${RESPONSE}" ] && echo "No response" | logger error && return 1
        echo "${RESPONSE}" && return 0        
    }
    __nnf "$@" || usage "tests" "$?" "$@" && return 1
}
(
    export -f tcp
)