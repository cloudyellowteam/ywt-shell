# #!/usr/bin/env bash
# # shellcheck disable=SC2317,SC2120,SC2155,SC2044,SC2001
# # HRML - Http Request Markup Language
# # Parse HRML files into a request parameters in any language, and vice versa
# # references
# # - https://marketplace.visualstudio.com/items?itemName=humao.rest-client
# # - https://github.com/usebruno/bruno
# 
# ## example of HRML file
# # POST https://example.com/comments/1 {
# #   authorization {
# #       type: "Bearer",
# #       token
# #   }
# #   headers {
# #       Content-Type: "application/json",
# #       ...
# #   }
# #   cookie {
# #       name: session
# #       value: "1234567890"
# #       httpOnly: true
# #       path: "/"
# #   }
# #   body {
# #       key: "value"
# #   }
# # }
# 
# hrml() {
#     echo "Parse HRML files into a request parameters in any language, and vice versa" | logger info
#     # local HRML_FILE=$1 # && shift
#     # local HRML_TARGET="${HRML_FILE}"
#     # local LANG=${1:-"bash"} && shift
#     local VERBS=("GET" "POST" "PUT" "PATCH" "DELETE" "HEAD" "OPTIONS" "CONNECT" "TRACE")
#     # local HRML_CONTENT=$(cat "$HRML_FILE")
#     __print() {
#         echo -n "$1"
#     }
#     __inspect:dir() {
#         local TARGET="${1}" && shift
#         ((DIR_INDEX++))
#         # echo "Inspecting directory ($DIR_INDEX): $TARGET" | logger info
#         while read -r FILE; do
#             # __print "{"
#             # __print "\"dir\": \"$TARGET\","
#             # __print "\"seq\": $DIR_INDEX,"
#             # __print "\"files\": ["
#             __print "["
#             __inspect:file "$FILE"
#             __print "],"
#             # __print "},"
#         done < <(find "$TARGET" -type f -name "*.hrml") | sed -e 's/,$//' | jq -c .
#     }
#     __inspect:file() {
#         local TARGET="${1}" && shift
#         ((FILE_INDEX++))
#         local NAME=$(basename "$TARGET") && NAME=${NAME%.*}
#         # echo "Inspecting file ($FILE_INDEX): $NAME" | logger info
#         {
#             __print "{"
#             __print "\"scope\": \"$(dirname "$TARGET")\","
#             __print "\"file\": \"$TARGET\","
#             __print "\"name\": \"$NAME\","
#             __print "\"seq\": $FILE_INDEX,"
#             __print "\"requests\": ["
#             local LINE_NUM=0
#             local REQUEST_INDEX=0
#             while read -r LINE || [ -n "$LINE" ]; do
#                 LINE_NUM=$((LINE_NUM + 1))
#                 LINE=$(echo "$LINE" | sed -e 's/^\s*//' -e 's/\s*$//')
#                 if [[ " ${VERBS[*]} " =~ ${LINE%% *} ]]; then
#                     local METHOD=${LINE%% *}
#                     [ -z "$METHOD" ] && continue
#                     local URL=${LINE#* } && URL=${URL% *}
#                     [ -z "$URL" ] && continue
#                     REQUEST_INDEX=$((REQUEST_INDEX + 1))
#                     __print "{"
#                     __print "\"from\": ${LINE_NUM},"
#                     __print "\"method\": \"${METHOD}\","
#                     __print "\"url\": \"${URL}\","
#                     __print "\"seq\": ${REQUEST_INDEX},"
#                 else
#                     if [[ "$LINE" == "/}"* ]]; then
#                         __print "\"to\": ${LINE_NUM}"
#                         __print "},"
#                     else
#                         continue
#                     fi
# 
#                     # echo "Invalid HRML line: $LINE" | logger error
#                     # continue
#                 fi
#                 #|| {
#                 #    echo "Invalid HRML line: $LINE" | logger error
#                 # }
#             done <"$TARGET" | sed -e 's/,$//'
#             __print "]"
#             __print "}"
#         } | jq -c .
#     }
#     __inspect:lines() {
#         local FILE="${1}" && shift
#         local FROM="${1}" && shift
#         local TO="${1}" && shift
#         sed -n "${FROM},${TO}p" "$FILE"
#     }
#     __inspect::request() {
#         local FILE="${1}" && shift
#         local REQUEST="${1}" && shift
#         # echo "$REQUEST" | jq . | tee /dev/stderr | logger info && return 0
#         # local FILE=$(echo "$REQUEST" | jq -r '.file')
#         local METHOD=$(echo "$REQUEST" | jq -r '.method')
#         local URL=$(echo "$REQUEST" | jq -r '.url')
#         local FROM=$(echo "$REQUEST" | jq -r '.from')
#         local TO=$(echo "$REQUEST" | jq -r '.to')
#         local SEQ=$(echo "$REQUEST" | jq -r '.seq')
#         __inspect:block() {
#             local BLOCK="${1}" && shift
#             local CONTENT="${1}" && shift
#             {
#                 __print "{\"${BLOCK,,}\": ["
#                 case "$BLOCK" in
#                 cookies)
#                     {
#                         local COOKIE=""
#                         while read -r LINE || [ -n "$LINE" ]; do
#                             if [[ "$LINE" == "cookie"* ]]; then
#                                 COOKIE_NAME=$(echo "$LINE" | grep -oP 'cookie\s+\K\w+')
#                                 COOKIE="{\"name\": \"$COOKIE_NAME\","
#                             elif [[ "$LINE" == "}"* ]]; then
#                                 [ -z "$COOKIE" ] && continue
#                                 COOKIE=$(echo "$COOKIE" | sed -e 's/,$//')
#                                 COOKIE+="}"
#                                 __print "$COOKIE" | jq -c . #| tee /dev/stderr | logger info
#                                 __print ","
#                                 COOKIE=""
#                             else
#                                 [ -z "$COOKIE" ] && continue
#                                 local VALUE=$(echo "$LINE" | grep -oP 'value:\s*"\K[^"]+')
#                                 [ -n "$VALUE" ] && COOKIE+="\"value\": \"$VALUE\","
#                                 VALUE=$(echo "$LINE" | grep -oP 'domain:\s*"\K[^"]+')
#                                 [ -n "$VALUE" ] && COOKIE+="\"domain\": \"$VALUE\","
#                                 VALUE=$(echo "$LINE" | grep -oP 'expires:\s*"\K[^"]+')
#                                 [ -n "$VALUE" ] && COOKIE+="\"expires\": \"$VALUE\","
#                                 VALUE=$(echo "$LINE" | grep -oP 'maxAge:\s*\K[^,]+')
#                                 [ -n "$VALUE" ] && COOKIE+="\"maxAge\": $VALUE,"
#                                 VALUE=$(echo "$LINE" | grep -oP 'secure:\s*\K[^,]+')
#                                 [ -n "$VALUE" ] && COOKIE+="\"secure\": $VALUE,"
#                                 VALUE=$(echo "$LINE" | grep -oP 'sameSite:\s*"\K[^"]+')
#                                 [ -n "$VALUE" ] && COOKIE+="\"sameSite\": \"$VALUE\","
#                                 VALUE=$(echo "$LINE" | grep -oP 'httpOnly:\s*\K[^,]+')
#                                 [ -n "$VALUE" ] && COOKIE+="\"httpOnly\": $VALUE,"
#                                 VALUE=$(echo "$LINE" | grep -oP 'path:\s*"\K[^"]+')
#                                 [ -n "$VALUE" ] && COOKIE+="\"path\": \"$VALUE\","
#                             fi
#                         done < <(echo "$CONTENT") | sed -e 's/,$//'
#                     } | sed -e 's/,$//'
# 
#                     ;;
#                 *)
#                     __print "$CONTENT" |
#                         awk '/'"${BLOCK}"' {/,/}/{print}' |
#                         sed -e 's/'"${BLOCK}"' {//' \
#                             -e 's/}//' \
#                             -e 's/^\s*//' \
#                             -e 's/\s*$//' \
#                             -e 's/,\s*$//' |
#                         grep -v '^\s*$' |
#                         awk '{gsub(/["'\'']/, "", $2); print "{\"" substr($1, 1, length($1)-1) "\": \"" $2 "\"},"}' |
#                         sed -e '$s/,$//' \
#                             -e 's/""$/"/'
#                     ;;
#                 esac
#                 __print "]}"
#             } | jq -c .
#         }
#         echo "Request ($SEQ): $METHOD $URL ($FROM-$TO) ${FILE}" | logger info
#         local CONTENT=$(__inspect:lines "$FILE" "$FROM" "$TO")
#         # CONTENT=$(echo "$CONTENT" | sed -e 's/^\s*//' -e 's/\s*$//')
#         # CONTENT=$(echo "$CONTENT" | sed -e '1d' -e '$d')
#         # CONTENT="${CONTENT//\{/\{}"
#         # __inspect:block "headers" "$CONTENT"
#         # __inspect:block "cookies" "$CONTENT" && echo
#         # __inspect:block "authorization" "$CONTENT"
#         __inspect:block "body" "$CONTENT"
#         # __inspect:block "data" "$CONTENT"
#         # __inspect:block "files" "$CONTENT"
#         # __inspect:block "params" "$CONTENT"
#         # __inspect:block "options" "$CONTENT"
#         # local VALUE="$(__inspect:headers "$CONTENT")"
#         # echo "Headers: ${VALUE:-{}}" | logger info
# 
#         # local LINE_NUM=$FROM
#         # while read -r LINE; do
#         #     echo "[${LINE_NUM}] $LINE" #| logger info
#         #     # if start with headers is header block
#         #     if [[ "$LINE" == "headers"* ]]; then
#         #         local HEADERS=$(__inspect:lines "$FILE" "$LINE_NUM" "$TO")
#         #         echo "Headers: $HEADERS" #| logger info
#         #     fi
#         #     LINE_NUM=$((LINE_NUM + 1))
#         # done < <(sed -n "${FROM},${TO}p" "$FILE")
#     }
#     __inspect() {
#         local TARGET="${1}" && shift
#         local DIR_INDEX=0
#         local FILE_INDEX=0
#         if [ -d "$TARGET" ]; then
#             local JSON=$(__inspect:dir "$TARGET")
#         elif [ -f "$TARGET" ]; then
#             local JSON=$(__inspect:file "$TARGET")
#         else
#             echo "Invalid HRML file or directory: $TARGET" | logger error
#             return 1
#         fi
#         echo "$JSON" | jq . | tee /dev/stderr | logger info
#         while read -r FILE; do
#             while read -r REQUEST; do
#                 __inspect::request "$FILE" "$REQUEST"
#             done < <(cat <<<"$JSON" | jq -c '.[].requests[] | select(.method != null)')
#         done < <(cat <<<"$JSON" | jq -r '.[].file')
# 
#     }
#     __method() {
#         echo "$1" | grep -oP "^\s*\w+" | head -1
#     }
#     __inspect "$@" #| jq . | tee /dev/stderr | logger info
#     return 0
# 
#     hrml:v1() {
#         __json() {
#             local JSON=("{") && local HRML_CONTENT=$(cat "$HRML_FILE")
#             local LINE_NUM=0
#             while read -r LINE || [ -n "$LINE" ]; do
#                 LINE_NUM=$((LINE_NUM + 1))
#                 LINE=$(echo "$LINE" | sed -e 's/^\s*//' -e 's/\s*$//')
#                 [ -z "$LINE" ] && continue
#                 # if line start with http verb
#                 if [[ " ${VERBS[*]} " =~ ${LINE%% *} ]]; then
#                     local METHOD=${LINE%% *}
#                     local URL=${LINE#* } && URL=${URL% *}
#                     JSON+=("\"index\": ${LINE_NUM}")
#                     JSON+=("\"method\": \"${METHOD}\"")
#                     JSON+=("\"url\": \"${URL}\"")
#                     continue
#                 fi
#                 # echo "${LINE_NUM} ${LINE}" | logger info
#             done <"$HRML_FILE" # > /tmp/hrml.json
#             JSON+=("}")
#             # JOIN JSON ARRAY by comma
#             echo "$(
#                 IFS=,
#                 echo "${JSON[*]}"
#             )"
#         }
#         ___json() {
#             __print "{"
#             local HRML_VALUE=$(__method)
#             __print "\"method\": \"${HRML_VALUE:-"GET"}\","
#             HRML_VALUE=$(__url)
#             __print "\"url\": \"${HRML_VALUE:-""}\","
#             HRML_VALUE=$(__headers)
#             __print "\"headers\": {${HRML_VALUE:-""}},"
#             HRML_VALUE=$(__body)
#             __print "\"body\": {${HRML_VALUE:-""}},"
#             HRML_VALUE=$(__cookie)
#             __print "\"cookie\": {${HRML_VALUE:-""}},"
#             HRML_VALUE=$(__authz)
#             __print "\"authorization\": {${HRML_VALUE:-""}},"
#             HRML_VALUE=$(__data)
#             __print "\"data\": {${HRML_VALUE:-""}},"
#             HRML_VALUE=$(__files)
#             __print "\"files\": {${HRML_VALUE:-""}},"
#             HRML_VALUE=$(__params)
#             __print "\"params\": {${HRML_VALUE:-""}},"
#             HRML_VALUE=$(__options)
#             __print "\"options\": {${HRML_VALUE:-""}}"
#             __print "}"
#         }
#         __params() {
#             echo "$HRML_CONTENT" | grep -oP "params\s*{[^}]+}" | sed -e 's/params\s*{//' -e 's/}//' -e 's/^\s*//' -e 's/\s*:\s*/: /g' -e 's/,\s*$//'
#         }
#         __files() {
#             echo "$HRML_CONTENT" | grep -oP "files\s*{[^}]+}" | sed -e 's/files\s*{//' -e 's/}//' -e 's/^\s*//' -e 's/\s*:\s*/: /g' -e 's/,\s*$//'
#         }
#         __options() {
#             echo "$HRML_CONTENT" | grep -oP "options\s*{[^}]+}" | sed -e 's/options\s*{//' -e 's/}//' -e 's/^\s*//' -e 's/\s*:\s*/: /g' -e 's/,\s*$//'
#         }
#         __data() {
#             echo "$HRML_CONTENT" | grep -oP "data\s*{[^}]+}" | sed -e 's/data\s*{//' -e 's/}//' -e 's/^\s*//' -e 's/\s*:\s*/: /g' -e 's/,\s*$//'
#         }
#         __authz() {
#             echo "$HRML_CONTENT" | grep -oP "authorization\s*{[^}]+}" | sed -e 's/authorization\s*{//' -e 's/}//' -e 's/^\s*//' -e 's/\s*:\s*/: /g' -e 's/,\s*$//'
#         }
#         __cookie() {
#             echo "$HRML_CONTENT" | grep -oP "cookie\s*{[^}]+}" | sed -e 's/cookie\s*{//' -e 's/}//' -e 's/^\s*//' -e 's/\s*:\s*/: /g' -e 's/,\s*$//'
#         }
#         __body() {
#             echo "$HRML_CONTENT" | grep -oP "body\s*{[^}]+}" | sed -e 's/body\s*{//' -e 's/}//' -e 's/^\s*//' -e 's/\s*:\s*/: /g' -e 's/,\s*$//'
#         }
#         __headers() {
#             echo "$HRML_CONTENT" | grep -oP "headers\s*{[^}]+}" | sed -e 's/headers\s*{//' -e 's/}//' -e 's/^\s*//' -e 's/\s*:\s*/: /g' -e 's/,\s*$//'
#         }
#         __url() {
#             echo "$HRML_CONTENT" | grep -oP "https?://\S+"
#         }
#         __method() {
#             echo "$HRML_CONTENT" | grep -oP "^\s*\w+" | head -1
#         }
#     }
# }
# (
#     export -f hrml
# )
