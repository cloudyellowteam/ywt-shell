#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:assets() {
    local YDK_USERNAME="cloudyellowteam"
    local YDK_REPO_NAME="ywt-shell"
    local YDK_REPO_BRANCH="main"
    local YDK_REPO_URL="https://github.com/${YDK_USERNAME}/${YDK_REPO_NAME}"
    local YDK_REPO_RAW_URL="https://raw.githubusercontent.com/${YDK_USERNAME}/${YDK_REPO_NAME}/${YDK_REPO_BRANCH}"
    activate(){
        echo "assets package"
    }
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

    ydk:try "$@"
    return $?
}
