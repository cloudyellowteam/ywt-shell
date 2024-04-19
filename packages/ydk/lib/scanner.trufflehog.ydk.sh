#!/usr/bin/env bash
# # shellcheck disable=SC2317,SC2120,SC2155,SC2044
# 
# __scanner:trufflehog() {
#     local DEFAULT_ARGS=(
#         "--json"
#     )
#     trufflehog:install() {
#         {
#             curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b /usr/local/bin
#         } >/dev/null 2>&1
# 
#     }
#     trufflehog:uninstall() {
#         rm -f /usr/local/bin/trufflehog >/dev/null 2>&1
#     }
#     trufflehog:cli() {
#         __scanner:cli "trufflehog" "${DEFAULT_ARGS[@]}" "$@"
#     }
#     trufflehog:version() {
#         trufflehog:cli --version
#         return 0
#     }
#     trufflehog:metadata() {
#         {
#             echo -n "{"
#             echo -n "\"uuid\":\"cbb46398-a79e-4afe-9672-badabf6075e7\","
#             echo -n "\"capabilities\":[\"filesystem\",\"repository\",\"docker:image\", \"bucket\"],"
#             echo -n "\"features\":[\"secrets\"],"
#             echo -n "\"engines\":[\"host\",\"docker\"],"
#             echo -n "\"formats\":[\"json\",\"text\"],"
#             echo -n "\"priority\":1,"
#             echo -n "\"tool\":{"
#             echo -n "\"driver\":{"
#             echo -n "\"name\":\"trufflehog\","
#             echo -n "\"informationUri\":\"https://github.com/trufflesecurity/trufflehog\","
#             echo -n "\"version\":\"3.71.2\""
#             echo -n "} }"
#             echo -n "}"
#         } | jq -c .
#         return 0
#     }
#     trufflehog:activate() {
#         echo "{}"
#         return 0
#     }
#     trufflehog:result() {
#         echo -n "["
#         {
#             while read -r LINE; do
#                 echo -n "$LINE"
#                 echo -n ","
#             done <"$1"
#         } | sed 's/,$//'
#         echo -n "]"
#     }
#     trufflehog:summary() {
#         echo -n "{}"
#     }
#     trufflehog:sarif() {
#         local trufflehog_report="$1"
#         local sarif_output="$2"
# 
#         jq -n --argfile findings "$trufflehog_report" '{
#             "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
#             "version": "2.1.0",
#             "runs": [
#                 {
#                     "tool": {
#                         "driver": {
#                             "name": "TruffleHog",
#                             "informationUri": "https://github.com/trufflesecurity/truffleHog"
#                         }
#                     },
#                     "results": ($findings | map({
#                         "ruleId": "secret-detected",
#                         "level": "warning",
#                         "message": {
#                             "text": "Potential secret or sensitive information detected."
#                         },
#                         "locations": [
#                             {
#                                 "physicalLocation": {
#                                     "artifactLocation": {
#                                         "uri": .path,
#                                         "uriBaseId": "%SRCROOT%"
#                                     },
#                                     "region": {
#                                         "startLine": .line_number
#                                     }
#                                 }
#                             }
#                         ]
#                     }))
#                 }
#             ]
#         }' >"$sarif_output"
#     }
#     trufflehog:asset() {
#         local ASSET="${1//\\\"/\"}" && shift
#         if ! __is json "$ASSET"; then
#             echo "{\"error\":\"Invalid asset\"}"
#             return 1
#         fi
#         case "$(jq -r '.type' <<<"$ASSET")" in
#         docker:image)
#             local DOCKER_IMAGE="$(jq -r '.target' <<<"$ASSET")"
#             if [ -z "$DOCKER_IMAGE" ]; then
#                 echo "{\"error\":\"Invalid image\"}"
#                 return 1
#             fi
#             trufflehog:cli docker --image="$DOCKER_IMAGE"
#             return 0
#             ;;
#         repository)
#             local REPOSITORY_URL="$(jq -r '.target' <<<"$ASSET")"
#             if [ -z "$REPOSITORY_URL" ]; then
#                 echo "{\"error\":\"Invalid repository URL\"}"
#                 return 1
#             fi
#             trufflehog:cli git "$REPOSITORY_URL"
#             return 0
#             ;;
#         filesystem)
#             local ASSET_PATH="$(jq -r '.target' <<<"$ASSET")"
#             if [ ! -d "$ASSET_PATH" ]; then
#                 echo "{\"error\":\"Invalid asset path\"}"
#                 return 1
#             fi
#             trufflehog:cli filesystem "/ywt-workdir$ASSET_PATH"
#             return 0
#             ;;
#         *)
#             echo "{\"error\":\"Invalid asset type\"}"
#             return 1
#             ;;
#         esac
#     }
#     local ACTION="$1" && shift
#     __nnf "trufflehog:$ACTION" "$@"
#     return $?
# }
