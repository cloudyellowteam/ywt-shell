#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:bundle() {
    [[ -z "$YDK_BUILDER_DEFAULTS_EXPIRES_AT" ]] && local YDK_BUILDER_DEFAULTS_EXPIRES_AT="31/12/2999"
    validate() {
        local SRC_FILE=${1} && [ ! -f "$SRC_FILE" ] && jq -n --arg src "$SRC_FILE" '{"error": "Source file not found: \($src). Use ydk:bundle validate <package>.ydk.sh"}' && return 1
        [[ "$SRC_FILE" != *".cli.sh" ]] && [[ "$SRC_FILE" != *".ydk.sh" ]] && jq -n --arg src "$SRC_FILE" --arg ext "$FILE_EXT" '{"error": "Invalid package file extension \($ext): \($src). Use <package>.ydk.sh"}' && return 1
        local FILE_EXT="${SRC_FILE##*.}"
        [[ "$SRC_FILE" != *".sh" ]] && jq -n --arg src "$SRC_FILE" --arg ext "$FILE_EXT" '{"error": "Invalid source file extension \($ext): \($src). Use <package>.ydk.sh"}' && return 1
        if ! grep -q "^#!/usr/bin/env bash$" "$SRC_FILE"; then
            jq -n --arg src "$SRC_FILE" '{"error": "Invalid shebang in source file: \($src)"}'
            return 1
        fi

        local FILENAME=$(basename -- "$SRC_FILE") && FILENAME="${FILENAME%.*}" && FILENAME="${FILENAME%.*}" && [ -z "$FILENAME" ] && jq -n --arg src "$SRC_FILE" '{"error": "Invalid file name: \($src)"}' && return 1
        local BUNDLE_NAME="${2:-"${FILENAME}.sh"}" && [ -z "$BUNDLE_NAME" ] && jq -n --arg src "$SRC_FILE" '{"error": "Invalid bundle name: \($src)"}' && return 1
        local FILE_BASEPATH=$(dirname -- "$SRC_FILE")
        local FILE_REALPATH=$(realpath -- "$FILE_BASEPATH")
        local FILE_RELATIVEPATH=$(realpath --relative-to="$SRC_FILE" "$FILE_BASEPATH")
        local BUNDLES=(lib)
        for BUNDLE in "${BUNDLES[@]}"; do
            if [[ ! -d "${FILE_REALPATH}/${BUNDLE}" ]]; then
                jq -n --arg src "$SRC_FILE" --arg bundle "$BUNDLE" '{"error": "Bundle directory not found: \($src)/\($bundle)"}'
                return 1
            fi
        done
        jq -n \
            --arg src "$SRC_FILE" \
            --arg name "$FILENAME" \
            --arg bundle "$BUNDLE_NAME" \
            --arg basepath "$FILE_BASEPATH" \
            --arg realpath "$FILE_REALPATH" \
            --arg relativepath "$FILE_RELATIVEPATH" \
            --argjson lib "$({
                echo -n "["
                for FILE in $(
                    find "$FILE_REALPATH" \
                        -not -path "$FILE_REALPATH" \
                        -type f \
                        -name "*.ydk.sh" \
                        -not -name "*.cli.sh" |
                        sort
                ); do
                    echo -n "\"$FILE\","
                done | sed 's/,$//'
                echo -n "]"
            })" \
            --argjson bundles "$({
                echo -n "{"
                for BUNDLE in "${BUNDLES[@]}"; do
                    # \"${FILE_REALPATH}/${BUNDLE}\",
                    echo -n "\"$BUNDLE\": {"
                    echo -n "\"path\": \"${FILE_REALPATH}/${BUNDLE}\","
                    echo -n "\"name\": \"$BUNDLE\","
                    echo -n "\"files\": ["
                    for FILE in $(find "${FILE_REALPATH}/${BUNDLE}" -type f | sort); do
                        echo -n "\"$FILE\","
                    done | sed 's/,$//'
                    echo -n "]"
                    echo -n "},"
                done | sed 's/,$//'
                echo -n "}"
            })" \
            '{
                "source": $src,
                "name": $name, 
                "bundle": $bundle, 
                "basepath": $basepath, 
                "realpath": $realpath, 
                "relativepath": $relativepath,
                "bundles": $bundles,
                "lib": $lib
            }'
        return 0
    }
    bundle:santize() {
        local FILE="$1"
        [[ ! -f "$FILE" ]] && jq -n --arg src "$FILE" '{"error": "Source file not found: \($src). Use ydk:bundle validate <package>.ydk.sh"}' && return 1
        grep -v "^#" "$FILE" | grep -v "^[[:space:]]*#[^!]" | grep -v "^$" | grep -v "^#!/usr/bin/env bash$" | grep -v "^# shellcheck disable" | grep -v "^#" | sed -e 's/^/\t/'
    }
    copyright() {
        ydk:version | jq -cr '
                . |
                "Name: \(.name)",
                "Version: \(.version)",
                "Description: \(.description)",
                "Homepage: \(.homepage)",
                "License: \(.license)",
                "Repository: \(.repository.url)",
                "Author: \(.author.name) <\(.author.email)> \(.author.url)",
                "Build: \(.build.name)",
                "Build Date: \(.build.data)",
                "Release: \(.release.name)",
                "Release Date: \(.release.date)",
                "Commit: \(.commit)"                
            ' | while read -r LINE; do
            echo "# $LINE"
        done
    }
    pack() {
        local VALIDATION=$(validate "$@")
        if jq -e '.error' <<<"$VALIDATION" >/dev/null 2>&1; then
            ydk:log "ERROR" "Invalid bundle: $(jq -r '.error' <<<"$VALIDATION")"
            ydk:throw 251 "ERR" "Invalid bundle: $(jq -r '.error' <<<"$VALIDATION")"
            return 1
        fi
        local BUNDLE_ENTRYPOINT=$(jq -r '.source' <<<"$VALIDATION")
        local BUNDLE_TMP=$(ydk:temp "bundle")
        local BUNDLE_FILE="$(jq -r '.realpath' <<<"$VALIDATION")/$(jq -r '.bundle' <<<"$VALIDATION")"
        trap 'rm -rf "$BUNDLE_TMP"' EXIT
        echo "#!/bin/bash" >"$BUNDLE_TMP"
        {
            copyright
            local COPYRIGHT=$(ydk:version | jq -cr .)
            COPYRIGHT=${COPYRIGHT//\"/\\\"}

            local BUNDLE_NAME=$(jq -r '.name' <<<"$VALIDATION")
            if [[ "$BUNDLE_NAME" == "ydk" ]]; then 
                BUNDLE_NAME="cli"
            else
                BUNDLE_NAME="${BUNDLE_NAME}:addon"
            fi

            # echo "# Bundle: $BUNDLE_FILE"
            # echo "# Source: $(jq -r '.source' <<<"$VALIDATION")"
            # echo "# Basepath: $(jq -r '.basepath' <<<"$VALIDATION")"
            # echo "# Realpath: $(jq -r '.realpath' <<<"$VALIDATION")"
            # echo "# Relativepath: $(jq -r '.relativepath' <<<"$VALIDATION")"
            echo "# Created: $(date)"
            echo "# Version: $(date +%Y%m%d%H%M%S)"
            echo "# Builder: $(whoami | md5sum | cut -d' ' -f1)"
            echo "# shellcheck disable=SC2044,SC2155,SC2317"
            echo "ydk:${BUNDLE_NAME}(){"
            echo -e "\tset -e -o pipefail"
            echo -e "\texport YDK_VERSION_LOCK=\"$COPYRIGHT\" && readonly YDK_VERSION_LOCK"
            while read -r FILE; do
                # echo "# File: $FILE"
                bundle:santize "$FILE"
            done < <(jq -r '.bundles.lib.files[]' <<<"$VALIDATION")
            # echo "# Entrypoint: $BUNDLE_ENTRYPOINT"
            bundle:santize "$BUNDLE_ENTRYPOINT"
            echo -e "\tydk:try:nnf \"\$@\""
            echo -e "\treturn \$?"
            echo "}"
            if [[ "$BUNDLE_NAME" == "cli" ]]; then
                echo "ydk:${BUNDLE_NAME} \"\$@\""
                echo "exit \$?"
            else 
                curl -sSL https://raw.githubusercontent.com/cloudyellowteam/ywt-shell/main/packages/ydk/ydk.sh
                echo "# Added YDK CLI"
                # cat /workspace/rapd-shell/packages/ydk/ydk.sh
            fi 
            # ydk "$@" || YDK_STATUS=$? && YDK_STATUS=${YDK_STATUS:-0} && echo "done $YDK_STATUS" && exit "${YDK_STATUS:-0}"
            # echo "# End of bundle"
            copyright
        } >>"$BUNDLE_TMP"
        jq . <<<"$VALIDATION"
        cat "$BUNDLE_TMP" >"$BUNDLE_FILE"
        rm -f "$BUNDLE_TMP"
        # generate checksum
        local BUNDLE_CHECKSUM=$(ydk:checksum generate "$BUNDLE_FILE" "sha256")
        ydk:log "info" "Checksum: $BUNDLE_CHECKSUM"
        echo "$BUNDLE_CHECKSUM" >"$BUNDLE_FILE.checksum"
        # verify checksum
        if ! ydk:checksum verify "$BUNDLE_FILE" "$BUNDLE_CHECKSUM" "sha256"; then
            ydk:log "ERROR" "Checksum verification failed: $BUNDLE_FILE"
        else
            ydk:log "INFO" "Checksum verification passed: $BUNDLE_FILE"
        fi
        # chmod +x "$BUNDLE_FILE"
        # "$BUNDLE_FILE" -v
        return 0
    }
    compiler() {
        if ! command -v shc >/dev/null 2>&1; then
            echo "Compiler is not installed, trying install"
            # TODO: Add support for other package managers
            apt-get install shc -y >/dev/null 2>&1 && return 0
            return 1
        fi
        local EXPIRES_AT="${YDK_BUILDER_DEFAULTS_EXPIRES_AT}" && [ -z "$EXPIRES_AT" ] && EXPIRES_AT="31/12/2999"
        if [[ ! $EXPIRES_AT =~ ^([0-9]{2})/([0-9]{2})/([0-9]{4})$ ]]; then
            echo "Invalid date format: $EXPIRES_AT. Use dd/mm/yyyy."
            return 1
        fi
        IFS='/' read -r EXPIRES_AT_DAY EXPIRES_AT_MONTH EXPIRES_AT_YEAR <<<"$EXPIRES_AT"
        if ! date -d "$EXPIRES_AT_YEAR-$EXPIRES_AT_MONTH-$EXPIRES_AT_DAY" "+%Y-%m-%d" &>/dev/null; then
            echo "Error: Invalid date ${EXPIRES_AT}"
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
        shc -e "${EXPIRES_AT}" \
            -m "${EXPIRES_MESSAGE}" \
            "${SHC_ARGS[@]}"
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
    compile() {
        local FILE=$1 && [[ ! -f "$FILE" ]] && echo "$FILE is not a valid file" && return 0
        local EXPIRES_AT="${2}" && [ -z "$EXPIRES_AT" ] && EXPIRES_AT="31/12/2999"
        local FILE_DIR=$(dirname -- "$FILE") && readonly FILE_DIR
        local FILENAME && FILENAME=$(basename -- "$FILE") && FILENAME="${FILENAME%.*}" && FILENAME="${FILENAME%.*}" && [ -z "$FILENAME" ] && echo "Invalid file name: $FILE" && return 1
        ydk:log "info" "Compiling $FILE, expires at $EXPIRES_AT"
        [[ -f "${FILE_DIR}/${FILENAME}.bin" ]] && rm -f "${FILE_DIR}/${FILENAME}.bin"
        [[ -f "${FILE_DIR}/${FILENAME}.sh.x.c" ]] && rm -f "${FILE_DIR}/${FILENAME}.sh.x.c"
        compiler -r \
            -f "${FILE}" \
            -e "${EXPIRES_AT}" \
            -o "${FILE_DIR}/${FILENAME}.bin"
        local BUILD_STATUS=$?
        if [[ $BUILD_STATUS -eq 0 ]]; then
            ydk:log "info" "File compiled successfully: ${FILE_DIR}/${FILENAME}.bin"
            ydk:log "info" "Run ${FILE_DIR}/${FILENAME}.bin process inspect | jq ."
            return "$BUILD_STATUS"
        else
            ydk:log "Error" "File compilation failed: ${FILE_DIR}/${FILENAME}.bin"
            return 1
        fi
    }
    build() {
        local FILE=$1 && [[ ! -f "$FILE" ]] && echo "$FILE is not a valid file" && return 0
        local EXPIRES_AT="${2:-$YDK_BUILDER_DEFAULTS_EXPIRES_AT}" && [ -z "$EXPIRES_AT" ] && EXPIRES_AT="31/12/2999"
        local BUNDLE=$(pack "$FILE")
        local BUNDLE_FILE=$(jq -r '.realpath' <<<"$BUNDLE")/$(jq -r '.bundle' <<<"$BUNDLE")
        compile "$BUNDLE_FILE" "$EXPIRES_AT"
        return $?
    }
    ydk:try:nnf "$@"
    return $?
}
