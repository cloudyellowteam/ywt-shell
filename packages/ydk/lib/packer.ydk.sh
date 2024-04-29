#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317,SC2120
ydk:packer() {
    YDK_LOGGER_CONTEXT="packer"
    packer:validate:src-file() {
        local SRC_FILE=${1} && [ ! -f "$SRC_FILE" ] && ydk:log error "Invalid source file ${SRC_FILE}" && return 1
        [[ "$SRC_FILE" != *".cli.sh" ]] && [[ "$SRC_FILE" != *".ydk.sh" ]] && ydk:log error "Invalid file extension" && return 1
        local FILE_EXT="${SRC_FILE##*.}"
        if [[ "$SRC_FILE" != *".sh" ]] || [[ "$FILE_EXT" != "sh" ]]; then
            ydk:log error "Invalid file extension" && return 1
        fi
        local FILENAME=$(basename -- "$SRC_FILE") && FILENAME="${FILENAME%.*}" && FILENAME="${FILENAME%.*}" && [ -z "$FILENAME" ] && ydk:throw 22 "Invalid file name" && return 1
        if ! grep -q "^#!/usr/bin/env bash$" "$SRC_FILE"; then
            ydk:log error "Invalid shebang in source file: ${SRC_FILE}" && return 1
        fi
        local BUNDLE_NAME="${2:-"${FILENAME}.sh"}" && [ -z "$BUNDLE_NAME" ] && ydk:log error "Invalid bundle name" && return 1
        local FILE_BASEPATH=$(dirname -- "$SRC_FILE")
        local FILE_REALPATH=$(realpath -- "$FILE_BASEPATH")
        local FILE_RELATIVEPATH=$(realpath --relative-to="$SRC_FILE" "$FILE_BASEPATH")
        # local BUNDLES=(lib)
        jq -n -c \
            --arg src "$SRC_FILE" \
            --arg name "$FILENAME" \
            --arg bundle "$BUNDLE_NAME" \
            --arg basepath "$FILE_BASEPATH" \
            --arg realpath "$FILE_REALPATH" \
            --arg relativepath "$FILE_RELATIVEPATH" \
            --argjson lib "$({
                find "$FILE_REALPATH" \
                    -type f \
                    -name "*.ydk.sh" \
                    -not -name "*.cli.sh" \
                    -not -name "$FILENAME" \
                    -not -name "$BUNDLE_NAME" \
                    -not -path "$FILE_REALPATH" |
                    sort | jq -R . | jq -s .
            })" \
            '{
                src: $src,
                name: $name,
                bundle: $bundle,
                basepath: $basepath,
                realpath: $realpath,
                relativepath: $relativepath,
                lib: $lib               
            }' >&4
        return 0
    }
    defaults() {
        {
            echo -n "{"
            echo -n "\"expires_at\":\"${YDK_CONFIG_PACKER_EXPIRE_AT:-"${YDK_PACKER_DEFAULTS[expires_at]:-"31/12/2999"}"}\","
            echo -n "\"dist\":\"${YDK_CONFIG_PACKER_DIST:-"${YDK_PACKER_DEFAULTS[dist]:-"./dist"}"}\","
            echo -n "\"release\": $(ydk:team release 4>&1),"
            echo -n "\"team\": $(ydk:team info 4>&1)"
            echo -n "}"
        } | jq -c . >&4
    }
    __packer:inject() {
        local FILE="$1"
        # number of tabs at the beginning of the line
        local TABS="${2:-0}"
        [[ ! -f "$FILE" ]] && ydk:log error "$FILE is not a valid file" && return 1
        local TABS_SPACES=$(printf "%${TABS}s")
        {
            grep -v "^#" "$FILE" |
                grep -v "^[[:space:]]*#[^!]" |
                grep -v "^$" |
                grep -v "^#!/usr/bin/env bash$" |
                grep -v "^# shellcheck disable" |
                grep -v "^#"
        } | sed -e "s/^/${TABS_SPACES}/" >&4
        return 0
    }
    pack() {
        ydk:log info "Bundling source file"
        local VALIDATION=$(packer:validate:src-file "$1" 4>&1)
        local PACK_DEFAUTLS=$(ydk:packer defaults 4>&1)
        # jq . <<<"$VALIDATION" >&4
        # jq  . <<<"$PACK_DEFAUTLS" 1>&2
        local BUNDLE_SRC=$(jq -r '.src' <<<"$VALIDATION")
        local BUNDLE_TMP=$(ydk:temp "bundle")
        echo "#!/bin/bash" >"$BUNDLE_TMP"
        local BUNDLE_ENTRYPOINT_NAME=$(mktemp -u -t "ywt:XXXXXXXXXX") && BUNDLE_ENTRYPOINT_NAME="${BUNDLE_ENTRYPOINT_NAME##*/}"
        {
            ydk:team copyright
            echo "# Builder: $(whoami | md5sum | cut -d' ' -f1)"
            local BUNDLE_NAME=$(jq -r '.name' <<<"$VALIDATION")
            local BUNDLE_IS_SDK=false
            [[ "$BUNDLE_NAME" == "ydk" ]] && BUNDLE_NAME="sdk" && BUNDLE_IS_SDK=true && BUNDLE_ENTRYPOINT_NAME="ydk"
            local BUNDLE_FILE_NAME=$(jq -r '.bundle' <<<"$VALIDATION") && BUNDLE_FILE_NAME=${BUNDLE_FILE_NAME//.sh/.sh}
            echo "# Bundle File Name: <$BUNDLE_FILE_NAME>"
            echo "# Bundle Entrypoint: <${BUNDLE_ENTRYPOINT_NAME}>"
            [[ "$BUNDLE_IS_SDK" == false ]] && {
                echo "curl -sSL https://raw.githubusercontent.com/cloudyellowteam/ywt-shell/main/packages/ydk/ydk.sh"
                echo "# Added YDK CLI"
                echo "source \"ydk.sh\""
                echo "${BUNDLE_ENTRYPOINT_NAME}(){"
                echo -e "\tset -e -o pipefail"
            }
            # echo -e "\techo \"\${YDK_BUNDLE_${BUNDLE_NAME^^}_INFO[*]}\""
            while read -r DEPENDENCIE; do
                # echo -e "\tsource \"$DEPENDENCIE\""
                __packer:inject "$DEPENDENCIE" 0 4>&1
            done < <(jq -r '.lib[]' <<<"$VALIDATION")
            __packer:inject "$BUNDLE_SRC" 0 4>&1
            [[ "$BUNDLE_IS_SDK" == false ]] && {
                # echo -e "\treturn 0"
                echo "}"
                echo -e "[[ -z \"\$YDK_PACKAGE_RELEASE_INFO_${BUNDLE_NAME^^}\" ]] && declare -g -A YDK_PACKAGE_RELEASE_INFO_${BUNDLE_NAME^^}=("
                echo -e "\t[\"entrypoint\"]=\"${BUNDLE_ENTRYPOINT_NAME}\""
                echo -e "\t[\"expires_at\"]=\"$(jq -r .expires_at <<<"$PACK_DEFAUTLS")\""
                echo -e "\t[\"release\"]='$(
                    jq -cr '
                    .release
                ' <<<"$PACK_DEFAUTLS"
                )'"
                echo -e "\t[\"team\"]='$(jq -cr .team <<<"$PACK_DEFAUTLS")'"
                echo -e ") && readonly YDK_PACKAGE_RELEASE_INFO _${BUNDLE_NAME^^}&& export YDK_PACKAGE_RELEASE_INFO_${BUNDLE_NAME^^}"
                echo "if [[ \"\$#\" -gt 0 ]]; then"
                echo -e "\t${BUNDLE_ENTRYPOINT_NAME} \"\$@\""
                echo -e "\texit \$?"
                echo "fi"
            }
        } >>"$BUNDLE_TMP"
        local BUNDLE_FULL_PATH="$(jq -r '.realpath' <<<"$VALIDATION")/${BUNDLE_FILE_NAME}"
        # {
        #     # echo "$BUNDLE_TMP"
        #     # echo "$BUNDLE_ENTRYPOINT_NAME"
        #     # echo "$BUNDLE_FULL_PATH"
        #     jq -c . <<<"$VALIDATION"
        #     # cat "$BUNDLE_TMP"
        # } >&4
        rm -f "$BUNDLE_FULL_PATH"
        mv -f "$BUNDLE_TMP" "$BUNDLE_FULL_PATH"
        chmod +x "$BUNDLE_FULL_PATH"
        ydk:log info "Bundle ${BUNDLE_ENTRYPOINT_NAME^^} created. $BUNDLE_FULL_PATH"

        # ydk:log info "Testing bundle 'source $BUNDLE_TMP logger success test'"
        # echo
        # chmod +x "$BUNDLE_TMP"
        # # [[ "$BUNDLE_IS_SDK" == false ]] && {
        #     if ! bash -c "$BUNDLE_TMP logger success \"YDK Package is ready\"" 1>&2; then
        #         ydk:log error "Bundle is not valid"
        #     else
        #         ydk:log success "Bundle is valid"
        #     fi
        # # }
        # echo
        # [[ "$BUNDLE_IS_SDK" == true ]] && {
        #     ydk:log info "Testing ${BUNDLE_ENTRYPOINT_NAME^^} SDK"
        #     echo
        #     if ! "$BUNDLE_TMP" logger success "SDK is ready"; then
        #         ydk:log error "SDK bundle is not valid"
        #     else
        #         ydk:log success "SDK bundle is valid"
        #     fi
        # }
        # # rm -f "$BUNDLE_TMP"
        return 0
    }
    ydk:try "$@" 4>&1
    return $?
}
{
    [[ -z "$YDK_PACKER_DEFAULTS" ]] && declare -g -A YDK_PACKER_DEFAULTS=(
        [expires_at]="31/12/2999"
        [dist]="./dist"
    )
}
builder:v2() {
    YWT_LOG_CONTEXT="BUILDER"
    config() {
        local DEFAULT_EXPIRES_AT="${YWT_CONFIG_BUILDER_EXPIRES_AT:-"31/12/2999"}"
        local PATH_DIST=${2:-"${YWT_CONFIG_BUILDER_DIST:-"$(jq -r .path.dist <<<"$YWT_CONFIG")"}"} && readonly PATH_DIST
        local PATH_SRC=${3:-"${YWT_CONFIG_BUILDER_SRC:-"$(jq -r .path.src <<<"$YWT_CONFIG")"}"} && readonly PATH_SRC
        local PATH_SDK=$(jq -r .path.sdk <<<"$YWT_CONFIG") && SDK=$(realpath -- "$PATH_SDK") && readonly PATH_SDK
        local PATH_BIN=$(jq -r .path.bin <<<"$YWT_CONFIG") && readonly PATH_BIN
        {
            echo -n "{"
            echo -n "\"expires\": \"$DEFAULT_EXPIRES_AT\","
            echo -n "\"path/dist\": \"$PATH_DIST\","
            echo -n "\"path/src\": \"$PATH_SRC\","
            echo -n "\"path/sdk\": \"$PATH_SDK\","
            echo -n "\"path/bin\": \"$PATH_BIN\""
            echo -n "}"
        } | jq -c .
    }
    info() {
        {
            echo -n "{"
            echo -n "\"date\": \"$(date -Iseconds)\","
            echo -n "\"id\": \"$(git rev-parse HEAD 2>/dev/null || echo "Unknown")\","
            echo -n "\"branch\": \"$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "Unknown")\","
            echo -n "\"tag\": \"$(git describe --tags 2>/dev/null || echo "Unknown")\","
            echo -n "\"commit\": \"$(git rev-parse --short HEAD 2>/dev/null || echo "Unknown")\","
            echo -n "\"author\": \"$(git log -1 --pretty=format:'%an <%ae>' 2>/dev/null || echo "Unknown")\","
            echo -n "\"message\": \"$(git log -1 --pretty=format:'%s' 2>/dev/null || echo "Unknown")\""
            echo -n "}"
        } | jq -c .
    }
    _prepare() {
        while read -r KEY VALUE; do
            [[ "$KEY" =~ ^path/ ]] && [[ ! -d "$VALUE" ]] && mkdir -p "${VALUE}" && echo "Created directory ${VALUE}" | logger verbose
        done < <(jq -r 'to_entries|map("\(.key) \(.value|tostring)")|.[]' <<<"$(config "$@")")
        echo "Directories created" | logger info
    }
    _cleanup() {
        local KEEP_SOURCE="${YWT_CONFIG_BUILDER_KEEP_SOURCE:-false}"
        [[ "$KEEP_SOURCE" == true ]] && echo "Keeping sources" | logger info && return 0
        local CONFIG=$(config "$@")
        local DIST=$(jq -r '.["path/dist"]' <<<"$CONFIG")
        rm -f "${DIST}/"*.sh >/dev/null
        rm -f "${DIST}/"*.c >/dev/null
        echo "Sources removed" | logger info
    }
    _bundle:validate() {
        local CONFIG=$(config "$@")
        local SRC_FILE=${1:?} && [ ! -f "$SRC_FILE" ] && echo "{ \"error\": \"Invalid source file\" }" && return 1
        local FILE_EXT="${SRC_FILE##*.}" && [[ "$FILE_EXT" != "sh" ]] && echo "{ \"error\": \"Invalid file extension\" }" && return 1

        if ! grep -q "^#!/usr/bin/env bash$" "$SRC_FILE"; then
            echo "{ \"error\": \"Invalid shebang\" }" && return 1
            return 1
        fi
        local FILENAME=$(basename -- "$SRC_FILE") && FILENAME="${FILENAME%.*}"
        local BUNDLE_NAME="${2:-"${FILENAME}.sh"}" && [ -z "$BUNDLE_NAME" ] && echo "{ \"error\": \"Invalid bundle name\" }" && return 1
        local FILE_BASEPATH=$(dirname -- "$SRC_FILE")
        local FILE_REALPATH=$(realpath -- "$FILE_BASEPATH")
        local FILE_RELATIVEPATH=$(realpath --relative-to="$SRC_FILE" "$FILE_BASEPATH")
        if [[ ! -d "${FILE_REALPATH}/lib" ]]; then
            echo "{ \"error\": \"${FILE_REALPATH}/lib is not a valid directory\" }" && return 1
        fi
        local SRC_PATH=$(jq -r '.["path/src"]' <<<"$CONFIG")
        local TARGET_FILE="${SRC_PATH}/${BUNDLE_NAME}" && [[ -f "$TARGET_FILE" ]] && rm -f "$TARGET_FILE"
        {
            echo -n "$CONFIG"
            echo -n "{"
            echo -n "\"success\": true,"
            echo -n "\"file\": \"$SRC_FILE\","
            echo -n "\"filename\": \"$FILENAME\","
            echo -n "\"extension\": \"$FILE_EXT\","
            echo -n "\"basepath\": \"$FILE_BASEPATH\","
            echo -n "\"realpath\": \"$FILE_REALPATH\","
            echo -n "\"relativepath\": \"$FILE_RELATIVEPATH\","
            echo -n "\"lib\": \"$FILE_REALPATH/lib\","
            echo -n "\"name\": \"$BUNDLE_NAME\","
            echo -n "\"output\": \"$TARGET_FILE\""
            echo -n "}"
        } | jq -sc '
            .[0] as $config |
            .[1] as $validation |
            {
                config: $config,
                validation: $validation
            }
        '
        return 0
    }
    _bundle:inject() {
        local FILE="$1"
        [[ ! -f "$FILE" ]] && echo "{ \"error\": \"$FILE is not a valid file\" }" && return 0
        grep -v "^#" "$FILE" | grep -v "^[[:space:]]*#[^!]" | grep -v "^$" | grep -v "^#!/usr/bin/env bash$" | grep -v "^# shellcheck disable" | grep -v "^#"
    }
    _bundle:checksum:generate() {
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
    bundle() {
        local VALIDATION=$(_bundle:validate "$@")
        if ! jq -r '.validation.success' <<<"$VALIDATION" | grep -q true; then
            echo "$VALIDATION" | jq -c .
            return 1
        fi
        _prepare
        _cleanup
        local BUNDLE_FILE=$(jq -r '.validation.output' <<<"$VALIDATION")
        local BUNDLE_LIB_PATH=$(jq -r '.validation.lib' <<<"$VALIDATION")
        local BUNDLE_SRC_PATH=$(jq -r '.config["path/src"]' <<<"$VALIDATION")
        local BUNDLE_OUTPUT_TMP=$(mktemp -u -t "ywt-XXXX")
        echo "#!/bin/bash" >"$BUNDLE_FILE"
        {
            copyright
            while read -r FILE; do
                local FILENAME && FILENAME=$(basename -- "$FILE")
                local RELATIVE_PATH && RELATIVE_PATH=$(realpath --relative-to="$BUNDLE_SRC_PATH" "$FILE")
                local RELATIVE_PATH && RELATIVE_PATH=$(dirname -- "$RELATIVE_PATH")
                echo "# <$FILENAME>"
                _bundle:inject "$FILE"
                echo "# </$FILENAME>"
                {
                    echo -n "{"
                    echo -n "\"file\": \"$FILE\","
                    echo -n "\"path\": \"$RELATIVE_PATH\","
                    echo -n "\"content\": \"$(cat "$FILE" | base64 -w 0)\","
                    echo -n "\"checksum\": $(_bundle:checksum:generate "$FILE")"
                    echo -n "}"
                } >>"$BUNDLE_OUTPUT_TMP"
            done < <(find "$BUNDLE_LIB_PATH" -type f -name "*.ywt.sh" | sort)

            local SRC_FILE=$(jq -r '.validation.file' <<<"$VALIDATION")
            echo "# <$SRC_FILE>"
            _bundle:inject "$SRC_FILE"
            echo "# </$SRC_FILE>"
        } >>"$BUNDLE_FILE"
        echo "Bundle created" | logger info
        cat "$BUNDLE_FILE"
        # jq -s '.' "$BUNDLE_OUTPUT_TMP"
    }

    __nnf "$@" || usage "$?" "builder" "$@" && return 1
    return 0
}
builder:v1() {
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
    __nnf "$@" || usage "$?" "builder" "$@" && return 1
    return 0
}
