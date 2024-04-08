#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:errors() {
    ydk:try:nnf "$@"
    return $?
}
(
    [[ -z "$YDK_ERRORS_MESSAGES" ]] && declare -a YDK_ERRORS_MESSAGES=(
        [255]="An error occurred"
        [254]="Failed to install ydk"
        [253]="Failed to install libraries"
        [252]="Failed to download"
    ) && export YDK_ERRORS_MESSAGES
)
