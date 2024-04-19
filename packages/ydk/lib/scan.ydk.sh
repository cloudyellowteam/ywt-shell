#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:scan() {
    ydk:try "$@"
    return $?
}

# 
# # Scan list
# # [{"name":"cloc","info":{"id":"bGlzdA==YvzUyUwcjrlduM","output":"/tmp/scanner-YvzUyUwcjrlduM.ywt"},"state":{"activated":true,"api":{"activate":true,"metadata":true,"version":true,"implemented":true}}},{"name":"trivy","info":{"id":"bGlzdA==YvzUyUwcjrlduM","output":"/tmp/scanner-YvzUyUwcjrlduM.ywt"},"state":{"activated":true,"api":{"activate":true,"metadata":true,"version":true,"implemented":true}}},{"name":"trufflehog","info":{"id":"bGlzdA==YvzUyUwcjrlduM","output":"/tmp/scanner-YvzUyUwcjrlduM.ywt"},"state":{"activated":true,"api":{"activate":true,"metadata":true,"version":true,"implemented":true}}}]
# 
# scan() {
#     __scan:validate() {
#         local ASSETS="$1" && shift
#         [ ! -f "${ASSETS}" ] && echo "File not found: ${ASSETS}" | logger error && return 1
#         if ! jq -e . "${ASSETS}" >/dev/null 2>&1; then
#             echo "{\"error\":\"Invalid JSON: ${ASSETS}\"}"
#             return 1
#         fi
#         # max of 10 assets
#         local ASSETS_COUNT=$(jq -c '.' "${ASSETS}" | wc -l)
#         if [ "${ASSETS_COUNT}" -gt 10 ]; then
#             echo "{\"error\":\"Max of 10 assets\"}"
#             return 1
#         fi
#     }
#     __scan:assets() {
#         local ASSETS="$1" && shift
#         if ! __scan:validate "${ASSETS}" >/dev/null 2>&1; then
#             echo "{\"error\":\"Invalid assets\"}"
#         fi
#         jq -c '.' "$ASSETS"
#         return 0
#     }
#     __scan:plan() {
#         jq -cn \
#             --argjson assets "$(__scan:assets "$1")" \
#             --argjson scanners "$(scanner list)" '
#             {
#                 assets: $assets,
#                 scanners: $scanners,
#                 plan: (
#                     $assets | map(
#                         . as $asset |
#                         $scanners | map(
#                             . as $scanner |
#                             select($asset.type | IN($scanner.metadata.capabilities[])) |
#                             {
#                                 asset: $asset,
#                                 scanner: $scanner
#                             }
#                         )
#                     ) | flatten |
#                     map(
#                         {
#                             asset: .asset,
#                             scanner: .scanner
#                         }
#                     )
#                 )
#             }
#         ' | jq '.plan'
#         # command: "scanner \(.scanner.header.name) asset [SINGLE_QUOTE]\(.asset | tojson)[SINGLE_QUOTE]"
#     }
#     plan() {
#         __scan:plan "$@" | jq -c 'del(.[] | .command)'
#     }
#     summary() {
#         __scan:plan "$@" | jq -c '
#             {
#                 assets: (map(.asset) | unique) | length,
#                 scanners: (map(.scanner.header.name) | unique) | length,
#                 executions: length
#             }
#         '
#     }
#     apply() {
#         {
#             local SCAN_TASKS=$(
#                 __scan:plan "$@" | jq -rc '
#                     .[]
#                 '
#             )
#             local SCAN_COMMANDS=()
#             while read -r TASK; do                
#                 TASK=$(jq -rc '.' <<<"${TASK}")
#                 # base64 url encode TASK
#                 local TASK_ARG=$(echo -n "${TASK}" | base64 -w 0 | tr -d '=' | tr '/+' '_-')
#                 # COMMAND="${COMMAND//\[SINGLE_QUOTE\]/\'}"
#                 # COMMAND="${COMMAND//\[DOUBLE_QUOTE\]/\"}"
#                 # COMMAND="${COMMAND//\"/\\\"}"
#                 # COMMAND="\"${COMMAND}\""
#                 # COMMAND="${COMMAND//\\\"\\\"/\"}"
#                 # echo "Executing task ${TASK}" | logger info
#                 SCAN_COMMANDS+=("scan analyze ${TASK_ARG}")
#             done <<<"${SCAN_TASKS}"      
#             # for IDX in "${!SCAN_COMMANDS[@]}"; do
#             #     local COMMAND="${SCAN_COMMANDS[$IDX]}"
#             #     # echo "Scanning ${IDX} of ${#SCAN_COMMANDS[@]}" | logger info
#             #     SCAN_COMMANDS[IDX]="scanner analyze ${COMMAND}"
#             #     # scan analyze "${COMMAND}"
#             # done      
#             # echo "${SCAN_COMMANDS[*]}"
#             async "${SCAN_COMMANDS[@]}" # & wait $!
# 
#             
#             # __scan:plan "$@" | jq -rc '.[] | .command' | while read -r COMMAND; do
#             #     SCAN_COMMANDS+=("${COMMAND}")
#             # done
#             # async "${SCAN_COMMANDS[@]}"
#             # __scan:plan "$@" | jq -rc '.[] | .command' | while read -r COMMAND; do
#             #     SCAN_COMMANDS+=("${COMMAND}")
#             #     # echo -n "{"
#             #     # echo -n "\"command\":\"${COMMAND//\"/\\\"}\","
#             #     # local SCAN_RESULT=$(${COMMAND})
#             #     # local SCAN_EXIT_STATUS=$?
#             #     # echo -n "\"exit\":$SCAN_EXIT_STATUS,"
#             #     # echo -n "\"result\":"                
#             #     # if [ "$SCAN_EXIT_STATUS" -ne 0 ]; then
#             #     #     echo "{\"error\":\"Failed: ${COMMAND}\"}"
#             #     # elif [ -z "${SCAN_RESULT}" ]; then
#             #     #     echo "{\"error\":\"Empty result\"}"
#             #     # elif jq -e . >/dev/null 2>&1 <<<"${SCAN_RESULT}"; then
#             #     #     echo "${SCAN_RESULT}" | jq -c '.'
#             #     # else 
#             #     # SCAN_RESULT="${SCAN_RESULT//\"/\\\"}" && SCAN_RESULT="${SCAN_RESULT//$'\n'/}" && SCAN_RESULT="${SCAN_RESULT//$'\r'/}" && SCAN_RESULT="${SCAN_RESULT//$'\t'/}" && SCAN_RESULT="${SCAN_RESULT//$'\v'/}" && SCAN_RESULT="${SCAN_RESULT//$'\f'/}"
#             #     #     echo "{\"error\":\"Invalid JSON: ${SCAN_RESULT}\"}"
#             #     # fi
#             #     # echo -n "}"
#             #     # echo 
#             #     # [[ ! "${COMMAND,,}" =~ ^scanner ]] && continue
#             #     # echo "Executing: ${COMMAND}" | logger info
#             #     # ${COMMAND} | jq -c '.' | logger success
#             #     # echo "$?" | logger warn
#             #     # break
#             #     # if ! "${COMMAND}" >/dev/null 2>&1; then
#             #     #     echo "Failed: ${COMMAND}" | logger error
#             #     #     return 1
#             #     # else
#             #     #     echo "Success: ${COMMAND}" | logger success
#             #     # fi
#             #     # eval "${COMMAND}"
#             # done
#             
#         } #| jq -s '.'
#     }
#     analyze() {
#         local SCAN_JSON=$(echo -n "$1" | base64 -d 2>/dev/null)
#         if [[ -n "$SCAN_JSON" ]] && jq -e . >/dev/null 2>&1 <<<"${SCAN_JSON}"; then
#             SCAN_JSON=$(jq -c '.' <<<"${SCAN_JSON}")
#             local SCAN_ASSET=$(jq -r '.asset' <<<"${SCAN_JSON}")
#             local SCAN_ASSET_TYPE=$(jq -r '.type' <<<"${SCAN_ASSET}")
#             local SCAN_SCANNER=$(jq -r '.scanner' <<<"${SCAN_JSON}")
#             local SCAN_SCANNER_NAME=$(jq -cr '.header.name' <<<"${SCAN_SCANNER}")
#             local SCAN_ASSET_ARG="$(jq -c '.' <<<"${SCAN_ASSET}")" && SCAN_ASSET_ARG="${SCAN_ASSET_ARG//\"/\\\"}"
#             echo "Scanning ${SCAN_ASSET_TYPE} with ${SCAN_SCANNER_NAME}" | logger info
#             scanner "${SCAN_SCANNER_NAME}" asset "${SCAN_ASSET_ARG}"                        
#             # command: "scanner \(.scanner.header.name) asset [SINGLE_QUOTE]\(.asset | tojson)[SINGLE_QUOTE]"
#         else
#             echo "Invalid base64 input" >&2
#         fi
# 
#     }
#     asset(){
#         local ASSET="$1" && shift
#         local SCANNER="$1" && shift
#         local COMMAND="scanner ${SCANNER} asset ${ASSET}"
#         echo "${COMMAND}"
#     }
#     __nnf "$@" && return "$?"
# }