#!/usr/bin/env bash
# shellcheck disable=SC2317,SC2120,SC2155,SC2044
# fecth requests like node.js
fetch() {
    YWT_LOG_CONTEXT="fetch"
    __metrics() {
        [ -z "$HTTP_METRIC" ] && local HTTP_METRIC=(
            "url_effective" "http_code" "response_code" "http_connect" "time_namelookup" "time_connect" "time_appconnect" "time_pretransfer" "time_starttransfer" "size_header" "size_request" "size_download" "size_upload" "speed_download" "speed_upload" "content_type" "num_connects" "time_redirect" "num_redirects" "ssl_verify_result" "proxy_ssl_verify_result" "filename_effective" "remote_ip" "remote_port" "local_ip" "local_port" "http_version" "scheme"
        ) && readonly HTTP_METRIC
        {
            echo -n "{"
            for METRIC in "${HTTP_METRIC[@]}"; do
                echo -n "\"${METRIC}\":\"%{${METRIC}}\","
            done
            echo -n "\"metrics\":\"%{time_total}\""
            echo -n "}"
        } | jq -c .
    }
    __check_header() {
        local HEADERS="${1:-"{}"}" && shift
        for VALUE in "${@}"; do
            local HEADER_VALUE=$(jq -r ".[\"${VALUE}\"]" <<<"${HEADERS}")
            if [ -n "${HEADER_VALUE}" ]; then
                echo -n "${HEADER_VALUE}"
                return 0
            fi
        done
        echo -n "0"
        return 1
    }
    __extract_rate_limit() {
        local HEADERS="${1:-"{}"}"
        local RATE_LIMIT="$(__check_header "$HEADERS" "x-ratelimit-limit" "x-rate-limit-limit")"
        local RATE_REMAIN="$(__check_header "$HEADERS" "x-ratelimit-remaining" "x-rate-limit-remaining")"
        local RATE_RESET="$(__check_header "$HEADERS" "x-ratelimit-reset" "x-rate-limit-reset")" && RATE_RESET=$((RATE_RESET < 0 ? 0 : RATE_RESET))
        local RATE_RESET_AT=$(date -u -d "@${RATE_RESET}" "+%Y-%m-%d %H:%M:%S")
        local RATE_WINDOW="$(($(date +%s) - RATE_RESET))" && RATE_WINDOW=$((RATE_WINDOW < 0 ? 0 : RATE_WINDOW))
        if [ -z "${RATE_WINDOW}" ] || [ "${RATE_WINDOW}" == "null" ]; then
            RATE_WINDOW=0
        fi
        RATE_WINDOW=$(date -u -d "@${RATE_WINDOW}" "+%H:%M:%S")
        local RATE_TIMESTAMP=$(date -u -d "@$(date +%s)" "+%Y-%m-%d %H:%M:%S")
        echo -n "{\"max\":${RATE_LIMIT},\"remain\":${RATE_REMAIN},\"reset\":${RATE_RESET}, \"reset_at\":\"${RATE_RESET_AT}\", \"window\":\"${RATE_WINDOW}\", \"timestamp\":\"${RATE_TIMESTAMP}\"}"
    }
    __cookies() {
        local HEADERS="${1:-"{}"}"
        jq -r '
            if .headers == null or .headers == {} then
                empty
            else
                .headers | to_entries[]
            end
            | select(.key | startswith("Set-Cookie"))
            | .value
            | split(";") | map(split("=")) | .[0] as $key | .[1] as $value | {($key): $value}
        ' <<<"${HEADERS}"
    }
    __scurl() {
        local URL="${1}"
        local METHOD="${2:-GET}"
        local DATA="${3:-}"
        local HEADERS="${4:-}"
        local TIMEOUT="${5:-3}"
        local RESPONSE=$(curl -s -X "${METHOD}" -H "${HEADERS}" -d "${DATA}" -m "${TIMEOUT}" "${URL}")
        [ -z "${RESPONSE}" ] && echo "No response" | logger error && return 1
        echo "${RESPONSE}" && return 0
    }
    __options() {
        local OPTIONS=$({
            [ -z "$1" ] && echo "{
                \"method\":\"GET\",
                \"headers\":{},
                \"data\":{},
                \"timeout\":3
            }" && return 0
            echo -n "$1" && return 0
        } | jq -c .)
        __is nil "$(jq -r '.method' <<<"${OPTIONS}")" && OPTIONS=$(jq -c ".method=\"GET\"" <<<"${OPTIONS}")
        __is nil "$(jq -r '.headers' <<<"${OPTIONS}")" && OPTIONS=$(jq -c ".headers={}" <<<"${OPTIONS}")
        __is nil "$(jq -r '.data' <<<"${OPTIONS}")" && OPTIONS=$(jq -c ".data={}" <<<"${OPTIONS}")
        __is nil "$(jq -r '.timeout' <<<"${OPTIONS}")" && OPTIONS=$(jq -c ".timeout=3" <<<"${OPTIONS}")
        echo "${OPTIONS}" && return 0

    }
    __send() {
        # local URL="https://jsonplaceholder.typicode.com/todos/1"
        # URL="https://httpbin.org"
        local URL="${1}" && shift && ! __is json "${URL}" && URL="$(parse url "${URL}")"
        __is nil "$(jq -r '.uri' <<<"${URL}")" && echo "No URL ${URL:-empty}" | logger error && return 1
        local OPTIONS=$(__options "$1") && shift && OPTIONS=$(jq . <<<"${OPTIONS}")
        local AUTZ="$(jq -r '.credentials' <<<"${URL}")"
        if [ -n "${AUTZ}" ]; then
            local AUTHORIZATION=$(jq -c ".headers.Authorization=\"Basic $(echo -n "${AUTZ}" | base64 -w 0)\"" <<<"${OPTIONS}")
            OPTIONS=$(jq -c ".=${AUTHORIZATION}" <<<"${OPTIONS}")
            # OPTIONS=$(jq -c ".headers=${HEADERS}" <<<"${OPTIONS}")
            # URL=$(jq -c 'del(.credentials)' <<<"${URL}")
            # remove credentials from uri property in url
            #URI="$(jq -r '.uri' <<<"${URL}")" && URI="${URI/$AUTZ@/}" #&& URL=$(jq -c ".uri=\"${URI}\"" <<<"${URL}")
        fi
        # get request unique id from uri
        local REQUEST_ID=$(echo -n "$(jq -r '.uri' <<<"${URL}")" | md5sum | cut -d' ' -f1)
        local RESPONSE_FILE="/tmp/ywt.request.${REQUEST_ID}.json" && export RESPONSE_FILE
        # local RESPONSE_FILE="$(mktemp -u -t ywt.request.XXXXXX -p /tmp --suffix=.json)" && export RESPONSE_FILE
        local CURL_ARGS=(
            "--include"
            "--silent"
            "--show-error"
            "--location"
            "--user-agent" "'ywt/0.0.0-alpha.0'"
            "--request" "$(jq -r '.method' <<<"${OPTIONS}")"
            # "--header $(jq -r '.headers' <<<"${OPTIONS}")"
            # "--data $(jq -r '.data' <<<"${OPTIONS}")"
            "--connect-timeout" "$(jq -r '.timeout' <<<"${OPTIONS}")"
            "--retry" "3"
            "--retry-delay" "3"
            "--retry-max-time" "30"
            "--write-out" "'$(__metrics)'"
            # "--output -"
            "--url" "$(jq -r '.uri' <<<"${URL}")"
            # send ywt cookie
            # "--cookie" "'ywt=$(jq -r '.cookies.ywt' <<<"${OPTIONS}")'"
            # "--cookie" "'ywt=0.0.0-alpha.0'"
        )
        while IFS= read -r HEADER; do
            CURL_ARGS+=("--header" "'${HEADER}'")
        done < <(jq -r '.headers | to_entries[] | "\(.key): \(.value)"' <<<"${OPTIONS}")
        logger info "🔼 $(jq -r '.method' <<<"${OPTIONS}") $(jq -r '.uri' <<<"${URL}")"
        local RESPONSE=$(curl "${CURL_ARGS[@]}" | response)
        local LOG_MESSAGE=$({
            echo -n "🔽"
            echo -n " $(jq -r '.method' <<<"${OPTIONS}")"
            echo -n " $(jq -r '.stats.url_effective' <<<"${RESPONSE}")"
            echo -n " $(jq -r '.status.status_code' <<<"${RESPONSE}")"
            echo -n " $(jq -r '.stats.metrics' <<<"${RESPONSE}")"
            # echo -n " $(jq -r '.stats.remote_ip' <<<"${RESPONSE}")"
            echo -n " ${YELLOW}$RESPONSE_FILE${NC}"
            echo -n " $REQUEST_ID"
        })
        if [ "$(jq -r '.ok' <<<"${RESPONSE}")" = "false" ]; then
            logger error "${LOG_MESSAGE}"
            local STATUS=1
        else
            logger success "${LOG_MESSAGE}"
            local STATUS=0
        fi
        # jq no color 
        jq -c <<<"${RESPONSE}" >"${RESPONSE_FILE}"
        # cat "${RESPONSE_FILE}"
        jq . <"${RESPONSE_FILE}"
        return "${STATUS}"
    }
    response() {
        local RESPONSE="${1}"
        if [ -p /dev/stdin ]; then
            RESPONSE=$(cat -)
            while IFS= read -r LINE; do
                if [ -z "$LINE" ]; then continue; fi
                RESPONSE+="\n$LINE"
            done
        fi
        RESPONSE=$(echo -e "${RESPONSE}" | sed -e 's/^[[:space:]]*// ' -e 's/[[:space:]]*$//' | tr -d '\r' | sed '1{/^$/d}' | sed "s,\x1B\[[0-9;]*[a-zA-Z],,g")
        # response start with curl: ( "curl error"
        if [[ "${RESPONSE}" =~ ^curl: ]]; then
            echo -n "{\"protocol\":\"\",\"status_code\":0,\"status_message\":\"${RESPONSE}\"}"
            return 1
        fi
        local IS_HEADER=true
        local IS_FIRST=true
        RESPONSE="$({
            BODY=""
            STATS=""
            while IFS= read -r LINE || [ -n "$LINE" ]; do
                if [ "$IS_FIRST" = true ]; then
                    local PROTOCOL="$(echo -n "$LINE" | cut -d' ' -f1)"
                    local STATUS_CODE="$(echo -n "$LINE" | cut -d' ' -f2)"
                    local STATUS_MESSAGE="$(echo -n "$LINE" | cut -d' ' -f3-)"
                    echo -ne "{\"protocol\":\"${PROTOCOL}\",\"status_code\":\"${STATUS_CODE}\",\"status_message\":\"${STATUS_MESSAGE}\"}{"
                    IS_FIRST=false
                elif [ "$IS_HEADER" = true ]; then
                    if [[ -n "${LINE}" ]]; then
                        local KEY="$(echo -n "$LINE" | cut -d':' -f1)"
                        local VALUE="$(echo -n "$LINE" | cut -d':' -f2- | sed 's/"/\\"/g' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')"
                        if [ "${KEY}" = "Set-Cookie" ]; then
                            VALUE=$(echo -n "${VALUE}" | tr ';' '\n' | tr -d '\n\t')
                        fi
                        echo -ne "\"${KEY}\":\"${VALUE}\"", | tr -d '\n\t'
                    else
                        echo -n '"x-ywt-version": "0.0.0-alpha.0"}'
                        IS_HEADER=false
                    fi
                else
                    BODY+="${LINE}"
                    # echo -ne "${LINE}"
                fi
            done < <(echo -e "${RESPONSE}")
            local IS_JSON=false
            STATS=$(echo "$BODY" | grep -oP "'{.*}'" | tail -n 1)
            STATS=$(echo -n "${STATS}" | sed "s/^'//" | sed "s/'$//")
            echo -n "${STATS}"
            # replace STATS from BODY
            BODY=$(echo -n "${BODY}" | sed "s/'{.*}'//")
            echo -n "{\"data\":"
            if __is json "${BODY}"; then
                local IS_JSON=true
                echo -n "${BODY}" | jq -c
            else
                BODY=$(echo -n "${BODY}" | sed 's/"/\\"/g' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
                echo -n "\"${BODY}\""
            fi
            echo -n ",\"json\":${IS_JSON}"
            echo -n ",\"ok\":$([ "$STATUS_CODE" -ge 200 ] && [ "$STATUS_CODE" -lt 300 ] && echo "true" || echo "false")"
            echo -n "}"
        })"
        RESPONSE=$(jq --slurp '{"status": .[0], "headers": .[1], "stats": .[2], "response": .[3]}' <<<"${RESPONSE}")
        RATE_LIMIT="$(__extract_rate_limit "$(jq -r '.headers' <<<"${RESPONSE}")")"
        COOKIES="$(__cookies "$(jq -r '.headers' <<<"${RESPONSE}")")"
        # logger info "[Response] $(jq -r '.status.status_code, .stats.url_effective' <<<"${RESPONSE}")"
        jq -c '. + {
            "cookies": '"${COOKIES:-"{}"}"', 
            "limit": '"${RATE_LIMIT}"',
            "ok": '.response.ok',
            "json": '.response.json'
        } | del(.response.ok, .response.json)' <<<"${RESPONSE}"
        # RESPONSE=$(jq -c '. + {"limit": '"${RATE_LIMIT}"'}' <<<"${RESPONSE}")
        # jq -C . <<< "${RESPONSE}"
        return 0
    }

    [ "$0" == "curl" ] && shift
    local METHOD="${1:-GET}"
    local URI="${2}" && [[ "${URI:-1}" != "/" ]] && URI="${URI}/" 
    URI="$(parse url "${URI}")" 
    if __is nil "$(jq -r '.uri' <<<"${URI}")"; then 
        echo "No URL2 (${URI})" | logger error 
        return 1
    fi
    case "${METHOD,,}" in    
    g | get)
        __send "$URI" '{"method":"'"${METHOD^^}"'"}'
        ;;
    p | post)
        __send "$URI" '{"method":"'"${METHOD^^}"'"}'
        ;;
    d | delete)
        __send "$URI" '{"method":"'"${METHOD}"'"}'
        ;;
    h | head)
        __send "$URI" '{"method":"'"${METHOD^^}"'"}'
        ;;
    o | options)
        __send "$URI" '{"method":"'"${METHOD^^}"'"}'
        ;;
    *) __nnf "$@" || usage "tests" "$?" "$@" && return 1 ;;
    esac
}
(
    export -f fetch
)
