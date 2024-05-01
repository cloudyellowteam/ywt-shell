#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:checksum() {
    hash(){
        local HASH=${1:-"sha256"}
        local FILE=${2} && [ ! -f "$FILE" ] && echo "File not found: $FILE" && return 1
        local HASH_CMD=""
        case "${HASH}" in
        "sha256")
            HASH_CMD="sha256sum"
            ;;
        "sha512")
            HASH_CMD="sha512sum"
            ;;
        "md5")
            HASH_CMD="md5sum"
            ;;
        "sha1")
            HASH_CMD="sha1sum"
            ;;
        *)
            echo "Unknown hash algorithm: ${HASH}"
            return 1
            ;;
        esac
        ${HASH_CMD} "${FILE}" | awk '{print $1}' >&4
        return $?
    }
    generate() {
        local FILE=${1} && [ ! -f "$FILE" ] && echo "File not found: $FILE" && return 1
        local HASH=${2:-"sha256"}
        hash "${HASH}" "${FILE}" 4>&1 >&4
    }
    verify(){
        local FILE=${1} && [ ! -f "$FILE" ] && echo "File not found: $FILE" && return 1
        local HASH=${2} && [ -z "$HASH" ] && echo "Hash not found" && return 1
        local HASH_TYPE=${3:-"sha256"}
        local FILE_HASH=$(hash "${HASH_TYPE}" "${FILE}" 4>&1)
        [ "$FILE_HASH" == "$HASH" ] && return 0
        ydk:log warn "Hash mismatch: $FILE_HASH != $HASH"
        return 1        
    }
    ydk:try "$@" 4>&1
    return $?
}
