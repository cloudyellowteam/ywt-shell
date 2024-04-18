#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:nnf() {
    local IOC_TARGET=${1} && shift && [ -z "$IOC_TARGET" ] && return 1
    IOC_TARGET=${IOC_TARGET#_} && IOC_TARGET=${IOC_TARGET#__} && IOC_TARGET="${IOC_TARGET//_/-5f}" && IOC_TARGET="${IOC_TARGET//-/-2d}" && IOC_TARGET="${IOC_TARGET// /_}"
    local IOC_ARGS=("$@")
    local START_TIME=$(date +%s)
    # echo "ydk:nnf: $IOC_TARGET / ${IOC_ARGS[*]}"
    ydk:is function "ydk:$IOC_TARGET" && IOC_TARGET="ydk:$IOC_TARGET"
    ! ydk:is function "$IOC_TARGET" && return 1
    exec 3>&1
    trap 'exec 3>&-' EXIT
    local IOC_STATUS
    # echo "{\"target\":\"$IOC_TARGET\",\"args\":[\"${IOC_ARGS[*]}\"]}"
    $IOC_TARGET "${IOC_ARGS[@]}" 1>&3 2>&3 ||
    IOC_STATUS=$? && IOC_STATUS=${IOC_STATUS:-0}    
    # set -- "${IOC_ARGS[@]}"
    local END_TIME=$(date +%s)
    local ELAPSED_TIME=$((END_TIME - START_TIME))
    if [ -n "$IOC_STATUS" ] && [ "$IOC_STATUS" -eq 0 ]; then
        local IOC_RESULT="SUCCESS"
    else
        local IOC_RESULT="FAILED"
    fi
    exec 3>&-
    # echo -n "{"
    # echo -n "\"target\": \"$IOC_TARGET\","
    # echo -n "\"args\": [\"${IOC_ARGS[*]}\"],"
    # echo -n "\"status\": $IOC_STATUS,"
    # echo -n "\"result\": \"$IOC_RESULT\","
    # echo -n "\"time\": $ELAPSED_TIME"
    # echo -n "}"
    # echo
    return "${IOC_STATUS}"
}
