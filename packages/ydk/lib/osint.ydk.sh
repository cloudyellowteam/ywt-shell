#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:osint() {
    ydk:try "$@" 4>&1
    return $?
}

# osint() {
#     employers() {
#         echo "employers"
#     }
#     employees() {
#         echo "employees"
#     }
#     companies() {
#         echo "companies"
#     }
#     domains() {
#         echo "domains"
#     }
#     emails() {
#         echo "emails"
#     }
# }
# (
#     export -f osint
# )