#!/usr/bin/env bash
# shellcheck disable=SC2317,SC2120,SC2155,SC2044
scanner() {
    local RESULT_FILE="$(mktemp -u -t ywt-XXXXXX --suffix=".$1" -p /tmp)"
    local CONTAINER_NAME="$(basename "$RESULT_FILE")" && CONTAINER_NAME="${CONTAINER_NAME//./-}"
    local DOCKER_ARGS=(
        "--rm"
        "--name" "${CONTAINER_NAME}"
        "-v" "$(pwd):/ywt-target"
        "ywt-sca:latest"
    )
    case "$1" in
    cloc)
        shift
        __scanner:cloc "$@"
        ;;
    trivy)
        shift
        __scanner:trivy "$@"
        ;;
    trufflehog)
        shift
        __scanner:trufflehog "$@"
        ;;
    *)
        __nnf "$@" || usage "tests" "$?" "$@" && return 1
        ;;
    esac
}
(
    export -f scanner
)
