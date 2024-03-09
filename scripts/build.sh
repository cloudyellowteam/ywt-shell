#!/bin/bash
builder() {
    local CURRENT_DIR && CURRENT_DIR=$(dirname -- "$0")
    local ROOT_DIR && ROOT_DIR=$(dirname -- "$CURRENT_DIR") && ROOT_DIR=$(realpath -- "$ROOT_DIR")
    #shellcheck source=/dev/null
    source "${ROOT_DIR}/rapd.sh" task --quiet
    echo "${RAPD_METADATA}" | jq .package
    local CONFIG_EXPIRES_AT="${2:-"31/12/2999"}"
    local DIST="${ROOT_DIR}/dist"
    local BIN="${ROOT_DIR}/bin"
    colorize "blue" "Building shc files from $ROOT_DIR" | logger info
    prepare() {
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
    cleanup() {
        local KEEP_SOURCE="${RAPD_CONFIG_BUILDER_KEEP_SOURCE:-false}"
        [[ "$KEEP_SOURCE" == true ]] && echo "Keeping sources" | logger info && return 0
        rm -f "${DIST}/"*.sh | logger verbose
        rm -f "${DIST}/"*.c | logger verbose
        echo "Sources removed" | logger info
    }
    setup_src_dir() {
        local TARGET=${1:?}
        [[ ! -d "$TARGET" ]] && echo "${TARGET} is not a valid target" | logger error && return 0
        find "$TARGET" -type f -name "*.sh" \
            -and -not -name "*.rapd.sh" \
            -and -not -name "rapd.sh" \
            -execdir sh -c '
                for file do
                    new_name="${file%.*}$1.${file##*.}"
                    # mv "$file" "$new_name"
                    # echo "mv $file $new_name"
                done
            ' sh ".rapd" {} +
    }
    build_file() {
        local FILE=$1
        [[ ! -f "$FILE" ]] && echo "$FILE is not a valid file" | logger error && return 0
        local EXPIRES_AT="${2:-$CONFIG_EXPIRES_AT}"
        local FILENAME && FILENAME=$(basename -- "$FILE") && FILENAME="${FILENAME%.*}"
        colorize "blue" "Building file ${FILE} valid until ${EXPIRES_AT}" | logger info
        shc -r -f "${FILE}" -e "${EXPIRES_AT}"
        cp -f "$FILE" "$DIST/$FILENAME.sh"          # .s = sh source
        mv -f "${FILE}.x" "${BIN}/$FILENAME"        # .x = executable
        mv -f "${FILE}.x.c" "${DIST}/$FILENAME.c"   # .c = c source
        stats "$FILE" "$EXPIRES_AT"
        colorize "green" "Build done. run ${BIN}/${FILENAME}" | logger success
    }
    bundle() {
        local SRC=${1:?}
        local EXPIRES_AT="${3:-$CONFIG_EXPIRES_AT}"
        [[ ! -d "$SRC" ]] && echo "${SRC} is not a valid directory" | logger error && return 0

        local MAIN && MAIN=$(find "$SRC" -type f -name ".rapd.sh" -or -name "main.sh" | head -n 1)
        [[ ! -f "$MAIN" ]] && echo "Invalid module main file, create a file ${YELLOW}<module>.rapd.sh${NC} in ${TARGET} folder" | logger from_buf error && return 0

        local BUNDLE_FILENAME && BUNDLE_FILENAME=$(basename -- "$MAIN")
        local BUNDLE_NAME="${BUNDLE_FILENAME%.*}"
        [[ "$BUNDLE_NAME" == "main" ]] && BUNDLE_NAME="rapd"
        [[ "$BUNDLE_NAME" != "rapd" ]] && BUNDLE_NAME="rapd.${BUNDLE_NAME}"

        local BUNDLE="${DIST}/${BUNDLE_NAME}"
        [[ -f "$BUNDLE" ]] && rm -f "$BUNDLE"
        touch "$BUNDLE"
        echo "#!/bin/bash" >"$BUNDLE"
        while read -r FILE; do
            local FILENAME && FILENAME=$(basename -- "$FILE")
            local RELATIVE_PATH && RELATIVE_PATH=$(realpath --relative-to="$RAPD_PATH_ROOT" "$file")
            local RELATIVE_PATH && RELATIVE_PATH=$(dirname -- "$RELATIVE_PATH")
            echo "Packaging ${RELATIVE_PATH}/${FILENAME}" | logger debug
            {
                echo -e "\n# start of $FILENAME\n" &&
                    grep -v "^#" <"$FILE"
            } >>"$BUNDLE"
            # cat "$FILE" | grep -v "^#" >>"$BUNDLE" # | tail -n +2
            echo -e "\n# end of $FILENAME\n" >>"$BUNDLE"
        done < <(find "$SRC" -type f -name "*.sh" -not -name "$BUNDLE_FILENAME")
        echo "Packaging ${GREEN}${MAIN}${NC}" | logger debug
        cat "$MAIN" >>"$BUNDLE"
        echo -e "\nrapd \"\$@\"" >>"$BUNDLE"
        build_file "$BUNDLE"
    }
    stats(){
        local TARGET=${1:?}
        local EXPIRES_AT="${2:-$CONFIG_EXPIRES_AT}"
        local FILENAME && FILENAME=$(basename -- "$TARGET") && FILENAME="${FILENAME%.*}"
        local FILE="${DIST}/${FILENAME}.sh"
        [[ ! -f "$FILE" ]] && echo "$FILE is not a valid file" | logger error && return 0
        local STAT_FILE="${DIST}/${FILENAME}.stat"
        [[ -f "$STAT_FILE" ]] && rm -f "$STAT_FILE"
        touch "$STAT_FILE"
        {
            echo "{"
            echo "  \"file\": \"$FILE\","
            echo "  \"expires_at\": \"$EXPIRES_AT\","
            echo "  \"size\": \"$(du -h "$FILE" | awk '{print $1}')\","
            echo "  \"md5\": \"$(md5sum "$FILE" | awk '{print $1}')\","
            echo "  \"sha1\": \"$(sha1sum "$FILE" | awk '{print $1}')\","
            echo "  \"sha256\": \"$(sha256sum "$FILE" | awk '{print $1}')\","
            echo "  \"sha512\": \"$(sha512sum "$FILE" | awk '{print $1}')\"",
            echo "  \"created_at\": \"$(date -Iseconds)\"",
            echo "  \"binary\": \"$(is_binary "$FILE")\""
            echo "}"
        } >> "$STAT_FILE"        
        echo "Stat file created at $STAT_FILE" | logger success
        jq -Cc . < "$STAT_FILE" | logger verbose
    }
    build() {
        local TARGET=${1:?}
        echo "Building $TARGET" | logger info
        local EXPIRES_AT="${2:-$CONFIG_EXPIRES_AT}"
        prepare
        setup_src_dir "$TARGET"
        [[ ! -d "$TARGET" ]] && [[ ! -f "$TARGET" ]] && echo "${TARGET} is not a valid target" | logger error && return 1
        [[ -d "$TARGET" ]] && local KIND=bundle && bundle "$TARGET" "$EXPIRES_AT"
        [[ -f "$TARGET" ]] && local KIND=file && build_file "$TARGET" "$EXPIRES_AT"
        echo "Build ${KIND} done" | logger success
        # cleanup
    }
    build "$@"
}
builder "$@"

# for filename in /shc-data/bash/*.sh; do

#     for ((i=0; i<=3; i++)); do

#         shc -r -f $filename -o "$filename-build"

#     done

# done

# rm -f /shc-data/bash/*.c
