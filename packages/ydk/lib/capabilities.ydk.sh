#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:capabilities() {
    ydk:try "$@" 4>&1
    return $?
}
#!/usr/bin/env bash
# # shellcheck disable=SC2317,SC2120,SC2155,SC2044
# capabilities() {
#     __capability() {
#         local CAPABILITY="$1" && shift
#         case "$CAPABILITY" in
#         inter)
#             local VALUE="false"
#             [ -t 0 ] && local VALUE="true"
#             ;;
#         net-admin)
#             local VALUE="false"
#             [ "$(id -u)" -eq 0 ] && local VALUE="true"
#             ;;
#         sudo)
#             local VALUE="false"
#             [ -x "$(command -v sudo)" ] && local VALUE="true"
#             ;;
#         mount)
#             local VALUE="false"
#             [ -d /mnt ] && local VALUE="true"
#             ;;
#         docker)
#             local VALUE="false"
#             [ -x "$(command -v docker)" ] && local VALUE="true"
#             ;;
#         sys-admin)
#             local VALUE="false"
#             [ "$(id -u)" -eq 0 ] && local VALUE="true"
#             ;;
#         *)
#             local VALUE="\"unexpected\""
#             ;;
#         esac
#         echo -n "\"$CAPABILITY\": $VALUE"
#     }
#     {
#         [ "$#" -eq 0 ] && set -- "sys-admin" "docker" "mount" "sudo" "net-admin" "inter"
#         echo -n "{"
#         echo -n "\"capabilities\": {"
#         while [ "$#" -gt 0 ]; do
#             __capability "$1"
#             shift
#             [ "$#" -gt 0 ] && echo -n ","
#         done
#         echo -n "}"
#         echo -n "}"
#     } | jq .
#     return 0
#     # __nnf "$@" || usage "tests" "$?" "$@" && return 1
# }
