#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
builder() {
    local CURRENT_DIR && CURRENT_DIR=$(dirname -- "$0")
    local ROOT_DIR && ROOT_DIR=$(dirname -- "$CURRENT_DIR") && ROOT_DIR=$(realpath -- "$ROOT_DIR")
    local CONFIG_EXPIRES_AT="31/12/2999"
    local DIST="${ROOT_DIR}/dist"
    local BIN="${ROOT_DIR}/bin"
    logger info "Building files from $ROOT_DIR"
    _prepare() {
        [[ ! -d "$DIST" ]] && mkdir -p "${DIST}"
        rm -fR "${DIST:?}"/*
        [[ ! -d "$BIN" ]] && mkdir -p "${BIN}"
        if ! command -v shc &>/dev/null; then
            colorize "red" "compiler is not installed, trying install" | logger warn
            apt-get install shc -y || return 1
        fi
        local SHC_INSTALLED && SHC_INSTALLED=$(command -v shc)
        [[ -z "$SHC_INSTALLED" ]] && colorize "red" "compiler is not installed" | logger error && return 1
        colorize "green" "compiler is installed" | logger success
    }
    _cleanup() {
        local KEEP_SOURCE="${YWT_CONFIG_BUILDER_KEEP_SOURCE:-false}"
        [[ "$KEEP_SOURCE" == true ]] && echo "Keeping sources" | logger info && return 0
        rm -f "${DIST}/"*.sh | logger verbose
        rm -f "${DIST}/"*.c | logger verbose
        echo "Sources removed" | logger info
    }
    _stats(){
        local TARGET=${1:?}
        local EXPIRES_AT="${2:-$CONFIG_EXPIRES_AT}"
        local FILENAME && FILENAME=$(basename -- "$TARGET") && FILENAME="${FILENAME%.*}"
        local FILE="${DIST}/${FILENAME}.sh"
        [[ ! -f "$FILE" ]] && echo "$FILE is not a valid file" | logger error && return 0
        local STAT_FILE="${DIST}/${FILENAME}.stat"
        [[ -f "$STAT_FILE" ]] && rm -f "$STAT_FILE"
        touch "$STAT_FILE"
        {
            local IS_BINARY=false
            LC_ALL=C grep -a '[^[:print:][:space:]]' "$FILE" >/dev/null && IS_BINARY=true
            echo "{"
            echo "  \"file\": \"$FILE\","
            echo "  \"expires_at\": \"$EXPIRES_AT\","
            echo "  \"size\": \"$(du -h "$FILE" | awk '{print $1}')\","
            echo "  \"md5\": \"$(md5sum "$FILE" | awk '{print $1}')\","
            echo "  \"sha1\": \"$(sha1sum "$FILE" | awk '{print $1}')\","
            echo "  \"sha256\": \"$(sha256sum "$FILE" | awk '{print $1}')\","
            echo "  \"sha512\": \"$(sha512sum "$FILE" | awk '{print $1}')\"",
            echo "  \"created_at\": \"$(date -Iseconds)\"",
            echo "  \"binary\": $IS_BINARY"
            echo "}"
        } >> "$STAT_FILE"        
        echo "Stat file created at $STAT_FILE" | logger success
        jq -Cc . < "$STAT_FILE" | logger verbose
    }
    build_file() {
        local FILE=$1
        [[ ! -f "$FILE" ]] && echo "$FILE is not a valid file" | logger error && return 0
        local EXPIRES_AT="${2:-$CONFIG_EXPIRES_AT}"
        local FILENAME && FILENAME=$(basename -- "$FILE") && FILENAME="${FILENAME%.*}"
        colorize "blue" "Building file ${FILE} valid until ${EXPIRES_AT}" | logger info
        # shc -r -f "${FILE}" -e "${EXPIRES_AT}"
        # cp -f "$FILE" "$DIST/$FILENAME.sh"          # .s = sh source
        # mv -f "${FILE}.x" "${BIN}/$FILENAME"        # .x = executable
        # mv -f "${FILE}.x.c" "${DIST}/$FILENAME.c"   # .c = c source
        # stats "$FILE" "$EXPIRES_AT"
        colorize "green" "Build done. run ${BIN}/${FILENAME}" | logger success
    }
    # if nnf "$@"; then return 0; fi
    nnf "$@" || usage "$?" "builder" "$@" && return 1
    return 0
}
(
    export -f builder
)
