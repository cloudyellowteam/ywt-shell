#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:assets() {
    [[ -z "$YDK_TEAM_INFO" ]] && {
        local YDK_TEAM_INFO=$(ydk:team info 4>&1)
        readonly YDK_TEAM_INFO
        export YDK_TEAM_INFO
    }
    local YDK_REMOTE_URL=$(jq -r '.repo.raw' <<<"${YDK_TEAM_INFO}" 2>/dev/null)
    local YDK_REMOTE_URL="https://raw.githubusercontent.com/cloudyellowteam/ywt-shell/main"
    [[ -z "$YDK_ASSETS_PATH" ]] && {
        local YDK_ASSETS_PATH="${YDK_PATHS[assets]}"
        readonly YDK_ASSETS_PATH
        export YDK_ASSETS_PATH
        mkdir -p "${YDK_ASSETS_PATH}"
    }
    # {
    #     jq . <<<"${YDK_TEAM_INFO}"
    #     echo "${YDK_REMOTE_URL}"
    #     echo "YDK_PATHS = ${YDK_PATHS[assets]}"
    # } >&4
    get() {
        local ASSETS=()
        for ASSET in "$@"; do
            [[ -n "${YDK_ASSETS[${ASSET}]}" ]] && ASSET="${YDK_ASSETS[${ASSET}]}"
            local ASSET_URL="${YDK_REMOTE_URL}/assets/${ASSET}"
            local ASSET_FILE="${YDK_ASSETS_PATH}/${ASSET}"
            local ASSET_TMP=$(ydk:temp "download")
            if [[ -f "${ASSET_FILE}" ]]; then
                ydk:log "INFO" "Asset already exists: ${ASSET_FILE}"
                echo "${ASSET_FILE}" >&4
                # rm -f "${ASSET_FILE}" >/dev/null 2>&1
                return 0                
            fi
            ydk:log "INFO" "Downloading asset from ${ASSET_URL}"
            if ! curl -f -SsL -o "${ASSET_TMP}" "${ASSET_URL}" 2>/dev/null; then
                ydk:log "ERROR" "Failed to download asset from ${ASSET_URL}"
                return 1
            fi
            if [[ -f "${ASSET_TMP}" ]] || [[ -s "${ASSET_TMP}" ]]; then
                mv "${ASSET_TMP}" "${ASSET_FILE}"
                rm -f "${ASSET_TMP}" >/dev/null 2>&1
            else
                ydk:log "ERROR" "Failed to download asset from ${ASSET_URL}"
                return 1
            fi
            ASSETS+=("${ASSET_FILE}")
        done
        echo "${ASSETS[@]}" | tr ' ' '\n' >&4
        return 0
    }
    download(){
        for ASSET in "${YDK_ASSETS[@]}"; do
            if ! get "${ASSET}" 4>/dev/null 2>&1; then
                ydk:log "ERROR" "Failed to download asset: ${ASSET}"
                continue
            fi
        done
        return 0
    }
    # local YDK_USERNAME="cloudyellowteam"
    # local YDK_REPO_NAME="ywt-shell"
    # local YDK_REPO_BRANCH="main"
    # local YDK_REPO_URL="https://github.com/${YDK_USERNAME}/${YDK_REPO_NAME}"
    # local YDK_REPO_RAW_URL="https://raw.githubusercontent.com/${YDK_USERNAME}/${YDK_REPO_NAME}/${YDK_REPO_BRANCH}"
    # download(){
    #     local YDK_ASSET_PATH="${1}"
    #     local YDK_ASSET_URL="${YDK_REPO_RAW_URL}/${YDK_ASSET_PATH}"
    #     local YDK_ASSET_FILE=$(basename -- "$YDK_ASSET_PATH")
    #     local YDK_ASSET_TMP=$(ydk:temp "download")
    #     trap 'rm -f "${YDK_ASSET_TMP}" >/dev/null 2>&1' EXIT
    #     if [[ -f "${YDK_ASSET_FILE}" ]]; then
    #         ydk:log "INFO" "Asset already exists: ${YDK_ASSET_FILE}"
    #         return 0
    #     fi
    #     ydk:log "INFO" "Downloading asset from ${YDK_ASSET_URL}"
    #     if ! curl -sSL -o "${YDK_ASSET_TMP}" "${YDK_ASSET_URL}"; then
    #         ydk:log "ERROR" "Failed to download asset from ${YDK_ASSET_URL}"
    #         return 1
    #     fi
    #     mv "${YDK_ASSET_TMP}" "${YDK_ASSET_FILE}"
    #     return $?
    # }
    activate() {
        echo "assets package"
    }
    ydk:try "$@" 4>&1
    return $?
}
{
    [[ -z "$YDK_ASSETS" ]] && declare -g -A YDK_ASSETS=(
        ["spinners"]="spinners.json"
        ["emojis"]="emojis.json"
        ["scanners"]="scanners.json"
        ["upm-vendors"]="upm.vendors.json"
    ) && readonly YDK_ASSETS && export YDK_ASSETS
}
