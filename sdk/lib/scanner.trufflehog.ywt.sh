#!/usr/bin/env bash
# shellcheck disable=SC2317,SC2120,SC2155,SC2044

__scanner:trufflehog(){
    local DEFAULT_ARGS=(
        "--json"
    )
    trufflehog:cli(){
        __scanner:cli "trufflehog" "${DEFAULT_ARGS[@]}" "$@"
    }
    trufflehog:version(){
        trufflehog:cli --version
        return 0
    }
    trufflehog:metadata(){
        {
            echo -n "{"
            echo -n "\"uuid\":\"cbb46398-a79e-4afe-9672-badabf6075e7\","
            echo -n "\"capabilities\":[\"filesystem\",\"repository\",\"docker:image\", \"bucket\"],"
            echo -n "\"features\":[\"secrets\"],"
            echo -n "\"engines\":[\"host\",\"docker\"],"
            echo -n "\"formats\":[\"json\",\"text\"]"
            echo -n "}"
        } | jq -c .
        return 0
    }
    trufflehog:activate(){
        echo "{}"
        return 0
    }
    local ACTION="$1" && shift
    __nnf "trufflehog:$ACTION" "$@"
}






# __scanner:trufflehog:v1() {
#     # local RESULT_FILE="$(mktemp -u -t XXXXXX --suffix=.trufflehog -p /tmp)"
#     local SCANNER="$({
#         echo -n "{"
#         echo -n "\"scanner\":\"trufflehog\","
#         echo -n "\"type\":[\"code\", \"secrets\"],"
#         echo -n "\"format\":\"json\","
#         echo -n "\"output\":\"$RESULT_FILE\","
#         echo -n "\"start\":\"$(date +%s)\","
#         echo -n "\"engines\":["
#         echo -n "\"host\","
#         echo -n "\"docker\""
#         echo -n "]"
#     })"
#     local DEFAULT_ARGS=(
#         "--json"
#     )
#     if __is command trufflehog; then
#         local VERSION=$(trufflehog --version)
#         SCANNER+="$({
#             echo -n ",\"engine\":\"host\""
#             echo -n ",\"version\":\"$VERSION\""
#         })"
#         trufflehog "${DEFAULT_ARGS[@]}" "$@" >"$RESULT_FILE"
#     elif __is command docker; then
#         local VERSION=$(docker run "${DOCKER_ARGS[@]}" trufflehog --version 2>&1)
#         SCANNER+="$({
#             echo -n ",\"engine\":\"docker\""
#             echo -n ",\"container\":\"${CONTAINER_NAME}\""
#             echo -n ",\"version\":\"trufflehog@$VERSION\""
#         })"
#         docker run "${DOCKER_ARGS[@]}" trufflehog "${DEFAULT_ARGS[@]}" "$@" &> "$RESULT_FILE"
#     else
#         SCANNER+=",\"error\":\"trufflehog not found\""
#     fi
#     if jq . "$RESULT_FILE" >/dev/null 2>&1; then
#         SCANNER+=",\"result\":$(jq -cs . "$RESULT_FILE")"
#         local IS_JSON=true
#     else
#         local CONTENT=$(cat "$RESULT_FILE")
#         local IS_JSON=false
#         CONTENT=$(
#             {
#                 echo "$CONTENT"
#             } | sed 's/"/\\"/g' |
#                 awk '{ printf "%s\\n", $0 }' |
#                 awk '{ gsub("\t", "\\t", $0); print $0 }' |
#                 sed 's/^/  /'
#         )
#         SCANNER+=",\"text\":\"string\""
#     fi
#     echo "${SCANNER}, \"end\":\"$(date +%s)\"}" | jq -c .
#     [ "$IS_JSON" = false ] && cat "$RESULT_FILE"
# }
