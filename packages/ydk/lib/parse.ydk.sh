#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:parse() {
    ydk:try "$@" 4>&1
    return $?
}

# parse() {
#     querystring() {
#         __require awk sed
#         local URI=${1}
#         if [[ $URI =~ .*\?([^#]*).* ]]; then
#             QS="${BASH_REMATCH[1]}"
#             JSON=$(echo "$QS" | tr '&' '\n' | awk -F '=' '{printf "\"%s\":\"%s\",\n", $1, $2}' | sed 's/,$//') && JSON="{ ${JSON} }" && JSON=$(echo "$JSON" | tr -d '\n') && JSON="${JSON//\"\"/\",\"}" 
#             
#             echo "$JSON"
#         fi
# 
#     }
#     url() {
#         __require cut rev
#         local URI=${1}
#         # [[ "${URI:-1}" != "?" ]] && URI="$URI?key=value"
#         local URI_SCHEME=$(echo "$URI" | grep "://" | sed -e's,^\(.*://\).*,\1,g')
#         local URI_NO_SCHEME="${URI/$URI_SCHEME/}" # $(echo "${URI/$URI_SCHEME/}" | cut -d/ -f3-)
#         local URI_PROTOCOL=$(echo "$URI_SCHEME" | sed -e's,^\(.*://\).*,\1,g' | sed -e's,://,,g')
#         local URI_CREDENTIAL=$(echo "$URI_NO_SCHEME" | grep "@" | cut -d"/" -f1 | rev | cut -d"@" -f2- | rev)
#         local URI_PASSWORD=$(echo "$URI_CREDENTIAL" | grep ":" | cut -d":" -f2)
#         if [[ -n $URI_PASSWORD ]]; then
#             URI_USER=$(echo "$URI_CREDENTIAL" | grep ":" | cut -d":" -f1)
#         else
#             URI_USER="$URI_CREDENTIAL"
#         fi
#         local URI_HOST_PORT=$(echo "${URI_NO_SCHEME/$URI_CREDENTIAL@/}" | cut -d"/" -f1 | cut -d"?" -f1)
#         local URI_HOST=$(echo "$URI_HOST_PORT" | cut -d":" -f1)
#         local URI_PORT=$(echo "$URI_HOST_PORT" | grep ":" | cut -d":" -f2)
#         local URI_PATH=$(echo "${URI_NO_SCHEME}" | grep "/" | cut -d"/" -f2-) && 
#         URI_PATH=$(echo "$URI_PATH" | grep "?" | cut -d"?" -f1)
#         local URI_QUERY=$(echo "$URI_NO_SCHEME" | grep "?" | cut -d"?" -f2)
#         if [[ -n $URI_QUERY ]]; then
#             local URI_QUERY_STRING=$(querystring "$URI")
#         else
#             local URI_QUERY_STRING="{}"
#         fi
#         local URI_ANCHOR=$(echo "$URI_QUERY" | grep "#" | cut -d"#" -f2)
#         echo "{
#             \"scheme\": \"$URI_SCHEME\",
#             \"protocol\": \"$URI_PROTOCOL\",
#             \"credentials\": \"$URI_CREDENTIAL\",
#             \"user\": \"$URI_USER\",
#             \"password\": \"$URI_PASSWORD\",
#             \"hostport\": \"$URI_HOST_PORT\",
#             \"host\": \"$URI_HOST\",
#             \"port\": \"$URI_PORT\",
#             \"path\": \"$URI_PATH\",
#             \"query\": \"$URI_QUERY\",
#             \"querystring\": $URI_QUERY_STRING,
#             \"anchor\": \"$URI_ANCHOR\",
#             \"uri\": \"$URI\",
#             \"surl\": \"${URI/$URI_CREDENTIAL@/}\"
#         }" | jq '.' -c
#         return 0
#     }
#     __nnf "$@" || usage "parse" "$?" "$@" && return 1
# }
# (
#     export -f parse
# )
