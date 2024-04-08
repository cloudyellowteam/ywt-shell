#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
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
                # return 1
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
        }
        echo
        exit 255
    }
    ydk:cli() {
        YDK_RUNTIME_ENTRYPOINT="${BASH_SOURCE[0]:-$0}"
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
        echo -n "{"
        echo -n "\"file\": \"${YDK_RUNTIME_ENTRYPOINT_NAME}\","
        echo -n "\"cli\": ${YDK_RUNTIME_IS_CLI},"
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
        echo -n "   \"email\": \"raphael@yellowteam.cloud\","
        echo -n "   \"url\": \"https://raphaelcarlosr.dev\""
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
                # shellcheck source=/dev/null # echo "source $FILE" 1>&2 &&
                source "${LIB_ENTRYPOINT}" >>"${YDK_DEP_OUTPUT}"
                # export -f "ydk:$LIB_NAME"
            fi
            # TODO: Activate library with ${LIB_NAME}:$LIB_NAME activate command
            {
                echo -n "\"activated\": true"
                echo -n "}"
            } >>"${YDK_DEP_OUTPUT}"
        done < <(find "$1" -type f -name "*.ydk.sh" | sort)
        # echo -n "]" >>"${YDK_DEP_OUTPUT}"
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
        # cat "${YDK_DEP_OUTPUT}"
        rm -f "${YDK_DEP_OUTPUT}"
        return 0
    }
    ydk:usage() {
        local YDK_USAGE_STATUS=$?
        [[ $1 =~ ^[0-9]+$ ]] && local YDK_USAGE_STATUS="${1}" && shift
        # return "$YDK_USAGE_STATUS"
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
        # ydk:throw "$YDK_USAGE_STATUS" "ERR" "Usage: ydk $YDK_USAGE_COMMAND"
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
        ydk:log "INFO" "Setting up ydk ${YDK_RUNTIME_DIR}"
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
            local LIB_PATH="${YDK_RUNTIME_DIR}/lib/${LIB_FILE}"
            if [ ! -f "${LIB_PATH}" ]; then
                ydk:log "INFO" "Downloading library: ${LIB_FILE} into ${LIB_PATH}"
                if ! curl -sfL "${LIB_URL}" -o "${LIB_PATH}" 2>&1; then
                    ydk:throw 252 "ERR" "Failed to download ${LIB_FILE}"
                fi
                [[ ! -f "${LIB_PATH}" ]] && ydk:throw 252 "ERR" "Failed to download ${LIB_FILE}"
            fi
            ydk:log "INFO" "Installing library: ${LIB_FILE}"
            # shellcheck source=/dev/null
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
    [[ "$1" != "install" ]] && ydk:require "${YDK_DEPENDENCIES[@]}"
    ydk:entrypoint "$@" || unset -f "ydk:entrypoint"
    ydk:boostrap >/dev/null 2>&1 || unset -f "ydk:boostrap"
    ydk:argv flags "$@" || set -- "${YDK_POSITIONAL[@]}"
    jq -c '.' <<<"$YDK_FLAGS"
    ydk:nnf "$@"
    YDK_STATUS=$? && [ -z "$YDK_STATUS" ] && YDK_STATUS=1
    [ "$YDK_STATUS" -ne 0 ] && ydk:throw "$YDK_STATUS" "ERR" "Usage: ydk $YDK_USAGE_COMMAND"
    return "${YDK_STATUS:-0}"
}
(
    [[ -z "$YDK_ERRORS_MESSAGES" ]] && declare -a YDK_ERRORS_MESSAGES=(
        [255]="An error occurred"
        [254]="Failed to install ydk"
        [253]="Failed to install libraries"
        [252]="Failed to download"
    ) && export YDK_ERRORS_MESSAGES
)
ydk "$@" || YDK_STATUS=$? && YDK_STATUS=${YDK_STATUS:-0} && echo "done $YDK_STATUS" && exit "${YDK_STATUS:-0}"
