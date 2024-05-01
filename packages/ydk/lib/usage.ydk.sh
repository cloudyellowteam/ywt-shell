#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:usage() {
    local YDK_USAGE_STATUS=$?
    [[ $1 =~ ^[0-9]+$ ]] && local YDK_USAGE_STATUS="${1}" && shift
    local YDK_USAGE_MESSAGE="${1:-"command not found"}" && shift
    local YDK_USAGE_COMMAND_ARGS=("$@")
    local YDK_ERROR_MESSAGE="${YDK_ERRORS_MESSAGES[$YDK_USAGE_STATUS]:-"An error occurred"}"
    {
        echo -n "{"
        echo -n "\"error\": true,"
        echo -n "\"status\": $YDK_USAGE_STATUS,"
        echo -n "\"message\": \"${YDK_ERROR_MESSAGE}. ${YDK_USAGE_MESSAGE}\","
        echo -n "\"command\": \"$1\","
        echo -n "\"args\": ["
        for YDK_USAGE_COMMAND_ARG in "${YDK_USAGE_COMMAND_ARGS[@]}"; do
            echo -n "\"${YDK_USAGE_COMMAND_ARG}\","
        done | sed -e 's/,$//'
        echo -n "],"
        echo -n "\"available\": "
        ydk:functions 4>&1 >&1
        echo -n "}"
        echo
    } >&4
    # local YDK_USAGE_COMMAND="${1:-"<command>"}" && shift
    # local YDK_USAGE_MESSAGE="${1:-"command not found"}" && shift
    # local YDK_USAGE_COMMANDS=("$@")
    # {
    #     echo "($YDK_USAGE_STATUS) ${YDK_USAGE_MESSAGE}"
    #     echo "* Usage: ydk $YDK_USAGE_COMMAND"
    #     [ "${#YDK_USAGE_COMMANDS[@]}" -gt 0 ] && {
    #         echo " [commands]"
    #         for YDK_USAGE_COMMAND in "${YDK_USAGE_COMMANDS[@]}"; do
    #             echo " ${YDK_USAGE_COMMAND}"
    #         done
    #     }
    # } >&1
    # ydk:throw "$YDK_USAGE_STATUS" "ERR" "Usage: ydk $YDK_USAGE_COMMAND"
    return "$YDK_USAGE_STATUS"
}
