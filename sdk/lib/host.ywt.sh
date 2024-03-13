#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
host() {
    info() {
        local HOSTNAME=$(hostname)
        local OS=$(uname -s)
        local KERNEL=$(uname -r)
        local ARCH=$(uname -m)
        local CPU=$(lscpu | grep "Model name" | cut -d: -f2 | xargs)
        local MEM=$(free -h | awk '/^Mem:/ {print $2}')
        local DISK=$(df -h / | awk '/\// {print $2}')
        echo "{
            \"hostname\": \"$HOSTNAME\",
            \"os\": \"$OS\",
            \"kernel\": \"$KERNEL\",
            \"arch\": \"$ARCH\",
            \"cpu\": \"$CPU\",
            \"mem\": \"$MEM\",
            \"disk\": \"$DISK\"
        }"
    }
    _nnf "$@" || usage "$?" "$@" && return 1
}
