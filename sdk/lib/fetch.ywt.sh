#!/usr/bin/env bash
# shellcheck disable=SC2317,SC2120,SC2155,SC2044
# fecth requests like node.js
fetch() {
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
        local URL="${1}" && shift && URL="$(parse url "${URL}")"
        [[ -z "$(jq -r '.uri' <<<"${URL}")" ]] && echo "No URL" | logger error && return 1
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
        )
        while IFS= read -r HEADER; do
            CURL_ARGS+=("--header" "'${HEADER}'")
        done < <(jq -r '.headers | to_entries[] | "\(.key): \(.value)"' <<<"${OPTIONS}")
        curl "${CURL_ARGS[@]}" | __response && exit 244
        # echo "URL=$(jq . <<<"$URL")" &&
        #     echo "OPTIONS=$(jq . <<<"$OPTIONS")" &&
        #     echo "CURL_ARGS=${CURL_ARGS[*]}"

    }
    __response() {
        local RESPONSE="${1}"
        if [ -p /dev/stdin ]; then
            RESPONSE=$(cat -)
            while IFS= read -r LINE; do
                if [ -z "$LINE" ]; then continue; fi
                RESPONSE+="\n$LINE"
            done
        fi
        RESPONSE=$(echo -e "${RESPONSE}" | sed -e 's/^[[:space:]]*// ' -e 's/[[:space:]]*$//' | tr -d '\r' | sed '1{/^$/d}' | sed "s,\x1B\[[0-9;]*[a-zA-Z],,g")
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
            # echo -n "\"stats\":${STATS}"            
            echo -n "{\"body\":" 
            if __is json "${BODY}"; then
                local IS_JSON=true
                echo -n "${BODY}" | jq -c                 
            else               
                BODY=$(echo -n "${BODY}" | sed 's/"/\\"/g' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
                echo -n "\"${BODY}\""
            fi
            echo -n ",\"json\":${IS_JSON}"
            echo -n ",\"ok\":$( [ "$STATUS_CODE" -ge 200 ] && [ "$STATUS_CODE" -lt 300 ] && echo "true" || echo "false" )"
            echo -n "}"
        })"
        RESPONSE=$(jq --slurp '{"status": .[0], "headers": .[1], "stats": .[2], "response": .[3]}' <<<"${RESPONSE}")
        echo "${RESPONSE}" | jq -C .
        return 0
    }

    [ "$0" == "curl" ] && shift
    __send "$@"
    exit 255

    local HEADERS=()
    local DATA=()
    local METHOD="GET"
    while [ "$#" -gt 0 ]; do
        case "${1}" in
        -H | --header)
            HEADERS+=("${2}")
            shift 2
            ;;
        -d | --data)
            DATA+=("${2}")
            shift 2
            ;;
        -X | --request)
            METHOD="${2}"
            shift 2
            ;;
        *)
            shift
            ;;
        esac
    done
    __nnf "$@" || usage "tests" "$?" "$@" && return 1
}
(
    export -f fetch
)
