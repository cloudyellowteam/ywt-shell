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
    __packer:compiler() {
        if ! command -v shc >/dev/null 2>&1; then
            ydk:log warn "Compiler is not installed, trying install"
            if command -v apt-get >/dev/null 2>&1; then
                apt-get install shc -y >/dev/null 2>&1 && {
                    ydk:log success "Compiler installed"
                    return 0
                } && return 0
            else
                # If the above installation method seems like too much work, then just download a compiled binary package from release page and copy the shc binary to /usr/bin and shc.1 file to /usr/share/man/man1.
                # local SHC_ZIP="https://github.com/neurobin/shc/archive/refs/tags/4.0.3.tar.gz"
                # local SHC_TMP=$(ydk:temp "shc" 4>&1)
                # local SHC_DIR=$(ydk:temp "shc" 4>&1)
                # local SHC_BIN="/usr/bin/shc"
                # curl -sSL "$SHC_ZIP" -o "$SHC_TMP" && {
                #     tar -xzf "$SHC_TMP" -C "$SHC_DIR" --strip-components=1
                #     cd "$SHC_DIR" && make install
                #     if [[ -f "$SHC_BIN" ]]; then
                #         ydk:log success "Compiler installed"
                #         return 0
                #     else
                #         ydk:log error "Compiler not installed"
                #         return 1
                #     fi
                # }
                ydk:throw 127 "Not package manager found to intall compiler"
            fi
            return 1
        fi
        local EXPIRES_AT="${YDK_BUILDER_DEFAULTS_EXPIRES_AT}" && [ -z "$EXPIRES_AT" ] && EXPIRES_AT="31/12/2999"
        if [[ ! $EXPIRES_AT =~ ^([0-9]{2})/([0-9]{2})/([0-9]{4})$ ]]; then
            ydk:throw 22 "Invalid date format: $EXPIRES_AT. Use dd/mm/yyyy."
            return 1
        fi
        IFS='/' read -r EXPIRES_AT_DAY EXPIRES_AT_MONTH EXPIRES_AT_YEAR <<<"$EXPIRES_AT"
        if ! date -d "$EXPIRES_AT_YEAR-$EXPIRES_AT_MONTH-$EXPIRES_AT_DAY" "+%Y-%m-%d" &>/dev/null; then
            ydk:throw 22 "Invalid date: $EXPIRES_AT"
            return 1
        fi
        unset EXPIRES_AT_DAY EXPIRES_AT_MONTH EXPIRES_AT_YEAR

        local EXPIRES_MESSAGE="File expired since ${EXPIRES_AT}, please contact us to renew"
        local SHC_ARGS=()
        while [[ $# -gt 0 ]]; do
            case "$1" in
            -e)
                EXPIRES_AT="${2}" && shift 2
                ;;
            -m)
                EXPIRES_MESSAGE+=". ${2}" && shift 2
                ;;
            *)
                SHC_ARGS+=("$1")
                shift
                ;;
            esac
        done
    
        shc -v -e "${EXPIRES_AT}" \
            -m "${EXPIRES_MESSAGE}" \
            "${SHC_ARGS[@]}" >&4

        return $?

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
    }
    bundle() {
        local VALIDATION=$(packer:validate:src-file "$1" 4>&1)
        local PACK_DEFAUTLS=$(ydk:packer defaults 4>&1)
        ydk:log info "Bundling source file" 
        # jq . <<<"$VALIDATION" >&4
        # jq  . <<<"$PACK_DEFAUTLS" >&1
        local BUNDLE_SRC=$(jq -r '.src' <<<"$VALIDATION")
        local BUNDLE_NAME=$(jq -r '.name' <<<"$VALIDATION")
        local BUNDLE_TMP=$(ydk:temp "bundle" 4>&1)
        echo "#!/bin/bash" >"$BUNDLE_TMP"
        local BUNDLE_ENTRYPOINT_NAME=$(mktemp -u -t "ywt:XXXXXXXXXX") && BUNDLE_ENTRYPOINT_NAME="${BUNDLE_ENTRYPOINT_NAME##*/}"
        {
            ydk:team copyright
            echo "# Builder: $(whoami | md5sum | cut -d' ' -f1)"
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
        ydk:log success "Bundle ${BUNDLE_ENTRYPOINT_NAME^^} created. $BUNDLE_FULL_PATH"
        local BUNDLE_CHECKSUM=$(ydk:checksum generate "$BUNDLE_FULL_PATH" "sha256")
        ydk:log "success" "Checksum: $BUNDLE_CHECKSUM"
        echo "$BUNDLE_CHECKSUM" >"$BUNDLE_FULL_PATH.checksum"
        if ! ydk:checksum verify "$BUNDLE_FULL_PATH" "$BUNDLE_CHECKSUM" "sha256"; then
            # ydk:log "ERROR" "Checksum verification failed $?: $BUNDLE_FULL_PATH"
            ydk:throw 255 "Checksum verification failed $?: $BUNDLE_FULL_PATH"
        else
            ydk:log "success" "Checksum verification passed"
        fi
        echo "$BUNDLE_FULL_PATH" >&4
        return 0
        # ydk:log info "Testing bundle 'source $BUNDLE_TMP logger success test'"
        # echo
        # chmod +x "$BUNDLE_TMP"
        # # [[ "$BUNDLE_IS_SDK" == false ]] && {
        #     if ! bash -c "$BUNDLE_TMP logger success \"YDK Package is ready\"" >&1; then
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
        # return 0
    }
    compile() {
        local FILE=$1 && [[ ! -f "$FILE" ]] && echo "$FILE is not a valid file" && return 0
        local EXPIRES_AT="${2}" && [ -z "$EXPIRES_AT" ] && EXPIRES_AT="31/12/2999"
        local FILE_DIR=$(dirname -- "$FILE") && readonly FILE_DIR
        local FILENAME && FILENAME=$(basename -- "$FILE") && FILENAME="${FILENAME%.*}" && FILENAME="${FILENAME%.*}" && [ -z "$FILENAME" ] && echo "Invalid file name: $FILE" && return 1
        ydk:log "info" "Compiling $FILE, expires at $EXPIRES_AT"
        [[ -f "${FILE_DIR}/${FILENAME}.bin" ]] && rm -f "${FILE_DIR}/${FILENAME}.bin"
        [[ -f "${FILE_DIR}/${FILENAME}.sh.x.c" ]] && rm -f "${FILE_DIR}/${FILENAME}.sh.x.c"
        __packer:compiler -r \
            -f "${FILE}" \
            -e "${EXPIRES_AT}" \
            -o "${FILE_DIR}/${FILENAME}.bin" 4>&1 >&4
        local BUILD_STATUS=$?
        if [[ $BUILD_STATUS -eq 0 ]]; then
            ydk:log "success" "File compiled successfully: ${FILE_DIR}/${FILENAME}.bin"
            ydk:log "info" "Run ${FILE_DIR}/${FILENAME}.bin process inspect | jq ."
            return "$BUILD_STATUS"
        else
            ydk:log "Error" "File compilation failed: ${FILE_DIR}/${FILENAME}.bin"
            return 1
        fi
    }
    build() {
        ydk:log info "Building bundle"
        local FILE=$1 && [[ ! -f "$FILE" ]] && ydk:throw 22 "Invalid file ${FILE}" && return 1
        local EXPIRES_AT="${2:-$YDK_BUILDER_DEFAULTS_EXPIRES_AT}" && [ -z "$EXPIRES_AT" ] && EXPIRES_AT="31/12/2999"
        ydk:log info "Packing"
        local BUNDLE=$(bundle "$FILE" 4>&1)
        [[ -z "$BUNDLE" ]] && ydk:throw 22 "Invalid bundle" && return 1
        ydk:log info "Compiling $BUNDLE"
        if ! compile "$BUNDLE" "$EXPIRES_AT" 4>&1; then
            ydk:throw 22 "Invalid compile"
            return 1
        fi
        ydk:log success "Build completed"
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
