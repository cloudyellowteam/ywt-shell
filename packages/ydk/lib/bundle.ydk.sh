#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:bundle() {
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
                "bundles": $bundles
            }'
        return 0
    }
    ydk:bundle:santize() {
        local FILE="$1"
        [[ ! -f "$FILE" ]] && jq -n --arg src "$FILE" '{"error": "Source file not found: \($src). Use ydk:bundle validate <package>.ydk.sh"}' && return 1
        grep -v "^#" "$FILE" | grep -v "^[[:space:]]*#[^!]" | grep -v "^$" | grep -v "^#!/usr/bin/env bash$" | grep -v "^# shellcheck disable" | grep -v "^#"
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
                "Build: \(.build.name)",
                "Build Date: \(.build.data)",
                "Release: \(.release.name)",
                "Release Date: \(.release.date)",
                "Commit: \(.commit)",
                "Author: \(.author.name) <\(.author.email)> \(.author.url)"
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
            echo "# Bundle: $BUNDLE_FILE"
            echo "# Source: $(jq -r '.source' <<<"$VALIDATION")"
            echo "# Basepath: $(jq -r '.basepath' <<<"$VALIDATION")"
            echo "# Realpath: $(jq -r '.realpath' <<<"$VALIDATION")"
            echo "# Relativepath: $(jq -r '.relativepath' <<<"$VALIDATION")"
            echo "# Created: $(date)"
            echo "# Version: $(date +%Y%m%d%H%M%S)"
            echo "# Builder: $(whoami)"
            echo "export YDK_LOCK=\"$COPYRIGHT\" && readonly YDK_COPYRIGHT"
            while read -r FILE; do
                echo "# File: $FILE"
                ydk:bundle:santize "$FILE"
            done < <(jq -r '.bundles.lib.files[]' <<<"$VALIDATION")
            echo "# Entrypoint: $BUNDLE_ENTRYPOINT"
            ydk:bundle:santize "$BUNDLE_ENTRYPOINT"
            echo "# End of bundle"
            copyright
        } >>"$BUNDLE_TMP"
        jq . <<<"$VALIDATION"
        cat "$BUNDLE_TMP" > "$BUNDLE_FILE"
        # chmod +x "$BUNDLE_FILE"
        # "$BUNDLE_FILE" -v        
        rm -f "$BUNDLE_TMP"
        return 0
    }
    ydk:try:nnf "$@"
    return $?
}
