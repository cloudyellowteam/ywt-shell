#!/usr/bin/env bash
# # shellcheck disable=SC2044,SC2155,SC2317
# user() {
#     info() {
#         local USER=$(whoami)
#         local GROUP=$(id -gn)
#         local USERID=$(id -u)
#         local GROUPID=$(id -g)
#         local HOME=~
#         local SHELL="$SHELL"
#         local SUDO=$(sudo -nv 2>&1 | grep "may run sudo" || true) && SUDO=${SUDO:-false}
#         echo "{
#             \"user\": \"$USER\",
#             \"group\": \"$GROUP\",
#             \"uid\": \"$USERID\",
#             \"gid\": \"$GROUPID\",
#             \"home\": \"$HOME\",
#             \"shell\": \"$SHELL\",
#             \"sudo\": \"$SUDO\"
#         }"
#     }
#     runAsRoot() {
#         local CMD="$*"
#         if [ "$EUID" -ne 0 ] && [ "$YWT_CONFIG_USE_SUDO" = "true" ]; then
#             CMD="sudo $CMD"
#         fi
#         $CMD
#     }
#     __nnf "$@" || usage "user" "$?" "$@" && return 1
# }
# (
#     export -f user
# )
