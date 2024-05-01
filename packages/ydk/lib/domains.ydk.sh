#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:domains() {
    ydk:try "$@" 4>&1
    return $?
}
# domains() {
#     hsts(){
#         local DOMAIN="${1}"
#         local HSTS_HEADER=$(curl -s -I "https://${DOMAIN}" | grep -i "Strict-Transport-Security")
#         if [ -z "${HSTS_HEADER}" ]; then
#             echo "HSTS not enabled for ${DOMAIN}" | logger warn
#             return 1
#         else
#             echo "HSTS enabled for ${DOMAIN}" | logger success
#             return 0
#         fi
#     }
#     __nnf "$@" || usage "tests" "$?" "$@" && return 1
# }
# (
#     export -f domains
# )