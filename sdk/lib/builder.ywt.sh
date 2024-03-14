#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
builder() {
    YWT_LOG_CONTEXT="BUILDER"
    local CONFIG_EXPIRES_AT="${YWT_CONFIG_BUILDER_EXPIRES_AT:-"31/12/2999"}"
    local DIST=${2:-"${YWT_CONFIG_BUILDER_DIST:-"$(jq -r .path.dist <<<"$YWT_CONFIG")"}"} && readonly DIST
    local SRC=${3:-"${YWT_CONFIG_BUILDER_SRC:-"$(jq -r .path.src <<<"$YWT_CONFIG")"}"} && readonly SRC
    local SDK=$(jq -r .path.sdk <<<"$YWT_CONFIG") && SDK=$(realpath -- "$SDK") && readonly SDK
    local BIN=$(jq -r .path.bin <<<"$YWT_CONFIG") && readonly BIN
    _prepare() {
        [[ ! -d "$DIST" ]] && mkdir -p "${DIST}"
        rm -fR "${DIST:?}"/*
        [[ ! -d "$BIN" ]] && mkdir -p "${BIN}"
        if ! command -v shc &>/dev/null; then
            colors apply "red" "$YWT_LOG_CONTEXT compiler is not installed, trying install" | logger warn
            apt-get install shc -y || return 1
        fi
        local SHC_INSTALLED && SHC_INSTALLED=$(command -v shc)
        [[ -z "$SHC_INSTALLED" ]] && colors apply "red" "$YWT_LOG_CONTEXT compiler is not installed" | logger error && return 1
        colors apply "green" "$YWT_LOG_CONTEXT Compiler is installed" | logger success
    }
    _cleanup() {
        local KEEP_SOURCE="${YWT_CONFIG_BUILDER_KEEP_SOURCE:-false}"
        [[ "$KEEP_SOURCE" == true ]] && echo "Keeping sources" | logger info && return 0
        rm -f "${DIST}/"*.sh | logger verbose
        rm -f "${DIST}/"*.c | logger verbose
        echo "Sources removed" | logger info
    }
    _stats() {
        local TARGET=${1:?}
        local EXPIRES_AT="${2:-$CONFIG_EXPIRES_AT}"
        local FILENAME && FILENAME=$(basename -- "$TARGET") && FILENAME="${FILENAME%.*}"
        local IS_BINARY=false
        LC_ALL=C grep -a '[^[:print:][:space:]]' "$TARGET" >/dev/null && IS_BINARY=true
        echo "{"
        echo "  \"file\": \"$TARGET\","
        echo "  \"expires_at\": \"$EXPIRES_AT\","
        echo "  \"size\": \"$(du -h "$TARGET" | awk '{print $1}' 2>/dev/null)\","
        echo "  \"md5\": \"$(md5sum "$TARGET" | awk '{print $1}' 2>/dev/null)\","
        echo "  \"sha1\": \"$(sha1sum "$TARGET" | awk '{print $1}' 2>/dev/null)\","
        echo "  \"sha256\": \"$(sha256sum "$TARGET" | awk '{print $1}' 2>/dev/null)\","
        echo "  \"sha512\": \"$(sha512sum "$TARGET" | awk '{print $1}' 2>/dev/null)\"",
        echo "  \"created_at\": \"$(date -Iseconds)\"",
        echo "  \"binary\": $IS_BINARY"
        echo "}"
    }
    __bundle() {
        local SRC_FILE=${1:?} && [ ! -f "$SRC_FILE" ] && echo "Invalid source file" | logger error && return 1
        local FILE_EXT="${SRC_FILE##*.}" && [[ "$FILE_EXT" != "sh" ]] && echo "Invalid file extension" | logger error && return 1
        local FILENAME=$(basename -- "$SRC_FILE") && FILENAME="${FILENAME%.*}"
        local FILE_BASEPATH=$(dirname -- "$SRC_FILE")
        local FILE_REALPATH=$(realpath -- "$FILE_BASEPATH")
        local FILE_RELATIVEPATH=$(realpath --relative-to="$SRC_FILE" "$FILE_BASEPATH")
        local BUNDLE_NAME="${2:-"${FILENAME}.sh"}" && [ -z "$BUNDLE_NAME" ] && echo "Invalid bundle name" | logger error && return 1
        local EXPIRES_AT="${3:-$CONFIG_EXPIRES_AT}" && [ -z "$EXPIRES_AT" ] && EXPIRES_AT="31/12/2999"
        local LIB=${FILE_REALPATH}/lib && [[ ! -d "$LIB" ]] && echo "${LIB} is not a valid directory" | logger error && return 0
        # local SRC=${3:-"${YWT_CONFIG_BUILDER_SRC:-"$(jq -r .path.src <<<"$YWT_CONFIG")"}"}
        local TARGET_FILE="${SRC}/${BUNDLE_NAME}" && [[ -f "$TARGET_FILE" ]] && rm -f "$TARGET_FILE"
        # {
        #     debug -n "{"
        #     debug -n "\"FILENAME\": \"$FILENAME\","
        #     debug -n "\"FILE_BASEPATH\": \"$FILE_BASEPATH\","
        #     debug -n "\"FILE_REALPATH\": \"$FILE_REALPATH\","
        #     debug -n "\"FILE_RELATIVEPATH\": \"$FILE_RELATIVEPATH\","
        #     debug -n "\"BUNDLE_NAME\": \"$BUNDLE_NAME\","
        #     debug -n "\"EXPIRES_AT\": \"$EXPIRES_AT\","
        #     debug -n "\"LIB\": \"$LIB\","
        #     debug -n "\"TARGET_FILE\": \"$TARGET_FILE\","
        #     debug -n "}"
        # }
        _inject() {
            local FILE="$1"
            [[ ! -f "$FILE" ]] && echo "$FILE is not a valid file" | logger error && return 0
            grep -v "^#" "$FILE" | grep -v "^$" | grep -v "^#!/usr/bin/env bash"
        }
        {
            echo "#!/bin/bash"
            echo "# shellcheck disable=SC2044,SC2155,SC2317"
            copyright
            while read -r FILE; do
                local FILENAME && FILENAME=$(basename -- "$FILE")
                local RELATIVE_PATH && RELATIVE_PATH=$(realpath --relative-to="$SRC" "$FILE")
                local RELATIVE_PATH && RELATIVE_PATH=$(dirname -- "$RELATIVE_PATH")
                echo -e "# $(_stats "$FILE" "$EXPIRES_AT" | jq -c .)\n"
                _inject "$FILE"
                echo -e "\n# end of $FILENAME\n"
            done < <(find "$LIB" -type f -name "*.ywt.sh" | sort)
            # echo "Packaging ${GREEN}${SRC_FILE}${NC}" | logger debug
            echo -e "# $(_stats "$SRC_FILE" "$EXPIRES_AT" | jq -c .)\n"
            _inject "$SRC_FILE"
            echo -e "\n# end of $SRC_FILE\n"
            # echo -e "\nif [ \"\$#\" -gt 0 ]; then $FILENAME \"\$@\"; fi"
        } >>"$TARGET_FILE"
        _stats "$TARGET_FILE" "$EXPIRES_AT" | jq -Cc . | logger info
    }
    __build_file() {
        local FILE=$1 && readonly FILE && [[ ! -f "$FILE" ]] && echo "$FILE is not a valid file" | logger error && return 0
        local FILE_DIR=$(dirname -- "$FILE") && readonly FILE_DIR
        local EXPIRES_AT="${2:-$CONFIG_EXPIRES_AT}" && [ -z "$EXPIRES_AT" ] && EXPIRES_AT="31/12/2999"
        # EXPIRES_AT="31/12/9999"
        local FILENAME && FILENAME=$(basename -- "$FILE") && FILENAME="${FILENAME%.*}"
        colors apply "blue" "Building file ${FILE} valid until ${EXPIRES_AT}" | logger info
        # -e %s  Expiration date in dd/mm/yyyy format [none]
        # -m %s  Message to display upon expiration ["Please contact your provider"]
        # -f %s  File name of the script to compile
        # -i %s  Inline option for the shell interpreter i.e: -e
        # -x %s  eXec command, as a printf format i.e: exec('%s',@ARGV);
        # -l %s  Last shell option i.e: --
        # -o %s  output filename
        # -r     Relax security. Make a redistributable binary
        # -v     Verbose compilation
        # -S     Switch ON setuid for root callable programs [OFF]
        # -D     Switch ON debug exec calls [OFF]
        # -U     Make binary untraceable [no]
        # -H     Hardening : extra security protection [no]
        #     Require bourne shell (sh) and parameters are not supported
        # -C     Display license and exit
        # -A     Display abstract and exit
        # -B     Compile for busybox
        # -h     Display help and exit
        shc -r -f "${FILE}" -e "${EXPIRES_AT}" -m "File expired since ${EXPIRES_AT}, please contact us to renew. $(jq -Cc .yellowteam <<<"$YWT_CONFIG")"
        # .s = sh source | .c = c source | .x = executable
        [ -f "$DIST/$FILENAME.sh" ] && rm -f "$DIST/$FILENAME.sh"
        [ -f "$DIST/$FILENAME.c" ] && rm -f "$DIST/$FILENAME.c"
        [ -f "${BIN}/$FILENAME" ] && rm -f "${BIN}/$FILENAME"
        cp -f "$FILE" "$DIST/$FILENAME.sh"      # /dist/file.sh
        mv -f "${FILE}.x.c" "$DIST/$FILENAME.c" # /dist/file.c
        mv -f "${FILE}.x" "${BIN}/$FILENAME"    # /bin/file
        # mv -f "${FILE}.x.c" "${DIST}/$FILENAME.c"           # ./file.c
        colors apply "green" "Build done. run ${BIN}/${FILENAME}" | logger success
        jq -Cn \
            --argjson sh "$(_stats "$DIST/$FILENAME.sh" "$EXPIRES_AT")" \
            --argjson c "$(_stats "$DIST/$FILENAME.c" "$EXPIRES_AT")" \
            --argjson bin "$(_stats "${BIN}/$FILENAME" "$EXPIRES_AT")" \
            '{sh: $sh, c: $c, bin: $bin}' | logger info

    }
    _build_sdk() {
        _prepare
        __bundle "$SDK/sdk.sh" "ywt.sh" "31/12/2999"
        # sed -i -e 's/# binary injection/text/g' "$SRC/ywt.sh"
        __build_file "$SRC/ywt.sh" "31/12/2999"
        return 0
    }
    inspect() {
        jq -r '.path' <<<"$YWT_CONFIG"
    }   
    _nnf "$@" || usage "$?" "builder" "$@" && return 1
    return 0
}
(
    export -f builder
)
