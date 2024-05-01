#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:store() {
    ydk:try "$@" 4>&1
    return $?
}

# store() {
#     __key() {
#         [ -z "$1" ] && echo "" && return 1
#         local KEY="${1// /_}" && KEY="${KEY//[^a-zA-Z0-9_]/_}"
#         while [[ "$KEY" == _* ]]; do KEY="${KEY#_}"; done
#         echo "${KEY^^}"
#     }
#     local ACTION="$1" && shift && [ -z "$ACTION" ] && ACTION="get"
#     local KEY="$(__key "$1")" && shift && [ -z "$KEY" ] && logger error "store: key is required" && return 1    
#     local VALUE="$1" && shift && [ -z "$VALUE" ] && VALUE="$(cat)" && [ -z "$VALUE" ] && logger error "store: value is required" && return 1
#     local FILE="$1" && [ -z "$FILE" ] && FILE="$YWT_PATH_CACHE/.store"
#     [ ! -f "$FILE" ] && touch "$FILE"
#     # [ ! -r "$FILE" ] || [ ! -w "$FILE" ] || [ ! -x "$FILE" ] && {
#     #     logger error "store: cannot read, write, or execute $FILE"
#     # } && return 1
#     case "$ACTION" in
#     s | set)
#         if ! grep -q "^$KEY=" "$FILE"; then
#             echo "$KEY=$VALUE" >>"$FILE" && return 0
#         else
#             sed -i "s/^$KEY=.*/$KEY=$VALUE/" "$FILE" && return 0          
#         fi
#         ;;
#     g | get)
#         if grep -q "^$KEY=" "$FILE"; then
#             VALUE=$(grep "^$KEY=" "$FILE" | cut -d'=' -f2)
#             echo "$VALUE" && return 0
#         fi
#         ;;
#     d | del | delete)
#         if grep -q "^$KEY=" "$FILE"; then
#             sed -i "/^$KEY=.*/d" "$FILE" && return 0
#         fi
#         ;;
#     c | clear)
#         rm -f "$FILE" && return 0
#         ;;
#     i | inspect)
#         while IFS= read -r LINE; do
#             IFS="=" read -r KEY VALUE <<<"$LINE" &&
#             echo -n "$KEY=" && strings mask "$VALUE" && echo
#         done <"$FILE" && return 0
#         ;;
#     *) usage "store" "Invalid action: $ACTION" "$@" && return 1 ;;
#     esac
#     return 1
# }
# (
#     export -f store
# )
