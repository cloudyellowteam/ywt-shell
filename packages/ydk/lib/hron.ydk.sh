#!/usr/bin/env bash
# # shellcheck disable=SC2317,SC2120,SC2155,SC2044
# # HRON HTTP Request Object Notation
# # JSON files for HTTP requests to any language, and vice versa
# # references
# # - https://marketplace.visualstudio.com/items?itemName=humao.rest-client
# # - https://github.com/usebruno/bruno
# 
# hron() {
#     YWT_LOGGER_CONTEXT="hron"
#     echo "Parsing HRON..." | logger info
#     local VERBS=("GET" "POST" "PUT" "PATCH" "DELETE" "HEAD" "OPTIONS" "CONNECT" "TRACE")
#     local DIR_INDEX=0
#     local FILE_INDEX=0
#     local LINE_INDEX=0
#     __print() {
#         echo -n "$1"
#     }
#     __inspect:file() {
#         local TARGET="${1}" && shift
#         ((FILE_INDEX++))
#         jq '.[]' "$TARGET"
#     }
#     __inspect:dir() {
#         local TARGET="${1}" && shift
#         ((DIR_INDEX++))
#         # echo "Inspecting directory ($DIR_INDEX): $TARGET" | logger info
#         while read -r FILE; do
#             __inspect:file "$FILE"
#         done < <(find "$TARGET" -type f -name "*.hron") # | sed -e 's/,$//' | jq -c .
#     }
#     __inspect:service:v1() {
#         local TARGET="${1}" && shift
#         local SERVICE_NAME=$(basename "$(dirname "$TARGET")")
#         ((FILE_INDEX++))
#         jq '
#             .[]
#             | .endpoint as $endpoint
#             | .service = (
#                 if .service then .service else "'"$SERVICE_NAME"'" end
#             )
#             | .headers = (
#                 if .headers then .headers else {} end
#             )
#             | .cookies = (
#                 if .cookies then .cookies else {} end
#             )
#             | .query = (
#                 if .query then .query else {} end
#             )
#             | .routes = (
#                 if .routes then .routes else [] end
#             )
#             | .service as $service
#             | .query as $query
#             | .headers as $headers
#             | .cookies as $cookies
#             | .routes as $routes            
#             | {
#                 routes: (
#                     $routes
#                     | map(
#                         to_entries
#                         | map(
#                             .key as $key
#                             | .value as $value
#                             | .method = ($key | split(" ")[0])
#                             | .path = ($key | split(" ")[1])
#                             | .id = (
#                                 $value.id
#                                 | if . then . else "" end
#                                 | sub("^-"; "")
#                                 | sub("-$"; "") 
#                                 | gsub("[^a-zA-Z0-9]"; "-")
#                                 | gsub("-+" ; "-")
#                             )
#                             | .query = (
#                                 $query
#                                 | to_entries
#                                 | map("\(.key)=\(.value)")
#                                 | join("&")
#                             )
#                             | .query = (
#                                 $value.query
#                                 | if . then to_entries
#                                 | map("\(.key)=\(.value)")
#                                 | join("&") else "" end
#                             )    
#                             | .query = (
#                                 if .query then "?" + .query else "" end
#                             )  
#                             | .headers = (
#                                 $value.headers
#                                 | if . then $headers + . else $headers end
#                             )
#                             | .cookies = (
#                                 $value.cookies
#                                 | if . then $cookies + . else $cookies end
#                             )
#                             | .cookies = (
#                                 .cookies
#                                 | to_entries                                
#                                 | map(
#                                     .value = (
#                                         .value
#                                         | if . then . else {} end
#                                     )
#                                     | .raw = (
#                                         .value.value
#                                         | if . then . + ";" else ";" end
#                                     )
#                                     | ."max-age" = (
#                                         .value."max-age"
#                                         | if . then "Max-Age=" + (. | tostring) + "; " else "" end
#                                     )
#                                     | .domain = (
#                                         .value.domain
#                                         | if . then "Domain=" + . + "; " else "" end
#                                     )
#                                     | .path = (
#                                         .value.path
#                                         | if . then "Path=" + . + "; " else "" end
#                                     )
#                                     | .secure = (
#                                         .value.secure
#                                         | if . then "Secure; " else "" end
#                                     )
#                                     | .httpOnly = (
#                                         .value.httpOnly
#                                         | if . then "HttpOnly; " else "" end
#                                     )
#                                     | .sameSite = (
#                                         .value.sameSite
#                                         | if . then "SameSite=" + . + "; " else "" end
#                                     )
#                                     | .expires = (
#                                         .value.expires
#                                         | if . then "Expires=" + . + "; " else "" end
#                                     )
#                                     | "Set-Cookie: " + (
#                                         .key + "=" + .raw + ."max-age" + .domain + .path + .secure + .httpOnly + .sameSite + .expires
#                                     )
#                                 )
#                             )
#                             | .url = $endpoint + "\(.path)\(.query)"                       
#                             | {
#                                 id: "\($service).\(.id)",
#                                 defaults: {
#                                     query: $query,
#                                     headers: $headers,
#                                     cookies: $cookies
#                                 },
#                                 service: $service,
#                                 endpoint: $endpoint,                                
#                                 query: .query,
#                                 headers: .headers,
#                                 cookies: .cookies,
#                                 key: $key,
#                                 method: .method,
#                                 path: .path,
#                                 url: .url,
#                                 query: .query,
#                                 headers: .headers,
#                                 cookies: .cookies
#                             }                  
#                         )
#                     )
#                 )
#             }
#             
#         ' "$TARGET"
#     }
#     __inspect:service() {
#         local TARGET="${1}" && shift
#         local SERVICE_NAME=$(basename "$(dirname "$TARGET")")
#         ((FILE_INDEX++))
#         jq '
#             .[]
#             | .endpoint as $endpoint
#             | .index = (
#                 '"$FILE_INDEX"'
#             )
#             | .index as $index
#             | .service = (
#                 if .service then .service else "'"$SERVICE_NAME"'" end
#             )
#             | .service as $service
#             | .id = (
#                 if .id then .id else .service end
#                 | sub("^-"; "")
#                 | sub("-$"; "") 
#                 | gsub("[^a-zA-Z0-9]"; "-")
#                 | gsub("-+" ; "-")
#             )
#             | .id as $id
#             | .headers = (
#                 if .headers then .headers else {} end
#             )
#             | .headers as $headers
#             | .cookies = (
#                 if .cookies then .cookies else {} end
#             )
#             | .cookies as $cookies
#             | .query = (
#                 if .query then .query else {} end
#             )
#             | .query as $query
#             | {
#                 index: $index,
#                 id: $id,
#                 service: $service,
#                 endpoint: $endpoint,                
#                 query: $query,
#                 headers: $headers,
#                 cookies: $cookies                
#             }
#         ' "$TARGET"
#     }
#     __inspect:routes(){
#         local SVC_SCHEMA="${1}" && shift
#         local ROUTES="${1}" && shift
#         if [ -f "$ROUTES" ]; then
#             local SVC_ROUTES=$(jq -r '.[]' "$ROUTES")
#         elif [ -d "$ROUTES" ]; then
#             local SVC_ROUTES=$(
#                 find "$ROUTES" -type f \
#                     -name "*.hron" \
#                     -not -name "index.hron" \
#                     -exec jq -r '
#                         . 
#                         | .schema = (
#                             '"$SVC_SCHEMA"'
#                         )
#                         | .file = (
#                             input_filename
#                             | sub(".*/"; "")
#                             | sub("\\.hron$"; "")
#                         )
#                         | .file as $file
#                         | .dir = (
#                             input_filename
#                             | sub("/[^/]+$"; "")
#                             | sub(".*/"; "")
#                         )
#                         | .dir as $dir                        
#                         | .
#                         
#                     ' {} \;
#             )
#         elif jq -e . >/dev/null 2>&1 <<<"$ROUTES"; then
#             local SVC_ROUTES=$(jq -r '.[]' <<<"$ROUTES")
#         else
#             __debug "Invalid routes: $ROUTES"
#             echo "[]" && return 1
#         fi
#         # SVC_SCHEMA=$(jq -n --argjson schema "$SVC_SCHEMA" --argjson routes "$SVC_ROUTES" '$schema + $routes')
#         echo "$SVC_ROUTES"
#     }
#     __inspect() {
#         local TARGET="${1}" && shift
#         [[ ! -d "$TARGET" ]] && echo "Invalid directory: $TARGET" && return 1
#         while read -r SVC_DIR; do
#             local SVC_INDEX="$SVC_DIR/index.hron"
#             [[ ! -f "$SVC_INDEX" ]] && continue
#             local SVC_SCHEMA="$(__inspect:service "$SVC_INDEX")"
#             # __inspect:routes "$SVC_SCHEMA" "$SVC_DIR"
#             echo "$SVC_SCHEMA" | jq .
#         done < <(find "$TARGET" -type d)
# 
#         # if [[ -d "$TARGET" ]]; then
#         #     __inspect:dir "$TARGET"
#         # elif [[ -f "$TARGET" ]]; then
#         #     __inspect:file "$TARGET"
#         # fi
#     }
#     __inspect "$1" #| jq .
# 
# }
# (
#     export -f hron
# )
