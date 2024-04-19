#!/usr/bin/env bash
# # shellcheck disable=SC2317,SC2155
# timezones() {
#     current() {
#         date +"%Z"
#     }
#     list() {
#         [ -d /usr/share/zoneinfo/ ] && find /usr/share/zoneinfo/ -type f -printf '%P\n' | sed 's/\.\///' | sort && return 0
#         __is command timedatectl && timedatectl | grep "Time zone" | awk '{print $3}' && return 0
#         return 1
#     }
#     __nnf "$@" || usage "dates" "$?" "$@" && return 1
# }
# (
#     export -f timezones
# )
