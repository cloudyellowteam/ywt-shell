#!/bin/bash
# Name: @ywteam/ydk-shell
# Version: 0.0.0-dev-0
# Description: Cloud Yellow Team | Shell SDK
# Homepage: https://yellowteam.cloud
# License: MIT
# Repository: https://github.com/ywteam/ydk-shell.git
# Author: Raphael Rego <hello@raphaelcarlosr.dev> https://raphaelcarlosr.dev
# Build: ydk-shell
# Build Date: null
# Release: ydk-shell
# Release Date: 2024-04-15T21:36:03+00:00
# Commit: {"id":"c61263f","hash":"c61263f98e365865def7d11cedd3e00078def45f","branch":"main","tag":"0.0.0-alpha-0-4-gc61263f","message":"Update ydk.cli.sh and bundle.ydk.sh scripts, and fix bundle.ydk.sh script"}
# Created: Mon Apr 15 21:36:03 UTC 2024
# Version: 20240415213603
# Builder: 74cc1c60799e0a786ac7094b532f01b1
# shellcheck disable=SC2044,SC2155,SC2317
ydk:cli(){
	set -e -o pipefail
	export YDK_VERSION_LOCK="{\"name\":\"@ywteam/ydk-shell\",\"version\":\"0.0.0-dev-0\",\"description\":\"Cloud Yellow Team | Shell SDK\",\"homepage\":\"https://yellowteam.cloud\",\"license\":\"MIT\",\"repository\":{\"type\":\"git\",\"url\":\"https://github.com/ywteam/ydk-shell.git\",\"branch\":\"main\"},\"bugs\":{\"url\":\"https://bugs.yellowteam.cloud\"},\"author\":{\"name\":\"Raphael Rego\",\"email\":\"hello@raphaelcarlosr.dev\",\"url\":\"https://raphaelcarlosr.dev\"},\"build\":{\"name\":\"ydk-shell\",\"date\":\"2024-04-15T21:36:03+00:00\"},\"release\":{\"name\":\"ydk-shell\",\"date\":\"2024-04-15T21:36:03+00:00\"},\"commit\":{\"id\":\"c61263f\",\"hash\":\"c61263f98e365865def7d11cedd3e00078def45f\",\"branch\":\"main\",\"tag\":\"0.0.0-alpha-0-4-gc61263f\",\"message\":\"Update ydk.cli.sh and bundle.ydk.sh scripts, and fix bundle.ydk.sh script\"}}" && readonly YDK_VERSION_LOCK
	ydk:is() {
	    case "$1" in
	    not-defined)
	        [ -z "$2" ] && return 0
	        [ "$2" == "null" ] && return 0
	        ;;
	    defined)
	        [ -n "$2" ] && return 0
	        [ "$2" != "null" ] && return 0
	        ;;
	    rw)
	        [ -r "$2" ] && [ -w "$2" ] && return 0
	        ;;
	    owner)
	        [ -O "$2" ] && return 0
	        ;;
	    writable)
	        [ -w "$2" ] && return 0
	        ;;
	    readable)
	        [ -r "$2" ] && return 0
	        ;;
	    executable)
	        [ -x "$2" ] && return 0
	        ;;
	    nil)
	        [ -z "$2" ] && return 0
	        [ "$2" == "null" ] && return 0
	        ;;
	    number)
	        [ -n "$2" ] && [[ "$2" =~ ^[0-9]+$ ]] && return 0
	        ;;
	    string)
	        [ -n "$2" ] && [[ "$2" =~ ^[a-zA-Z0-9_]+$ ]] && return 0
	        ;;
	    boolean)
	        [ -n "$2" ] && [[ "$2" =~ ^(true|false)$ ]] && return 0
	        ;;
	    date)
	        [ -n "$2" ] && [[ "$2" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && return 0
	        ;;
	    url)
	        [ -n "$2" ] && [[ "$2" =~ ^https?:// ]] && return 0
	        ;;
	    json)
	        jq -e . <<<"$2" >/dev/null 2>&1 && return 0
	        ;;
	    fnc | function)
	        type -t "$2" >/dev/null 2>&1 && return 0
	        ;;
	    cmd | command)
	        command -v "$2" >/dev/null 2>&1 && return 0
	        ;;
	    f | file)
	        [ -f "$2" ] && return 0
	        ;;
	    d | dir)
	        [ -d "$2" ] && return 0
	        ;;
	    esac
	    return 1
	}
	ydk:nnf() {
	    local IOC_TARGET=${1} && shift && [ -z "$IOC_TARGET" ] && return 1
	    IOC_TARGET=${IOC_TARGET#_} && IOC_TARGET=${IOC_TARGET#__} && IOC_TARGET="${IOC_TARGET//_/-5f}" && IOC_TARGET="${IOC_TARGET//-/-2d}" && IOC_TARGET="${IOC_TARGET// /_}"
	    local IOC_ARGS=("$@")
	    local START_TIME=$(date +%s)
	    ydk:is function "ydk:$IOC_TARGET" && IOC_TARGET="ydk:$IOC_TARGET"
	    ! ydk:is function "$IOC_TARGET" && return 1
	    exec 3>&1
	    trap 'exec 3>&-' EXIT
	    local IOC_STATUS
	    $IOC_TARGET "${IOC_ARGS[@]}" 1>&3 2>&3
	    IOC_STATUS=$? && [ -z "$IOC_STATUS" ] && IOC_STATUS=1
	    local END_TIME=$(date +%s)
	    local ELAPSED_TIME=$((END_TIME - START_TIME))
	    if [ -n "$IOC_STATUS" ] && [ "$IOC_STATUS" -eq 0 ]; then
	        local IOC_RESULT="SUCCESS"        
	    else
	        local IOC_RESULT="FAILED"
	    fi
	    exec 3>&-
	    return $IOC_STATUS
	}
	ydk:argv() {
	    values() {
	        [ -n "$YDK_ARGV" ] && echo "$YDK_ARGV" | jq -c . && return 0
	        YDK_POSITIONAL=()
	        export YDK_ARGV=$(
	            {
	                local JSON="{" && local FIRST=true
	                while [[ $# -gt 0 ]]; do
	                    local FLAG="$1"
	                    [[ "$FLAG" != --* ]] && [[ "$FLAG" != -* ]] && YDK_POSITIONAL+=("$1") && shift && continue
	                    local KEY=${FLAG#--} && KEY=${KEY#-} && KEY=${KEY%%=*} && KEY=${KEY%%:*}
	                    local VALUE=${FLAG#*=} && VALUE=${VALUE#*:} && VALUE=${VALUE#*=} && VALUE=${VALUE#--} && VALUE=${VALUE#-}
	                    [[ "$KEY" == "$VALUE" ]] && VALUE=true
	                    [[ -z "$VALUE" ]] && VALUE=true
	                    [[ "$VALUE" != true ]] && [[ "$VALUE" != false ]] && [[ "$VALUE" =~ ^[0-9]+$ ]] && VALUE="\"$VALUE\""
	                    [ "$FIRST" == true ] && FIRST=false || JSON+=","
	                    JSON+="\"$KEY\":\"$VALUE\"" && shift
	                done
	                JSON+="}"
	                echo "$JSON"
	            }
	        ) && readonly YDK_ARGV
	        echo "$YDK_ARGV" | jq -rc .
	        return 0
	    }
	    form() {
	        [ -n "$YDK_FORM" ] && echo "$YDK_FORM" | jq -c . && return 0
	        YDK_POSITIONAL=()
	        export YDK_FORM=$({
	            local JSON="{" && local FIRST=true
	            while [[ $# -gt 0 ]]; do
	                local PARAM="$1"
	                [[ "$PARAM" != kv=* ]] && YDK_POSITIONAL+=("$1") && shift && continue
	                local KEY=${PARAM#kv=}
	                local VALUE=${KEY#*:} && VALUE=${VALUE#*:} && VALUE=${VALUE#=}
	                KEY=${KEY%%:*}
	                [ "$KEY" == "$VALUE" ] && VALUE=true
	                [ -z "$VALUE" ] && VALUE=true
	                [ "$FIRST" == true ] && FIRST=false || JSON+=","
	                JSON+="\"$KEY\":\"$VALUE\"" && shift
	            done
	            JSON+="}"
	            echo "$JSON"
	        }) && readonly YDK_FORM
	        echo "$YDK_FORM" | jq -c .
	    }
	    flags() {
	        YDK_POSITIONAL=()
	        YDK_FLAGS=$(jq -n '{ "quiet": false, "trace": null, "logger": null, "debug": null, "output": null }')
	        while [[ $# -gt 0 ]]; do
	            case "$1" in
	            -q | --quiet)
	                export YDK_QUIET=true #&& readonly YDK_QUIET
	                YDK_FLAGS=$(jq -n --argjson flags "$YDK_FLAGS" --arg quiet true '$flags | .quiet=$quiet')
	                shift
	                ;;
	            -t | --trace)
	                local VALUE=$(jq -r '.trace' <<<"$YDK_FLAGS")
	                [ "$VALUE" == "null" ] && shift && continue
	                [ "$VALUE" == true ] && VALUE="/tmp/ywt.trace"
	                [ -p "$VALUE" ] && rm -f "$VALUE"
	                export YDK_TRACE_FIFO="$VALUE"
	                [ ! -p "$YDK_TRACE_FIFO" ] && mkfifo "$YDK_TRACE_FIFO" #&& readonly YDK_TRACE_FIFO
	                YDK_LOGS+=("Trace FIFO enabled. In another terminal use 'tail -f $YDK_TRACE_FIFO' to watch logs or 'rapd debugger trace watch $YDK_TRACE_FIFO'.")
	                YDK_FLAGS=$(jq -n --argjson flags "$YDK_FLAGS" --arg trace "$VALUE" '$flags | .trace=$trace')
	                shift
	                ;;
	            -l | --logger)
	                local VALUE=$(jq -r '.logger' <<<"$YDK_FLAGS")
	                [ "$VALUE" == "null" ] && shift && continue
	                [ "$VALUE" == true ] && VALUE="/tmp/ywt.logger"
	                [ -p "$YDK_LOGGER_FIFO" ] && rm -f "$YDK_LOGGER_FIFO"
	                export YDK_LOGGER_FIFO="$VALUE"
	                [ ! -p "$YDK_LOGGER_FIFO" ] && mkfifo "$YDK_LOGGER_FIFO" #&& readonly YDK_LOGGER_FIFO
	                YDK_LOGS+=("Logger FIFO enabled. In another terminal use 'tail -f $YDK_LOGGER_FIFO' to watch logs or 'rapd logger watch $YDK_LOGGER_FIFO'.")
	                YDK_FLAGS=$(jq -n --argjson flags "$YDK_FLAGS" --arg logger "$VALUE" '$flags | .logger=$logger')
	                shift
	                ;;
	            -d | --debug)
	                [ "$YDK_DEBUG" == true ] && shift && continue
	                YDK_DEBUG=true && #readonly YDK_DEBUG
	                    local VALUE=$(jq -r '.debug' <<<"$YDK_FLAGS")
	                [ "$VALUE" == "null" ] && shift && continue
	                [ "$VALUE" == true ] && VALUE="/tmp/ywt.debugger"
	                [ -p "$YDK_DEBUG_FIFO" ] && rm -f "$YDK_DEBUG_FIFO"
	                export YDK_DEBUG_FIFO="$VALUE"
	                [ ! -p "$YDK_DEBUG_FIFO" ] && mkfifo "$YDK_DEBUG_FIFO" #&& readonly YDK_DEBUG_FIFO
	                YDK_LOGS+=("Debug enabled. In another terminal use 'tail -f $YDK_DEBUG_FIFO' to watch logs or 'rapd debugger watch $YDK_DEBUG_FIFO'.")
	                YDK_FLAGS=$(jq -n --argjson flags "$YDK_FLAGS" --arg debug "$VALUE" '$flags | .debug=$debug')
	                shift
	                ;;
	            -o | --output)
	                local VALUE=$(jq -r '.output' <<<"$YDK_FLAGS")
	                [ "$VALUE" == "null" ] && shift && continue
	                [ "$VALUE" == true ] && VALUE="/tmp/ywt.output"
	                [ -p "$VALUE" ] && rm -f "$VALUE"
	                export YDK_OUTPUT_FIFO="$VALUE"
	                [ ! -p "$YDK_OUTPUT_FIFO" ] && mkfifo "$YDK_OUTPUT_FIFO" #&& readonly YDK_OUTPUT_FIFO
	                YDK_LOGS+=("Output FIFO enabled. In another terminal use 'tail -f $YDK_OUTPUT_FIFO' to watch logs or 'rapd output watch $YDK_OUTPUT_FIFO'.")
	                YDK_FLAGS=$(jq -n --argjson flags "$YDK_FLAGS" --arg output "$VALUE" '$flags | .output=$output')
	                shift
	                ;;
	            -p* | --param*)
	                YDK_POSITIONAL+=("$1")
	                shift
	                ;;
	            *)
	                YDK_POSITIONAL+=("$1")
	                shift
	                ;;
	            esac
	        done
	        export YDK_FLAGS      # && readonly YDK_FLAGS
	        set -- "${YDK_POSITIONAL[@]}"
	        return 0
	    }
	    ydk:try:nnf "$@"
	    return $?
	}
	ydk:assets() {
	    local YDK_USERNAME="cloudyellowteam"
	    local YDK_REPO_NAME="ywt-shell"
	    local YDK_REPO_BRANCH="main"
	    local YDK_REPO_URL="https://github.com/${YDK_USERNAME}/${YDK_REPO_NAME}"
	    local YDK_REPO_RAW_URL="https://raw.githubusercontent.com/${YDK_USERNAME}/${YDK_REPO_NAME}/${YDK_REPO_BRANCH}"
	    download(){
	        local YDK_ASSET_PATH="${1}"
	        local YDK_ASSET_URL="${YDK_REPO_RAW_URL}/${YDK_ASSET_PATH}"
	        local YDK_ASSET_FILE=$(basename -- "$YDK_ASSET_PATH")
	        local YDK_ASSET_TMP=$(ydk:temp "download")
	        trap 'rm -f "${YDK_ASSET_TMP}" >/dev/null 2>&1' EXIT
	        if [[ -f "${YDK_ASSET_FILE}" ]]; then
	            ydk:log "INFO" "Asset already exists: ${YDK_ASSET_FILE}"
	            return 0
	        fi
	        ydk:log "INFO" "Downloading asset from ${YDK_ASSET_URL}"
	        if ! curl -sSL -o "${YDK_ASSET_TMP}" "${YDK_ASSET_URL}"; then
	            ydk:log "ERROR" "Failed to download asset from ${YDK_ASSET_URL}"
	            return 1
	        fi
	        mv "${YDK_ASSET_TMP}" "${YDK_ASSET_FILE}"
	        return $?
	    }    
	    ydk:try:nnf "$@"
	    return $?
	}
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
	            echo "# Created: $(date)"
	            echo "# Version: $(date +%Y%m%d%H%M%S)"
	            echo "# Builder: $(whoami | md5sum | cut -d' ' -f1)"
	            echo "# shellcheck disable=SC2044,SC2155,SC2317"
	            echo "ydk:${BUNDLE_NAME}(){"
	            echo -e "\tset -e -o pipefail"
	            echo -e "\texport YDK_VERSION_LOCK=\"$COPYRIGHT\" && readonly YDK_VERSION_LOCK"
	            while read -r FILE; do
	                bundle:santize "$FILE"
	            done < <(jq -r '.bundles.lib.files[]' <<<"$VALIDATION")
	            bundle:santize "$BUNDLE_ENTRYPOINT"
	            echo -e "\tydk:try:nnf \"\$@\""
	            echo -e "\treturn \$?"
	            echo "}"
	            if [[ "$BUNDLE_NAME" == "cli" ]]; then
	                echo "ydk:${BUNDLE_NAME} \"\$@\""
	                echo "exit \$?"
	            else 
	                curl -sSL https://raw.githubusercontent.com/cloudyellowteam/ywt-shell/main/packages/ydk/ydk.sh
	            fi 
	            copyright
	        } >>"$BUNDLE_TMP"
	        jq . <<<"$VALIDATION"
	        cat "$BUNDLE_TMP" >"$BUNDLE_FILE"
	        rm -f "$BUNDLE_TMP"
	        local BUNDLE_CHECKSUM=$(ydk:checksum generate "$BUNDLE_FILE" "sha256")
	        ydk:log "info" "Checksum: $BUNDLE_CHECKSUM"
	        echo "$BUNDLE_CHECKSUM" >"$BUNDLE_FILE.checksum"
	        if ! ydk:checksum verify "$BUNDLE_FILE" "$BUNDLE_CHECKSUM" "sha256"; then
	            ydk:log "ERROR" "Checksum verification failed: $BUNDLE_FILE"
	        else
	            ydk:log "INFO" "Checksum verification passed: $BUNDLE_FILE"
	        fi
	        return 0
	    }
	    compiler() {
	        if ! command -v shc >/dev/null 2>&1; then
	            echo "Compiler is not installed, trying install"
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
	        ${HASH_CMD} "${FILE}" | awk '{print $1}'
	        return $?
	    }
	    generate() {
	        local FILE=${1} && [ ! -f "$FILE" ] && echo "File not found: $FILE" && return 1
	        local HASH=${2:-"sha256"}
	        hash "${HASH}" "${FILE}"
	    }
	    verify(){
	        local FILE=${1} && [ ! -f "$FILE" ] && echo "File not found: $FILE" && return 1
	        local HASH=${2} && [ -z "$HASH" ] && echo "Hash not found" && return 1
	        local HASH_TYPE=${3:-"sha256"}
	        local FILE_HASH=$(hash "${HASH_TYPE}" "${FILE}")
	        [ "$FILE_HASH" == "$HASH" ] && return 0
	        echo "Hash mismatch: $FILE_HASH != $HASH"
	        return 1        
	    }
	    ydk:try:nnf "$@"
	    return $?
	}
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
	ydk:installer() {
	    install() {
	        local YDK_BINARY_PATH=/usr/local/bin
	        local YDK_INSTALL_PATH="/ywteam/ydk-shell"
	        local YDK_LOGS_PATH="/var/log/ywteam/ydk-shell"
	        local YDK_CACHE_PATH="/var/cache/ywteam/ydk-shell"
	        local YDK_DATA_PATH="/var/lib/ywteam/ydk-shell"
	        local YDK_CONFIG_PATH="/etc/ywteam/ydk-shell"
	        local YDK_RUNTIME_PATH="/opt/ywteam/ydk-shell"
	        local YDK_CACHE_PATH="/var/cache/ywteam/ydk-shell"
	        while [[ $# -gt 0 ]]; do
	            case "$1" in
	            -h | --help)
	                shift
	                ydk:usage 0 "ydk" "install" "usage"
	                exit 0
	                ;;
	            -p | --path)
	                YDK_INSTALL_PATH="${1}"
	                shift
	                ;;
	            -l | --logs)
	                YDK_LOGS_PATH="${1}"
	                shift
	                ;;
	            -c | --cache)
	                YDK_CACHE_PATH="${1}"
	                shift
	                ;;
	            -d | --data)
	                YDK_DATA_PATH="${1}"
	                shift
	                ;;
	            -r | --runtime)
	                YDK_RUNTIME_PATH="${1}"
	                shift
	                ;;
	            -C | --config)
	                YDK_CONFIG_PATH="${1}"
	                shift
	                ;;
	            -b | --binary)
	                YDK_BINARY_PATH="${1}"
	                shift
	                ;;
	            *)
	                echo "Unknown option: $1"
	                shift
	                ;;
	            esac
	        done
	        [[ ! -d "$YDK_BINARY_PATH" ]] && echo "Binary path not found: $YDK_BINARY_PATH. Use -b or --binary to set valid one" && exit 254
	        local YDK_PATH="${YDK_BINARY_PATH}/${YDK_INSTALL_PATH}" && YDK_PATH=${YDK_PATH//\/\//\/}
	        local YDK_TMP=$(ydk:temp "install")
	        trap 'rm -f "${YDK_TMP}" >/dev/null 2>&1' EXIT
	        ydk:log "INFO" "Installing required packages into ${YDK_PATH}"
	        ! ydk:require "${YDK_DEPENDENCIES[@]}" && {
	            apk add --update
	            apk add --no-cache bash jq git parallel
	            apk add --no-cache curl ca-certificates openssl ncurses coreutils python2 make gcc g++ libgcc linux-headers grep util-linux binutils findutils
	            rm -rf /var/cache/apk/* /root/.npm /tmp/*
	        } >"$YDK_TMP" # >/dev/null 2>&1
	        ydk:log "INFO" "Packages installed, verifying dependencies"
	        ! ydk:require "${YDK_DEPENDENCIES[@]}" && {
	            echo "Failed to install required packages"
	            ydk:throw 255 "ERR" "Failed to install required packages"
	        }        
	        ydk:log "INFO" "Packages installed, verifying dependencies"
	        ydk:require "${YDK_DEPENDENCIES[@]}"
	        ydk:log "INFO" "Done, Getting version info"
	        {
	            for DEPENDENCY in "${YDK_DEPENDENCIES[@]}"; do
	                echo -n "{"
	                echo -n "\"name\": \"${DEPENDENCY}\","
	                if command -v "$DEPENDENCY" >/dev/null 2>&1; then
	                    echo -n "\"path\": \"$(command -v "$DEPENDENCY")\","
	                    case "$DEPENDENCY" in
	                    awk)
	                        local VERSION="$("$DEPENDENCY" -W version 2>&1)"
	                        ;;
	                    curl)
	                        local VERSION="$("$DEPENDENCY" -V 2>&1 | head -n 1 | grep -oE "[0-9]+\.[0-9]+\.[0-9]+")"
	                        ;;
	                    *)
	                        if "$DEPENDENCY" --version >/dev/null 2>&1; then
	                            local VERSION="$("$DEPENDENCY" --version 2>&1)"
	                        elif "$DEPENDENCY" version >/dev/null 2>&1; then
	                            local VERSION="$("$DEPENDENCY" version 2>&1)"
	                        else
	                            local VERSION="null"
	                        fi
	                        ;;
	                    esac
	                    VERSION=${VERSION//\"/\\\"}
	                    VERSION=$(echo "$VERSION" | head -n 1)
	                    echo -n "\"version\": \"$VERSION\""
	                else
	                    echo -n "\"path\": \"null\""
	                fi
	                echo -n "}"
	            done
	        } | jq -cs '
	            . |
	            {
	                "dependencies": .,
	                "install": {
	                    "path": "'"${YDK_PATH}"'",
	                    "logs": "'"${YDK_LOGS_PATH}"'",
	                    "cache": "'"${YDK_CACHE_PATH}"'",
	                    "data": "'"${YDK_DATA_PATH}"'",
	                    "config": "'"${YDK_CONFIG_PATH}"'",
	                    "runtime": "'"${YDK_RUNTIME_PATH}"'"
	                }
	            }
	        ' >"$YDK_TMP" #'.' >/dev/null 2>&1
	        while read -r DEPENDENCY; do
	            local DEPENDENCY_NAME=$(jq -r '.name' <<<"${DEPENDENCY}")
	            local DEPENDENCY_PATH=$(jq -r '.path' <<<"${DEPENDENCY}")
	            local DEPENDENCY_VERSION=$(jq -r '.version' <<<"${DEPENDENCY}")
	            if command -v "$DEPENDENCY_NAME" >/dev/null 2>&1; then
	                continue
	            fi
	            if [ "$DEPENDENCY_PATH" == "null" ]; then
	                ydk:log "INFO" "Dependency not found: $DEPENDENCY_NAME"
	                ydk:throw 253 "ERR" "Dependency not found: $DEPENDENCY_NAME"
	            fi
	            if [ "$DEPENDENCY_VERSION" == "null" ]; then
	                ydk:log "INFO" "Dependency version not found: $DEPENDENCY_NAME"
	                ydk:throw 252 "ERR" "Dependency version not found: $DEPENDENCY_NAME"
	            fi
	        done < <(jq -c '
	            .dependencies[] |
	            select(
	                .version != "null" or
	                .path != "null"
	            ) |
	            {
	                "name": .name,
	                "path": .path,
	                "version": .version
	            } |
	            reduce . as $item (
	                {};
	                .[$item.name] = $item
	            ) |
	            .[]
	        ' "$YDK_TMP")
	        {
	            echo -e "Name\tVersion\tPath"
	            jq -cr '
	            .dependencies[] |
	            [
	                .name,
	                .version,
	                .path
	            ] | @tsv
	        ' "$YDK_TMP"
	        } | column -t -s $'\t'
	        jq '
	            . |
	            .install.path as $path |
	            .install.logs as $logs |
	            .install.cache as $cache |
	            .install.data as $data |
	            .install.config as $config |
	            .install.runtime as $runtime |
	            .dependencies | length as $total |
	            {
	                "deps": $total,
	                "path": {
	                    "bin": $path,
	                    "logs": $logs,
	                    "cache": $cache,
	                    "data": $data,
	                    "config": $config,
	                    "runtime": $runtime
	                }
	            }
	        ' "$YDK_TMP"
	        rm -f "${YDK_TMP}"
	        ydk welcome
	    }
	    ydk:try:nnf "$@"
	    return $?
	}
	ydk:process() {
	    etime() {
	        if grep -q 'Alpine' /etc/os-release; then
	            ps -o etime= "$$" | awk -F "[:]" '{ print ($1 * 60) + $2 }' | head -n 1
	        else
	            ps -o etime= -p "$$" | sed -e 's/^[[:space:]]*//' | sed -e 's/\://' | head -n 1
	        fi
	    }
	    stdin() {
	        [ ! -p /dev/stdin ] && [ ! -t 0 ] && return "$1"
	        while IFS= read -r INPUT; do
	            echo "$INPUT"
	        done
	        unset INPUT
	    }
	    stdout() {
	        [ ! -p /dev/stdout ] && [ ! -t 1 ] && return "$1"
	        while IFS= read -r OUTPUT; do
	            echo "$OUTPUT"
	        done
	        unset OUTPUT
	    }
	    stderr() {
	        [ ! -p /dev/stderr ] && [ ! -t 2 ] && return "$1"
	        while IFS= read -r ERROR; do
	            echo "$ERROR" >&2
	        done
	        unset ERROR
	    }
	    inspect(){
	        jq -cn \
	            --arg pid "$$" \
	            --arg etime "$(etime)" \
	            --argjson cli "$(ydk:cli)" \
	            --argjson package "$(ydk:version)" \
	            '{ 
	                pid: $pid,
	                etime: $etime,
	                cli: $cli,
	                package: $package
	            }'
	    }
	    ydk:try:nnf "$@"
	    return $?
	}
	ydk:strings() {
	    echo "strings"
	    return 0
	}
	YDK_CLI_ENTRYPOINT="${0}" && readonly YDK_CLI_ENTRYPOINT
	YDK_CLI_ARGS=("$@")
	ydk() {
	    set -e -o pipefail
	    local YDK_INITIALIZED=false
	    local YDK_POSITIONAL=()
	    local YDK_DEPENDENCIES=("jq" "curl" "sed" "awk" "tr" "sort" "basename" "dirname" "mktemp" "openssl" "column")
	    local YDK_MISSING_DEPENDENCIES=()
	    ydk:log() {
	        local YDK_LOG_LEVEL="${1:-"INFO"}"
	        local YDK_LOG_MESSAGE="${2:-""}"
	        local YDK_LOG_TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
	        echo "[YDK][$YDK_LOG_TIMESTAMP] ${YDK_LOG_LEVEL^^}: $YDK_LOG_MESSAGE" 1>&2
	    }
	    ydk:require() {
	        for DEPENDENCY in "${@}"; do
	            ! echo "${YDK_DEPENDENCIES[*]}" | grep -q "${DEPENDENCY}" >/dev/null 2>&1 && YDK_DEPENDENCIES+=("${DEPENDENCY}")
	            if ! command -v "$DEPENDENCY" >/dev/null 2>&1; then
	                YDK_MISSING_DEPENDENCIES+=("${DEPENDENCY}")
	            fi
	        done
	        [ "${#YDK_MISSING_DEPENDENCIES[@]}" -eq 0 ] && return 0
	        {
	            echo -n "{"
	            echo -n "\"error\": \"missing ${#YDK_MISSING_DEPENDENCIES[@]} dependencies\","
	            echo -n "\"dependencies\": ["
	            for MISSING_DEPENDENCY in "${YDK_MISSING_DEPENDENCIES[@]}"; do
	                echo -n "\"${MISSING_DEPENDENCY}\","
	            done | sed 's/,$//'
	            echo -n "]"
	            echo -n "}"
	        } | jq -c .
	        return 1
	    }
	    ydk:cli() {
	        YDK_RUNTIME_ENTRYPOINT="$YDK_CLI_ENTRYPOINT"
	        YDK_RUNTIME_ENTRYPOINT_NAME=$(basename "${YDK_RUNTIME_ENTRYPOINT}")
	        YDK_RUNTIME_IS_CLI=false
	        [[ "${YDK_RUNTIME_ENTRYPOINT_NAME}" == *".cli.sh" ]] && YDK_RUNTIME_IS_CLI=true
	        YDK_RUNTIME_NAME="${YDK_RUNTIME_ENTRYPOINT_NAME//.cli.sh/}"
	        YDK_RUNTIME_DIR=$(cd "$(dirname "${YDK_RUNTIME_ENTRYPOINT}")" && pwd)
	        YDK_RUNTIME_VERSION="0.0.0-dev-0"
	        [ -f "${YDK_RUNTIME_DIR}/package.json" ] && {
	            YDK_RUNTIME_VERSION=$(jq -r '.version' "${YDK_RUNTIME_DIR}/package.json")
	        } || [ -f "${YDK_RUNTIME_DIR}/VERSION" ] && {
	            YDK_RUNTIME_VERSION=$(cat "./VERSION")
	        }
	        YDK_RUNTIME_IS_BINARY=false
	        if [ -f "${YDK_RUNTIME_ENTRYPOINT}" ]; then
	            if command -v file >/dev/null 2>&1; then
	                file "${YDK_RUNTIME_ENTRYPOINT}" | grep -q "ELF" && YDK_RUNTIME_IS_BINARY=true
	            elif [[ "${BASH_SOURCE[0]}" == "environment" ]]; then
	                YDK_RUNTIME_IS_BINARY=true
	            else
	                YDK_RUNTIME_IS_BINARY=false
	            fi
	        fi
	        echo -n "{"
	        echo -n "\"file\": \"${YDK_RUNTIME_ENTRYPOINT_NAME}\","
	        echo -n "\"cli\": ${YDK_RUNTIME_IS_CLI},"
	        echo -n "\"binary\": ${YDK_RUNTIME_IS_BINARY},"
	        echo -n "\"sources\": ["
	        for YDK_BASH_SOURCE in "${BASH_SOURCE[@]}"; do
	            YDK_BASH_SOURCE=${YDK_BASH_SOURCE//\"/\\\"}
	            echo -n "\"${YDK_BASH_SOURCE}\","
	        done | sed 's/,$//'
	        echo -n "],"
	        echo -n "\"name\": \"${YDK_RUNTIME_NAME}\","
	        echo -n "\"entrypoint\": \"${YDK_RUNTIME_ENTRYPOINT}\","
	        echo -n "\"path\": \"${YDK_RUNTIME_DIR}\","
	        echo -n "\"args\": ["
	        for YDK_CLI_ARG in "${YDK_CLI_ARGS[@]}"; do
	            YDK_CLI_ARG=${YDK_CLI_ARG//\"/\\\"}
	            echo -n "\"${YDK_CLI_ARG}\","
	        done | sed 's/,$//'
	        echo -n "],"
	        echo -n "\"version\": \"${YDK_RUNTIME_VERSION:-"0.0.0-local-0"}\""
	        echo -n "}"
	    }
	    ydk:version() {
	        ydk:require "jq"
	        local YDK_REPO_OWNER="ywteam"
	        local YDK_REPO_NAME="ydk-shell"
	        local YDK_REPO_BRANCH="main"
	        local YDK_RUNTIME_VERSION="0.0.0-dev-0"
	        [ -f "${YDK_RUNTIME_DIR}/package.json" ] && {
	            YDK_RUNTIME_VERSION=$(jq -r '.version' "${YDK_RUNTIME_DIR}/package.json")
	        } || [ -f "${YDK_RUNTIME_DIR}/VERSION" ] && {
	            YDK_RUNTIME_VERSION=$(cat "./VERSION")
	        }
	        echo -n "{"
	        echo -n '"name": "@ywteam/ydk-shell",'
	        echo -n "\"version\": \"${YDK_RUNTIME_VERSION:-"0.0.0-local-0"}\","
	        echo -n '"description": "Cloud Yellow Team | Shell SDK",'
	        echo -n '"homepage": "https://yellowteam.cloud",'
	        echo -n '"license": "MIT",'
	        echo -n '"repository": {'
	        echo -n "   \"type\": \"git\","
	        echo -n "   \"url\": \"https://github.com/${YDK_REPO_OWNER}/${YDK_REPO_NAME}.git\","
	        echo -n "   \"branch\": \"${YDK_REPO_BRANCH}\""
	        echo -n "},"
	        echo -n "\"bugs\": {"
	        echo -n "   \"url\": \"https://bugs.yellowteam.cloud\""
	        echo -n "},"
	        echo -n "\"author\": {"
	        echo -n "   \"name\": \"Raphael Rego\","
	        echo -n "   \"email\": \"hello@raphaelcarlosr.dev\","
	        echo -n "   \"url\": \"https://raphaelcarlosr.dev\""
	        echo -n "},"
	        echo -n "\"build\": {"
	        echo -n "   \"name\": \"ydk-shell\","
	        echo -n "   \"date\": \"$(date -Iseconds)\""
	        echo -n "},"
	        echo -n "\"release\": {"
	        echo -n "   \"name\": \"ydk-shell\","
	        echo -n "   \"date\": \"$(date -Iseconds)\""
	        echo -n "},"
	        echo -n "\"commit\": {"
	        echo -n "   \"id\": \"$(git rev-parse --short HEAD 2>/dev/null || echo "Unknown")\","
	        echo -n "   \"hash\": \"$(git rev-parse HEAD 2>/dev/null || echo "Unknown")\","
	        echo -n "   \"branch\": \"$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "Unknown")\","
	        echo -n "   \"tag\": \"$(git describe --tags 2>/dev/null || echo "Unknown")\","
	        echo -n "   \"message\": \"$(git log -1 --pretty=format:'%s' 2>/dev/null || echo "Unknown")\""
	        echo -n "}"
	        echo -n "}"
	        echo
	    }
	    ydk:teardown() {
	        local YDK_EXIT_CODE="${1:-$?}"
	        local YDK_EXIT_MESSAGE="${2:-"exit with: ${YDK_EXIT_CODE}"}"
	        local YDK_BUGS_REPORT=$(ydk:version | jq -r '.bugs.url') && [ "$YDK_BUGS_REPORT" == "null" ] && YDK_BUGS_REPORT="https://bugs.yellowteam.cloud"
	        if [ "${YDK_EXIT_CODE}" -ne 0 ]; then
	            ydk:log "ERROR" "An error (${YDK_EXIT_CODE}) occurred, see you later"
	            ydk:log "INFO" "Please report this issue at: ${YDK_BUGS_REPORT}"
	        else
	            ydk:log "INFO" "Done, ${YDK_EXIT_MESSAGE}, see you later"
	            ydk:log "${YDK_EXIT_MESSAGE}, see you later"
	        fi
	        exit "${YDK_EXIT_CODE}"
	    }
	    ydk:terminate() {
	        local YDK_TERM="${1:-"ERR"}"
	        local YDK_TERM_MESSAGE="${2:-"terminate with: ${YDK_TERM}"}"
	        ydk:log "ERROR" "($YDK_TERM) ${YDK_TERM_MESSAGE}"
	        kill -s "${YDK_TERM}" $$ 2>/dev/null
	    }
	    ydk:raize() {
	        local ERROR_CODE="${1:-$?}" && ERROR_CODE=${ERROR_CODE//[^0-9]/} && ERROR_CODE=${ERROR_CODE:-255}
	        local ERROR_CUSTOM_MESSAGE="${2:-}"
	        local ERROR_MESSAGE="${YDK_ERRORS_MESSAGES[$ERROR_CODE]:-An error occurred}" && ERROR_MESSAGE="${ERROR_MESSAGE} ${ERROR_CUSTOM_MESSAGE}"
	        shift 2
	        jq -cn \
	            --arg code "${ERROR_CODE}" \
	            --arg message "${ERROR_MESSAGE}" \
	            '{ code: $code, message: $message }' | jq -c .
	    }
	    ydk:catch() {
	        local YDK_CATH_STATUS="${1:-$?}"
	        local YDK_CATH_MESSAGE="${2:-"catch with: ${YDK_CATH_STATUS}"}"
	        ydk:log "ERROR" "($YDK_CATH_STATUS) ${YDK_CATH_MESSAGE}"
	        return "${YDK_CATH_STATUS}"
	    }
	    ydk:throw() {
	        local YDK_THROW_STATUS="${1:-$?}"
	        local YDK_TERM="${2:-"ERR"}"
	        local YDK_THROW_MESSAGE="${2:-"throw with: ${YDK_THROW_STATUS}"}"
	        ydk:catch "${YDK_THROW_STATUS}" "${YDK_THROW_MESSAGE}"
	        ydk:teardown "${YDK_THROW_STATUS}" "${YDK_THROW_MESSAGE}"
	    }
	    ydk:try:nnf() {
	        ydk:nnf "$@"
	        YDK_STATUS=$? && [ -z "$YDK_STATUS" ] && YDK_STATUS=1
	        [ "$YDK_STATUS" -ne 0 ] && ydk:usage "$YDK_STATUS" "$1" "${@:2}"
	        return "${YDK_STATUS}"
	    }
	    ydk:temp() {
	        local FILE_PREFIX="${1:-""}" && [[ -n "$FILE_PREFIX" ]] && FILE_PREFIX="${FILE_PREFIX}_"
	        mktemp -u -t "${FILE_PREFIX}"XXXXXXXX -p /tmp --suffix=".ydk"
	    }
	    ydk:dependencies() {
	        [[ ! -d "${1}" ]] && echo -n "[]" | jq -c '.' && return 1
	        local YDK_DEP_OUTPUT=$(ydk:temp "dependencies")
	        echo -n "" >"${YDK_DEP_OUTPUT}"
	        while read -r LIB_ENTRYPOINT; do
	            local LIB_ENTRYPOINT_NAME &&
	                LIB_ENTRYPOINT_NAME=$(basename -- "$LIB_ENTRYPOINT") &&
	                LIB_ENTRYPOINT_NAME=$(
	                    echo "$LIB_ENTRYPOINT_NAME" |
	                        tr '[:upper:]' '[:lower:]'
	                )
	            local LIB_NAME="${LIB_ENTRYPOINT_NAME//.ydk.sh/}" &&
	                LIB_NAME=$(echo "$LIB_NAME" | sed 's/^[0-9]*\.//')
	            local LIB_ENTRYPOINT_TYPE="$(type -t "ydk:$LIB_NAME")"
	            {
	                echo -n "{"
	                echo -n "\"file\": \"${LIB_ENTRYPOINT_NAME}\","
	                echo -n "\"name\": \"${LIB_NAME}\","
	                echo -n "\"entrypoint\": \"${LIB_ENTRYPOINT}\","
	                echo -n "\"path\": \"${1}\","
	                echo -n "\"type\": \"${LIB_ENTRYPOINT_TYPE}\","
	            } >>"${YDK_DEP_OUTPUT}"
	            if [ -n "$LIB_ENTRYPOINT_TYPE" ] && [ "$LIB_ENTRYPOINT_TYPE" = function ]; then
	                echo -n "\"imported\": false," >>"${YDK_DEP_OUTPUT}"
	            else
	                echo -n "\"imported\": true," >>"${YDK_DEP_OUTPUT}"
	                source "${LIB_ENTRYPOINT}" >>"${YDK_DEP_OUTPUT}"
	            fi
	            {
	                echo -n "\"activated\": true"
	                echo -n "}"
	            } >>"${YDK_DEP_OUTPUT}"
	        done < <(find "$1" -type f -name "*.ydk.sh" | sort)
	        jq -sc '.' "${YDK_DEP_OUTPUT}"
	        rm -f "${YDK_DEP_OUTPUT}"
	    }
	    ydk:boostrap() {
	        [ "$YDK_INITIALIZED" == true ] && return 0
	        YDK_INITIALIZED=true && readonly YDK_INITIALIZED
	        local YDK_RUNTIME=$(ydk:cli | jq -c '.')
	        local YDK_RUNTIME_DIR=$(jq -r '.path' <<<"${YDK_RUNTIME}")
	        local YDK_RUNTIME_NAME=$(jq -r '.name' <<<"${YDK_RUNTIME}")
	        local YDK_DEP_OUTPUT=$(ydk:temp "dependencies")
	        local YDK_INCLUDES=(lib extensions)
	        for INCLUDE_IDX in "${!YDK_INCLUDES[@]}"; do
	            local YDK_INCLUDE="${YDK_INCLUDES[$INCLUDE_IDX]}"
	            ydk:dependencies "${YDK_RUNTIME_DIR}/${YDK_INCLUDE}" >>"${YDK_DEP_OUTPUT}"
	        done
	        jq "
	            . + {\"cli\": ${YDK_RUNTIME}} |
	            . + {\"version\": $(ydk:version)} |
	            . + {\"dependencies\": $(jq -sc ". | flatten" "${YDK_DEP_OUTPUT}")}
	        " <<<"{}"
	        rm -f "${YDK_DEP_OUTPUT}"
	        return 0
	    }
	    ydk:usage() {
	        local YDK_USAGE_STATUS=$?
	        [[ $1 =~ ^[0-9]+$ ]] && local YDK_USAGE_STATUS="${1}" && shift
	        local YDK_USAGE_COMMAND="${1:-"<command>"}" && shift
	        local YDK_USAGE_MESSAGE="${1:-"command not found"}" && shift
	        local YDK_USAGE_COMMANDS=("$@")
	        {
	            echo "($YDK_USAGE_STATUS) ${YDK_USAGE_MESSAGE}"
	            echo "* Usage: ydk $YDK_USAGE_COMMAND"
	            [ "${#YDK_USAGE_COMMANDS[@]}" -gt 0 ] && {
	                echo " [commands]"
	                for YDK_USAGE_COMMAND in "${YDK_USAGE_COMMANDS[@]}"; do
	                    echo " ${YDK_USAGE_COMMAND}"
	                done
	            }
	        } 1>&2
	        return "$YDK_USAGE_STATUS"
	    }
	    ydk:setup() {
	        local REQUIRED_LIBS=(
	            "1.is"
	            "2.nnf"
	            "3.argv"
	            "installer"
	        )
	        local RAW_URL="https://raw.githubusercontent.com/cloudyellowteam/ywt-shell/main"
	        local YDK_RUNTIME=$(ydk:cli | jq -c '.')
	        local YDK_RUNTIME_DIR=$(jq -r '.path' <<<"${YDK_RUNTIME}")
	        ydk:log "INFO" "Setting up ydk"
	        ydk:log "INFO" "Downloading libraries"
	        ydk:log "INFO" "Downloading libraries from: ${RAW_URL}"
	        ydk:log "INFO" "Installing libraries into: ${YDK_RUNTIME_DIR}"
	        for LIB in "${REQUIRED_LIBS[@]}"; do
	            if type -t "ydk:$LIB" = function >/dev/null 2>&1; then
	                ydk:log "INFO" "Library $LIB is already installed"
	                continue
	            fi
	            local LIB_FILE="${LIB}.ydk.sh"
	            local LIB_URL="${RAW_URL}/packages/ydk/lib/${LIB_FILE}"
	            mkdir -p "${YDK_RUNTIME_DIR}/lib"
	            local LIB_PATH="${YDK_RUNTIME_DIR}/lib/${LIB_FILE}"
	            if [ ! -f "${LIB_PATH}" ]; then
	                ydk:log "INFO" "Downloading library: ${LIB_FILE} into ${LIB_PATH}"
	                if ! curl -sfL "${LIB_URL}" -o "${LIB_PATH}" 2>&1; then
	                    ydk:throw 252 "ERR" "Failed to download ${LIB_FILE}"
	                fi
	                [[ ! -f "${LIB_PATH}" ]] && ydk:throw 252 "ERR" "Failed to download ${LIB_FILE}"
	            fi
	            ydk:log "INFO" "Installing library: ${LIB_FILE}"
	            source "${LIB_PATH}"
	        done
	        ydk:log "INFO" "All libraries are installed"
	        return 0
	    }
	    ydk:entrypoint() {
	        YDK_POSITIONAL=()
	        while [[ $# -gt 0 ]]; do
	            case "$1" in
	            -i | --install | install)
	                shift
	                ydk:log "INFO" "Installing ydk"
	                if ! type -t "ydk:installer" = function >/dev/null 2>&1; then
	                    ydk:log "INFO" "Downloading installer library"
	                    if ! ydk:setup "$@"; then
	                        ydk:throw 253 "ERR" "Failed to install libraries"
	                    fi
	                fi
	                ydk:log "INFO" "Installing ydk"
	                if ! ydk:installer install "$@"; then
	                    ydk:throw 254 "ERR" "Failed to install ydk"
	                fi
	                ydk:log "INFO" "Installation done"
	                exit 0
	                ;;
	            -v | --version)
	                shift
	                ydk:version | jq -c '.'
	                exit 0
	                ;;
	            -h | --help)
	                shift
	                ydk:usage 0 "ydk" "version" "usage" "install"
	                exit 0
	                ;;
	            esac
	            YDK_POSITIONAL+=("$1") && shift
	        done
	        set -- "${YDK_POSITIONAL[@]}"
	        return 0
	    }
	    ydk:welcome() {
	        ydk:version | jq '.'
	    }
	    trap 'ydk:catch $? "An error occurred"' ERR INT TERM
	    trap 'ydk:teardown $? "Exit with: $?"' EXIT
	    [[ "$1" != "install" ]] && ! ydk:require "${YDK_DEPENDENCIES[@]}" && ydk:throw 255 "ERR" "Failed to install required packages"
	    ydk:entrypoint "$@" || unset -f "ydk:entrypoint"
	    ydk:boostrap >/dev/null 2>&1 || unset -f "ydk:boostrap"
	    ydk:argv flags "$@" || set -- "${YDK_POSITIONAL[@]}"
	    jq -c '.' <<<"$YDK_FLAGS"
	    ydk:nnf "$@"
	    YDK_STATUS=$? && [ -z "$YDK_STATUS" ] && YDK_STATUS=1
	    [ "$YDK_STATUS" -ne 0 ] && ydk:throw "$YDK_STATUS" "ERR" "Usage: ydk $YDK_USAGE_COMMAND"
	    return "${YDK_STATUS:-0}"
	}
	ydk "$@" || YDK_STATUS=$? && YDK_STATUS=${YDK_STATUS:-0} && exit "${YDK_STATUS:-0}"
	ydk:try:nnf "$@"
	return $?
}
ydk:cli "$@"
exit $?
# Name: @ywteam/ydk-shell
# Version: 0.0.0-dev-0
# Description: Cloud Yellow Team | Shell SDK
# Homepage: https://yellowteam.cloud
# License: MIT
# Repository: https://github.com/ywteam/ydk-shell.git
# Author: Raphael Rego <hello@raphaelcarlosr.dev> https://raphaelcarlosr.dev
# Build: ydk-shell
# Build Date: null
# Release: ydk-shell
# Release Date: 2024-04-15T21:36:03+00:00
# Commit: {"id":"c61263f","hash":"c61263f98e365865def7d11cedd3e00078def45f","branch":"main","tag":"0.0.0-alpha-0-4-gc61263f","message":"Update ydk.cli.sh and bundle.ydk.sh scripts, and fix bundle.ydk.sh script"}
