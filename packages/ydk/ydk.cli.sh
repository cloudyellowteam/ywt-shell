#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
# source "/tmp/ywteam/ydk-shell/ydk.2RKuje9q.3044146.bundle" logger info test; 
# ydk prgma 4>&1
# # ydk logger info test
# exit 255
YDK_CLI_ENTRYPOINT="${0}" && readonly YDK_CLI_ENTRYPOINT
YDK_CLI_ARGS=("$@")
export YDK_BRAND="YDK" && readonly YDK_BRAND
export YDK_PACKAGE_NAME="ydk-shell" && readonly YDK_PACKAGE_NAME
export YDK_IS_INSTALL=false && [[ "${1,,}" =~ ^(install|setup|upgrade|uninstall|remove|purge)$ ]] && YDK_IS_INSTALL=true
readonly YDK_IS_INSTALL
set -e -o pipefail
set -e -o errtrace
ydk() {
    local YDK_CLI_NAME=$(basename "${YDK_CLI_ENTRYPOINT}") && readonly YDK_CLI_FILE_NAME
    local YDK_CLI_DIR=$(cd "$(dirname "${YDK_CLI_ENTRYPOINT}")" && pwd) && readonly YDK_CLI_DIR
    local YDK_INITIALIZED=false
    local YDK_BOOTSTRAPED=false
    export YDK_POSITIONAL_ARGS=()
    local YDK_PATH_TMP="/tmp/ywteam/${YDK_PACKAGE_NAME}" && mkdir -p "${YDK_PATH_TMP}"
    local YDK_DEPENDENCIES=(
        "jq" "curl" "sed" "awk" "tr" "sort" "basename" "dirname" "mktemp" "openssl" "column" "ps" "kill" "trap" "mkfifo"
    )
    local YDK_DEPENDENCIES_MISSING=()
    ydk:prgma() {
        local YDK_VERSION="0.0.0-dev-0"
        [ -f "${YDK_CLI_DIR}/VERSION" ] && YDK_VERSION=$(cat "./VERSION")
        local YDK_CLI_BINARY=false
        if command -v file >/dev/null 2>&1; then
            file "${YDK_CLI_ENTRYPOINT}" | grep -q "ELF" && YDK_CLI_BINARY=true
        elif [[ "${BASH_SOURCE[0]}" == "environment" ]]; then
            YDK_CLI_BINARY=true
        fi
        local YDK_CLI=$({
            echo -n "{"
            echo -n "\"brand\": \"${YDK_BRAND}\","
            echo -n "\"package\": \"${YDK_PACKAGE_NAME}\","
            echo -n "\"version\": \"${YDK_VERSION}\","
            echo -n "\"binary\": ${YDK_CLI_BINARY},"
            echo -n "\"cwd\": \"$(pwd)\","
            echo -n "\"entrypoint\": \"${YDK_CLI_ENTRYPOINT}\","
            echo -n "\"name\": \"${YDK_CLI_NAME//.cli.sh/}\","
            echo -n "\"file\": \"${YDK_CLI_NAME}\","
            echo -n "\"path\": \"${YDK_CLI_DIR}\","
            echo -n "\"args\": ["
            for YDK_CLI_ARG in "${YDK_CLI_ARGS[@]}"; do
                echo -n "\"${YDK_CLI_ARG}\","
            done | sed 's/,$//'
            echo -n "],"
            echo -n "\"sources\": ["
            for YDK_BASH_SOURCE in "${BASH_SOURCE[@]}"; do
                YDK_BASH_SOURCE=${YDK_BASH_SOURCE//\"/\\\"}
                echo -n "\"${YDK_BASH_SOURCE}\","
            done | sed 's/,$//'
            echo -n "]"
            echo -n "}"
        })
        echo "$YDK_CLI" >&4
        ydk:log "info" ":shorts: ${YDK_PACKAGE_NAME}@${YDK_VERSION} $([[ "${YDK_CLI_BINARY}" == true ]] && echo "app" || echo "sdk")"
        return 0
    }
    ydk:require() {
        local RESULT=0
        for DEPENDENCY in "${@}"; do
            ! echo "${YDK_DEPENDENCIES[*]}" | grep -q "${DEPENDENCY}" >/dev/null 2>&1 && YDK_DEPENDENCIES+=("${DEPENDENCY}")
            if ! command -v "$DEPENDENCY" >/dev/null 2>&1; then
                #[[ "${DEPENDENCY}" == "!"* ]]
                YDK_DEPENDENCIES_MISSING+=("${DEPENDENCY}")
                RESULT=1
            fi
        done
        # [ "${#YDK_DEPENDENCIES_MISSING[@]}" -eq 0 ] && return 0
        local DETAILS=$({
            echo -n "{"
            echo -n "\"error\":"
            [[ "${#YDK_DEPENDENCIES_MISSING[@]}" -eq 0 ]] && echo -n "false," || echo -n "true,"
            echo -n "\"missing\": ${#YDK_DEPENDENCIES_MISSING[@]},"
            echo -n "\"dependencies\": ["
            for MISSING_DEPENDENCY in "${YDK_DEPENDENCIES_MISSING[@]}"; do
                echo -n "\"${MISSING_DEPENDENCY}\","
            done | sed 's/,$//'
            echo -n "]"
            echo -n "}"
        })
        [[ "$RESULT" -gt 0 ]] && {
            ydk:log error "Missing required packages '${YDK_DEPENDENCIES_MISSING[*]}'. Please install"
            # command -v jq >/dev/null 2>&1 && {
            #     ydk:log error "$(jq -c . <<<"${DETAILS}")"
            # }
            # ydk:throw 254 echo "Missing required packages $_"
        }
        echo "$DETAILS" >&4
        return "$RESULT"
    }
    ydk:help() {
        local YDK_USAGE_STATUS=$1
        local YDK_USAGE_COMMAND="${2:-""}"
        local YDK_USAGE_MESSAGE="${3:-""}"
        local YDK_USAGE_COMMANDS=("$@")
        {
            ydk:log "info" "($YDK_USAGE_STATUS) ${YDK_USAGE_MESSAGE}"
            ydk:log "info" "* Usage: ydk $YDK_USAGE_COMMAND ($_)"
            [ "${#YDK_USAGE_COMMANDS[@]}" -gt 0 ] && {
                ydk:log "info" " [commands]"
                for YDK_USAGE_COMMAND in "${YDK_USAGE_COMMANDS[@]}"; do
                    ydk:log "info" " ${YDK_USAGE_COMMAND}"
                done
            }
        } 1>&2
        return "$YDK_USAGE_STATUS"
    }
    ydk:inject() {
        local ENTRYPOINT_FILE="${1}" && [[ ! -f "${ENTRYPOINT_FILE}" ]] && return 0
        local ENTRYPOINT_NAME=$(basename "${ENTRYPOINT_FILE}")
        local ENTRYPOINT=${ENTRYPOINT_NAME//.ydk.sh/}
        ENTRYPOINT=$(echo "$ENTRYPOINT" | sed 's/^[0-9]*\.//')
        local ENTRYPOINT_TYPE="$(type -t "ydk:$ENTRYPOINT")" && [ -n "$ENTRYPOINT_TYPE" ] && return 0
        if ! [ "$ENTRYPOINT_TYPE" = function ]; then
            # echo "Loading entrypoint: ${ENTRYPOINT}" 1>&2
            # shellcheck source=/dev/null # echo "source $FILE" 1>&2 &&
            source "${ENTRYPOINT_FILE}" activate
            # echo "Loaded entrypoint ($?): ${ENTRYPOINT}" 1>&2
            # export -f "$ENTRYPOINT"
            local ENTRYPOINT_TYPE=$(type -t "ydk:$ENTRYPOINT")
        fi
        if ! [ "$ENTRYPOINT_TYPE" = function ]; then
            # ydk:throw 255 "Failed to load entrypoint: ${ENTRYPOINT_TYPE}"
            return 1
        fi
        return 0
    }
    ydk:boostrap() {
        ! ydk:require "find" "sort" && {
            read -r -u 4 REQUIRED_DEPS
            ydk:log error "${REQUIRED_DEPS}"
            ydk:throw 254 "Missing required packages '${YDK_DEPENDENCIES_MISSING[*]}'"
        }
        [ "$YDK_INITIALIZED" == true ] && return 0
        YDK_INITIALIZED=true && readonly YDK_INITIALIZED
        while read -r ENTRYPOINT_FILE; do
            if ! ydk:inject "${ENTRYPOINT_FILE}"; then
                ydk:throw 255 "Failed to load entrypoint: ${ENTRYPOINT_FILE}"
                return 1
            fi
        done < <(
            find "${YDK_CLI_DIR}" \
                -type f -name "*.ydk.sh" \
                -not -name "${YDK_CLI_FILE_NAME}" | sort
        )
        # ydk:logger info "Activating entrypoints"
        while read -r FUNC_NAME; do
            {
                [[ "$FUNC_NAME" =~ (activate|boostrap|inject|teardown|try|catch|throw|opts) ]] && continue
                [[ ! "$FUNC_NAME" == "ydk:logger" ]] && continue
                "$FUNC_NAME" activate >/dev/null 2>&1
            }
        done < <(ydk:functions | jq -r '.functions[]')
        # ydk:logger success "Activated. Application Boostraped"
        YDK_BOOTSTRAPED=true && readonly YDK_BOOTSTRAPED
        return 0
    }
    ydk:teardown() {
        local YDK_EXIT_CODE="${1:-$?}"
        local YDK_EXIT_MESSAGES=(
            "${2:-"exit with: ${YDK_EXIT_CODE}"}"
        )
        [[ -n "$YDK_ERRORS_MESSAGES" ]] && YDK_EXIT_MESSAGES+=("${YDK_ERRORS_MESSAGES[$YDK_EXIT_CODE]}. ${YDK_CATH_MESSAGE}")
        # local YDK_EXIT_MESSAGE="${2:-"exit with: ${YDK_EXIT_CODE}"}"
        # local YDK_BUGS_REPORT=$(ydk:version | jq -r '.bugs.url') && [ "$YDK_BUGS_REPORT" == "null" ] && YDK_BUGS_REPORT="https://bugs.yellowteam.cloud"
        local YDK_EXIT_LEVEL="" && [[ "${YDK_EXIT_CODE}" -ne 0 ]] && YDK_EXIT_LEVEL="error" || YDK_EXIT_LEVEL="success"
        local YDK_EXIT_JSON=$({
            if [ "${YDK_EXIT_CODE}" -ne 0 ]; then
                echo -n "{"
                echo -n "\"level\": \"error\","
                echo -n "\"error\": true,"
                echo -n "\"status\": ${YDK_EXIT_CODE},"
                echo -n "\"message\": \"An error occurred, see you later\","
                echo -n "\"report\": \"Please report this issue at: ${YDK_BUGS_REPORT}\""
                echo -n "}"
            else
                echo -n "{"
                echo -n "\"level\": \"success\","
                echo -n "\"error\": false,"
                echo -n "\"status\": ${YDK_EXIT_CODE},"
                echo -n "\"message\": \"Done, ${YDK_EXIT_MESSAGES[*]}, see you later\""
                echo -n "}"
            fi
        })
        # local YDK_EXIT_LEVEL=$(jq -r '.level' <<<"${YDK_EXIT_JSON}")
        rm -f ${YDK_FIFO}
        # ydk:log "info" "$YDK_EXIT_JSON"
        [[ -n "$YDK_ERRORS_MESSAGES" ]] && YDK_THROW_MESSAGE="${YDK_ERRORS_MESSAGES[$YDK_THROW_STATUS]}. ${YDK_THROW_MESSAGE}"
        ydk:log "$YDK_EXIT_LEVEL" "($YDK_EXIT_CODE) ${YDK_EXIT_MESSAGES[*]}"
        exit "${YDK_EXIT_CODE}"
    }
    ydk:try() {
        ydk:nnf "$@" || {
            YDK_STATUS=$? && YDK_STATUS=${YDK_STATUS:-0}
            [ "$YDK_STATUS" -ne 0 ] && [[ ! "$1" == "activate" ]] && ydk:throw "$YDK_STATUS" "Usage: ydk $*"
            # [ "$YDK_STATUS" -ne 0 ] && ydk:usage "$YDK_STATUS" "$1" "${@:2}" && ydk:throw "$YDK_STATUS" "Usage: ydk $*" &&
            return "${YDK_STATUS}"
        }
    }
    ydk:log() {
        local YDK_LOG_LEVEL="${1:-"INFO"}"
        local YDK_LOG_MESSAGE="${2:-""}"
        if [[ "$(type -f "ydk:logger" 2>/dev/null)" == function ]] || [[ "$YDK_BOOTSTRAPED" == true ]]; then
            ydk:logger "$@" # "${YDK_LOG_LEVEL,,}" "${YDK_LOG_MESSAGE}"
        else
            local YDK_LOG_TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
            {
                echo -e "${YELLOW}[${YDK_BRAND}]${NC} [$$] [$YDK_LOG_TIMESTAMP] ${YDK_LOG_LEVEL^^} ${YDK_LOG_MESSAGE}"
            } 1>&2
        fi
        return 0
    }
    ydk:catch() {
        local YDK_CATH_STATUS="${1:-$?}"
        local YDK_CATH_MESSAGE="${2:-"catch with: ${YDK_CATH_STATUS}"}"
        # [[ -n "$YDK_ERRORS_MESSAGES" ]] && YDK_CATH_MESSAGE="${YDK_ERRORS_MESSAGES[$YDK_CATH_STATUS]}. ${YDK_CATH_MESSAGE}"
        ydk:log error "($YDK_CATH_STATUS) ${YDK_CATH_MESSAGE} ($_)"
        return "${YDK_CATH_STATUS}"
    }
    ydk:throw() {
        local YDK_THROW_STATUS="${1:-$?}"
        local YDK_THROW_MESSAGE="${2:-"throw with: ${YDK_THROW_STATUS}"}"
        local YDK_TERM="${3:-"ERR"}"
        # [[ -n "$YDK_ERRORS_MESSAGES" ]] && YDK_THROW_MESSAGE="${YDK_ERRORS_MESSAGES[$YDK_THROW_STATUS]}. ${YDK_THROW_MESSAGE}"
        # if [[ "$(type -f "ydk:errors" 2>/dev/null)" == function ]]; then
        #     YDK_EXIT_MESSAGES+=("$(ydk:errors message "${YDK_EXIT_CODE}" 4>&1)")
        # else
        #     echo "{\"error\": \"$(type -f "ydk" 2>/dev/null)\"}"
        # fi
        # ydk:catch "$YDK_THROW_STATUS" "$2"
        # if [[ "$(type -f "ydk:usage" 2>/dev/null)" == function ]]; then
        #     ydk:usage "$YDK_THROW_STATUS" "$2" "${@:3}"
        # else
        #     ydk:help "$YDK_THROW_STATUS" "$2" "${@:3}"
        # fi
        ydk:teardown "${YDK_THROW_STATUS}" "${YDK_THROW_MESSAGE}"
        # kill -s "${YDK_TERM}" $$ 2>/dev/null
        exit "$YDK_THROW_STATUS"
    }
    ydk:temp() {
        local FILE_SUFFIX="${1}" && [[ -n "$FILE_SUFFIX" ]] && FILE_SUFFIX="${FILE_SUFFIX}"
        mktemp -u -t "${YDK_BRAND,,}.XXXXXXXX" -p "/tmp/ywteam/${YDK_PACKAGE_NAME,,}" --suffix=".$$.${FILE_SUFFIX,,}"
    }
    ydk:opts() {
        local YDK_OPTS=$(ydk:argv walk "$@" | jq -r .)
        IFS=$'\n' read -r -d '' -a YDK_OPTS_ARGS <<<"$(jq -r '.__args[]' <<<"$YDK_OPTS")"
        set -- "${YDK_OPTS_ARGS[@]}"
        return 0
    }
    ydk:configure() {
        if [[ "$YDK_IS_INSTALL" == true ]]; then
            # if ! ydk:installer "$@"; then
            #     ydk:logger error "Failed to install ydk"
            #     # ydk:throw 253 "Failed to install ydk"
            #     # set -- "${YDK_POSITIONAL_ARGS[@]}"
            # fi
            ydk:installer "$@"
            local YDK_INSTALL_STATUS=$?
            ydk:team welcome
            exit "$YDK_INSTALL_STATUS"
        fi
        return 0
    }
    trap 'ydk:catch $? "An unexpected error occurred"' ERR INT TERM
    trap 'ydk:teardown $? "Script exited"' EXIT
    local YDK_FIFO="/tmp/ydk.fifo" && readonly YDK_FIFO
    [[ ! -p "${YDK_FIFO}" ]] && mkfifo "${YDK_FIFO}"
    exec 4<>"${YDK_FIFO}" # exec 4<&- | # exec 4>&1 | # exec 4<&0
    trap 'exec 4>&-; rm -f '"${YDK_FIFO}"'' EXIT
    if ! ydk:boostrap 2>&1; then
        ydk:throw 255 "Failed to boostrap ydk"
    fi
    ydk:configure "$@"
    ! ydk:require "${YDK_DEPENDENCIES[@]}" && ydk:throw 254 "Failed to load dependencies"
    ydk:prgma
    ydk:team welcome
    # ydk:analytics ga collect >/dev/null 2>&1
    ydk:try "$@" || YDK_STATUS=$? && YDK_STATUS=${YDK_STATUS:-0}
    # echo "{\"return\": ${YDK_STATUS}}"
    # ydk:teardown "${YDK_STATUS}" "Script exited"
    exec 4>&-
    rm -f "${YDK_FIFO}"
    return "${YDK_STATUS}"
    # [ "$YDK_STATUS" -ne 0 ] && ydk:throw "$YDK_STATUS" "Usage: ydk $*"
    # return "${YDK_STATUS:-0}"
    # return $?
    # local YDK_COMMAND="${1:-"runtime"}"
    # echo "YDK_COMMAND: ${YDK_COMMAND}" 1>&2
    # local YDK_COMMAND_TYPE=$(type -t "ydk:$YDK_COMMAND") && [ -z "$YDK_COMMAND_TYPE" ] && YDK_COMMAND_TYPE="function"
    # if [ "$YDK_COMMAND_TYPE" = function ]; then
    #     shift
    #     "ydk:$YDK_COMMAND" "$@"
    # else
    #     echo "Command not found: ${YDK_COMMAND}" 1>&2
    #     exit 255
    # fi
}
if [[ "$#" -gt 0 ]]; then
    ydk "$@"
    exit $?
fi

# ydk:helper:copy(){
#     src_dir="/workspace/rapd-shell/packages/ydk/common"
#     dest_dir="/workspace/rapd-shell/packages/ydk/lib"
#     for src_file in "$src_dir"/*.ywt.sh; do
#         src_name=$(basename "$src_file") && src_name="${src_name//.ywt.sh/}"
#         dest_file="$dest_dir/${src_name}.ydk.sh"
#         [[ -f "$dest_file" ]] && {
#             echo "File exists: $dest_file"
#             while IFS= read -r src_line; do
#                 echo "# $src_line" >> "$dest_file"
#             done < "$src_file"
#             continue
#         }
#         echo "Copying: $src_file -> $dest_file"
#         cp "$src_file" "$dest_file"
#         # append a comment # to the beginning of each line on dest file
#         sed -i 's/^/# /' "$dest_file"
#         rm -f "$src_file"
#     done
#     exit 255
# }

# || {
#     YDK_STATUS=$? && YDK_STATUS=${YDK_STATUS:-0}
#     echo "{\"exit\": ${YDK_STATUS}}"
#     exit "${YDK_STATUS}"
# }
# echo "{\"success\": true}"
# exit 0

# ydk2() {
#     set -e -o pipefail
#     local YDK_INITIALIZED=false
#     local YDK_POSITIONAL=()
#     local YDK_DEPENDENCIES=("jq" "curl" "sed" "awk" "tr" "sort" "basename" "dirname" "mktemp" "openssl" "column")
#     local YDK_MISSING_DEPENDENCIES=()
#     ydk:log() {
#         local YDK_LOG_LEVEL="${1:-"INFO"}"
#         local YDK_LOG_MESSAGE="${2:-""}"
#         local YDK_LOG_TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
#         echo "[YDK][$YDK_LOG_TIMESTAMP] ${YDK_LOG_LEVEL^^}: $YDK_LOG_MESSAGE" 1>&2

#     }
#     ydk:require() {
#         for DEPENDENCY in "${@}"; do
#             ! echo "${YDK_DEPENDENCIES[*]}" | grep -q "${DEPENDENCY}" >/dev/null 2>&1 && YDK_DEPENDENCIES+=("${DEPENDENCY}")
#             if ! command -v "$DEPENDENCY" >/dev/null 2>&1; then
#                 YDK_MISSING_DEPENDENCIES+=("${DEPENDENCY}")
#                 # return 1
#             fi
#         done
#         [ "${#YDK_MISSING_DEPENDENCIES[@]}" -eq 0 ] && return 0
#         {
#             echo -n "{"
#             echo -n "\"error\": \"missing ${#YDK_MISSING_DEPENDENCIES[@]} dependencies\","
#             echo -n "\"dependencies\": ["
#             for MISSING_DEPENDENCY in "${YDK_MISSING_DEPENDENCIES[@]}"; do
#                 echo -n "\"${MISSING_DEPENDENCY}\","
#             done | sed 's/,$//'
#             echo -n "]"
#             echo -n "}"
#         } | jq -c .
#         return 1
#     }
# ydk:cli() {
#     YDK_RUNTIME_ENTRYPOINT="$YDK_CLI_ENTRYPOINT"
#     YDK_RUNTIME_ENTRYPOINT_NAME=$(basename "${YDK_RUNTIME_ENTRYPOINT}")
#     YDK_RUNTIME_IS_CLI=false
#     [[ "${YDK_RUNTIME_ENTRYPOINT_NAME}" == *".cli.sh" ]] && YDK_RUNTIME_IS_CLI=true
#     YDK_RUNTIME_NAME="${YDK_RUNTIME_ENTRYPOINT_NAME//.cli.sh/}"
#     YDK_RUNTIME_DIR=$(cd "$(dirname "${YDK_RUNTIME_ENTRYPOINT}")" && pwd)
#     YDK_RUNTIME_VERSION="0.0.0-dev-0"
#     [ -f "${YDK_RUNTIME_DIR}/package.json" ] && {
#         YDK_RUNTIME_VERSION=$(jq -r '.version' "${YDK_RUNTIME_DIR}/package.json")
#     } || [ -f "${YDK_RUNTIME_DIR}/VERSION" ] && {
#         YDK_RUNTIME_VERSION=$(cat "./VERSION")
#     }
#     YDK_RUNTIME_IS_BINARY=false
#     if [ -f "${YDK_RUNTIME_ENTRYPOINT}" ]; then
#         if command -v file >/dev/null 2>&1; then
#             file "${YDK_RUNTIME_ENTRYPOINT}" | grep -q "ELF" && YDK_RUNTIME_IS_BINARY=true
#         elif [[ "${BASH_SOURCE[0]}" == "environment" ]]; then
#             YDK_RUNTIME_IS_BINARY=true
#         else
#             YDK_RUNTIME_IS_BINARY=false
#         fi
#     fi
#     echo -n "{"
#     echo -n "\"file\": \"${YDK_RUNTIME_ENTRYPOINT_NAME}\","
#     echo -n "\"cli\": ${YDK_RUNTIME_IS_CLI},"
#     echo -n "\"binary\": ${YDK_RUNTIME_IS_BINARY},"
#     echo -n "\"sources\": ["
#     for YDK_BASH_SOURCE in "${BASH_SOURCE[@]}"; do
#         YDK_BASH_SOURCE=${YDK_BASH_SOURCE//\"/\\\"}
#         echo -n "\"${YDK_BASH_SOURCE}\","
#     done | sed 's/,$//'
#     echo -n "],"
#     echo -n "\"name\": \"${YDK_RUNTIME_NAME}\","
#     echo -n "\"entrypoint\": \"${YDK_RUNTIME_ENTRYPOINT}\","
#     echo -n "\"path\": \"${YDK_RUNTIME_DIR}\","
#     echo -n "\"args\": ["
#     for YDK_CLI_ARG in "${YDK_CLI_ARGS[@]}"; do
#         YDK_CLI_ARG=${YDK_CLI_ARG//\"/\\\"}
#         echo -n "\"${YDK_CLI_ARG}\","
#     done | sed 's/,$//'
#     echo -n "],"
#     echo -n "\"version\": \"${YDK_RUNTIME_VERSION:-"0.0.0-local-0"}\""
#     echo -n "}"
# }
#     ydk:version() {
#         ydk:require "jq"
#         local YDK_REPO_OWNER="ywteam"
#         local YDK_REPO_NAME="ydk-shell"
#         local YDK_REPO_BRANCH="main"
#         local YDK_RUNTIME_VERSION="0.0.0-dev-0"
#         [ -f "${YDK_RUNTIME_DIR}/package.json" ] && {
#             YDK_RUNTIME_VERSION=$(jq -r '.version' "${YDK_RUNTIME_DIR}/package.json")
#         } || [ -f "${YDK_RUNTIME_DIR}/VERSION" ] && {
#             YDK_RUNTIME_VERSION=$(cat "./VERSION")
#         }
#         echo -n "{"
#         echo -n '"name": "@ywteam/ydk-shell",'
#         echo -n "\"version\": \"${YDK_RUNTIME_VERSION:-"0.0.0-local-0"}\","
#         echo -n '"description": "Cloud Yellow Team | Shell SDK",'
#         echo -n '"homepage": "https://yellowteam.cloud",'
#         echo -n '"license": "MIT",'
#         echo -n '"repository": {'
#         echo -n "   \"type\": \"git\","
#         echo -n "   \"url\": \"https://github.com/${YDK_REPO_OWNER}/${YDK_REPO_NAME}.git\","
#         echo -n "   \"branch\": \"${YDK_REPO_BRANCH}\""
#         echo -n "},"
#         echo -n "\"bugs\": {"
#         echo -n "   \"url\": \"https://bugs.yellowteam.cloud\""
#         echo -n "},"
#         echo -n "\"author\": {"
#         echo -n "   \"name\": \"Raphael Rego\","
#         echo -n "   \"email\": \"hello@raphaelcarlosr.dev\","
#         echo -n "   \"url\": \"https://raphaelcarlosr.dev\""
#         echo -n "},"
#         echo -n "\"build\": {"
#         echo -n "   \"name\": \"ydk-shell\","
#         echo -n "   \"date\": \"$(date -Iseconds)\""
#         echo -n "},"
#         echo -n "\"release\": {"
#         echo -n "   \"name\": \"ydk-shell\","
#         echo -n "   \"date\": \"$(date -Iseconds)\""
#         echo -n "},"
#         echo -n "\"commit\": {"
#         echo -n "   \"id\": \"$(git rev-parse --short HEAD 2>/dev/null || echo "Unknown")\","
#         echo -n "   \"hash\": \"$(git rev-parse HEAD 2>/dev/null || echo "Unknown")\","
#         echo -n "   \"branch\": \"$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "Unknown")\","
#         echo -n "   \"tag\": \"$(git describe --tags 2>/dev/null || echo "Unknown")\","
#         # echo -n "   \"author\": \"$(git log -1 --pretty=format:'%an <%ae>' 2>/dev/null || echo "Unknown")\","
#         echo -n "   \"message\": \"$(git log -1 --pretty=format:'%s' 2>/dev/null || echo "Unknown")\""
#         echo -n "}"
#         echo -n "}"
#         echo
#     }
#     ydk:teardown() {
#         local YDK_EXIT_CODE="${1:-$?}"
#         local YDK_EXIT_MESSAGE="${2:-"exit with: ${YDK_EXIT_CODE}"}"
#         local YDK_BUGS_REPORT=$(ydk:version | jq -r '.bugs.url') && [ "$YDK_BUGS_REPORT" == "null" ] && YDK_BUGS_REPORT="https://bugs.yellowteam.cloud"
#         if [ "${YDK_EXIT_CODE}" -ne 0 ]; then
#             ydk:log "ERROR" "An error (${YDK_EXIT_CODE}) occurred, see you later"
#             ydk:log "INFO" "Please report this issue at: ${YDK_BUGS_REPORT}"
#         else
#             ydk:log "INFO" "Done, ${YDK_EXIT_MESSAGE}, see you later"
#             ydk:log "${YDK_EXIT_MESSAGE}, see you later"
#         fi
#         exit "${YDK_EXIT_CODE}"
#     }
#     ydk:terminate() {
#         local YDK_TERM="${1:-"ERR"}"
#         local YDK_TERM_MESSAGE="${2:-"terminate with: ${YDK_TERM}"}"
#         ydk:log "ERROR" "($YDK_TERM) ${YDK_TERM_MESSAGE}"
#         kill -s "${YDK_TERM}" $$ 2>/dev/null
#     }
#     ydk:raize() {
#         local ERROR_CODE="${1:-$?}" && ERROR_CODE=${ERROR_CODE//[^0-9]/} && ERROR_CODE=${ERROR_CODE:-255}
#         local ERROR_CUSTOM_MESSAGE="${2:-}"
#         local ERROR_MESSAGE="${YDK_ERRORS_MESSAGES[$ERROR_CODE]:-An error occurred}" && ERROR_MESSAGE="${ERROR_MESSAGE} ${ERROR_CUSTOM_MESSAGE}"
#         shift 2
#         jq -cn \
#             --arg code "${ERROR_CODE}" \
#             --arg message "${ERROR_MESSAGE}" \
#             '{ code: $code, message: $message }' | jq -c .
#     }
#     ydk:catch() {
#         local YDK_CATH_STATUS="${1:-$?}"
#         local YDK_CATH_MESSAGE="${2:-"catch with: ${YDK_CATH_STATUS}"}"
#         ydk:log "ERROR" "($YDK_CATH_STATUS) ${YDK_CATH_MESSAGE}"
#         return "${YDK_CATH_STATUS}"
#     }
#     ydk:throw() {
#         local YDK_THROW_STATUS="${1:-$?}"
#         local YDK_TERM="${2:-"ERR"}"
#         local YDK_THROW_MESSAGE="${2:-"throw with: ${YDK_THROW_STATUS}"}"
#         ydk:catch "${YDK_THROW_STATUS}" "${YDK_THROW_MESSAGE}"
#         ydk:teardown "${YDK_THROW_STATUS}" "${YDK_THROW_MESSAGE}"
#     }
#     ydk:try:nnf() {
#         ydk:nnf "$@"
#         YDK_STATUS=$? && [ -z "$YDK_STATUS" ] && YDK_STATUS=1
#         [ "$YDK_STATUS" -ne 0 ] && ydk:usage "$YDK_STATUS" "$1" "${@:2}"
#         return "${YDK_STATUS}"
#     }
#     ydk:temp() {
#         local FILE_PREFIX="${1:-""}" && [[ -n "$FILE_PREFIX" ]] && FILE_PREFIX="${FILE_PREFIX}_"
#         mktemp -u -t "${FILE_PREFIX}"XXXXXXXX -p /tmp --suffix=".ydk"
#     }
#     ydk:dependencies() {
#         [[ ! -d "${1}" ]] && echo -n "[]" | jq -c '.' && return 1
#         local YDK_DEP_OUTPUT=$(ydk:temp "dependencies")
#         echo -n "" >"${YDK_DEP_OUTPUT}"
#         while read -r LIB_ENTRYPOINT; do
#             local LIB_ENTRYPOINT_NAME &&
#                 LIB_ENTRYPOINT_NAME=$(basename -- "$LIB_ENTRYPOINT") &&
#                 LIB_ENTRYPOINT_NAME=$(
#                     echo "$LIB_ENTRYPOINT_NAME" |
#                         tr '[:upper:]' '[:lower:]'
#                 )
#             local LIB_NAME="${LIB_ENTRYPOINT_NAME//.ydk.sh/}" &&
#                 LIB_NAME=$(echo "$LIB_NAME" | sed 's/^[0-9]*\.//')
#             local LIB_ENTRYPOINT_TYPE="$(type -t "ydk:$LIB_NAME")"
#             {
#                 echo -n "{"
#                 echo -n "\"file\": \"${LIB_ENTRYPOINT_NAME}\","
#                 echo -n "\"name\": \"${LIB_NAME}\","
#                 echo -n "\"entrypoint\": \"${LIB_ENTRYPOINT}\","
#                 echo -n "\"path\": \"${1}\","
#                 echo -n "\"type\": \"${LIB_ENTRYPOINT_TYPE}\","
#             } >>"${YDK_DEP_OUTPUT}"

#             if [ -n "$LIB_ENTRYPOINT_TYPE" ] && [ "$LIB_ENTRYPOINT_TYPE" = function ]; then
#                 echo -n "\"imported\": false," >>"${YDK_DEP_OUTPUT}"
#             else
#                 echo -n "\"imported\": true," >>"${YDK_DEP_OUTPUT}"
#                 # shellcheck source=/dev/null # echo "source $FILE" 1>&2 &&
#                 source "${LIB_ENTRYPOINT}" >>"${YDK_DEP_OUTPUT}"
#                 # export -f "ydk:$LIB_NAME"
#             fi
#             # TODO: Activate library with ${LIB_NAME}:$LIB_NAME activate command
#             {
#                 echo -n "\"activated\": true"
#                 echo -n "}"
#             } >>"${YDK_DEP_OUTPUT}"
#         done < <(find "$1" -type f -name "*.ydk.sh" | sort)
#         # echo -n "]" >>"${YDK_DEP_OUTPUT}"
#         jq -sc '.' "${YDK_DEP_OUTPUT}"
#         rm -f "${YDK_DEP_OUTPUT}"
#     }
#     ydk:boostrap() {
#         [ "$YDK_INITIALIZED" == true ] && return 0
#         YDK_INITIALIZED=true && readonly YDK_INITIALIZED
#         local YDK_RUNTIME=$(ydk:cli | jq -c '.')
#         local YDK_RUNTIME_DIR=$(jq -r '.path' <<<"${YDK_RUNTIME}")
#         local YDK_RUNTIME_NAME=$(jq -r '.name' <<<"${YDK_RUNTIME}")
#         local YDK_DEP_OUTPUT=$(ydk:temp "dependencies")
#         local YDK_INCLUDES=(lib extensions)
#         for INCLUDE_IDX in "${!YDK_INCLUDES[@]}"; do
#             local YDK_INCLUDE="${YDK_INCLUDES[$INCLUDE_IDX]}"
#             ydk:dependencies "${YDK_RUNTIME_DIR}/${YDK_INCLUDE}" >>"${YDK_DEP_OUTPUT}"
#         done
#         jq "
#             . + {\"cli\": ${YDK_RUNTIME}} |
#             . + {\"version\": $(ydk:version)} |
#             . + {\"dependencies\": $(jq -sc ". | flatten" "${YDK_DEP_OUTPUT}")}
#         " <<<"{}"
#         # cat "${YDK_DEP_OUTPUT}"
#         rm -f "${YDK_DEP_OUTPUT}"
#         return 0
#     }
#     ydk:usage() {
#         local YDK_USAGE_STATUS=$?
#         [[ $1 =~ ^[0-9]+$ ]] && local YDK_USAGE_STATUS="${1}" && shift
#         # return "$YDK_USAGE_STATUS"
#         local YDK_USAGE_COMMAND="${1:-"<command>"}" && shift
#         local YDK_USAGE_MESSAGE="${1:-""}" && shift
#         local YDK_USAGE_COMMANDS=("$@")
#         {
#             echo "($YDK_USAGE_STATUS) ${YDK_USAGE_MESSAGE}"
#             echo "* Usage: ydk $YDK_USAGE_COMMAND"
#             [ "${#YDK_USAGE_COMMANDS[@]}" -gt 0 ] && {
#                 echo " [commands]"
#                 for YDK_USAGE_COMMAND in "${YDK_USAGE_COMMANDS[@]}"; do
#                     echo " ${YDK_USAGE_COMMAND}"
#                 done
#             }
#         } 1>&2
#         # ydk:throw "$YDK_USAGE_STATUS" "ERR" "Usage: ydk $YDK_USAGE_COMMAND"
#         return "$YDK_USAGE_STATUS"
#     }
#     ydk:setup() {
#         local REQUIRED_LIBS=(
#             "1.is"
#             "2.nnf"
#             "3.argv"
#             "installer"
#         )
#         local RAW_URL="https://raw.githubusercontent.com/cloudyellowteam/ywt-shell/main"
#         local YDK_RUNTIME=$(ydk:cli | jq -c '.')
#         local YDK_RUNTIME_DIR=$(jq -r '.path' <<<"${YDK_RUNTIME}")
#         ydk:log "INFO" "Setting up ydk"
#         ydk:log "INFO" "Downloading libraries"
#         ydk:log "INFO" "Downloading libraries from: ${RAW_URL}"
#         ydk:log "INFO" "Installing libraries into: ${YDK_RUNTIME_DIR}"
#         for LIB in "${REQUIRED_LIBS[@]}"; do
#             if type -t "ydk:$LIB" = function >/dev/null 2>&1; then
#                 ydk:log "INFO" "Library $LIB is already installed"
#                 continue
#             fi
#             local LIB_FILE="${LIB}.ydk.sh"
#             local LIB_URL="${RAW_URL}/packages/ydk/lib/${LIB_FILE}"
#             mkdir -p "${YDK_RUNTIME_DIR}/lib"
#             local LIB_PATH="${YDK_RUNTIME_DIR}/lib/${LIB_FILE}"
#             if [ ! -f "${LIB_PATH}" ]; then
#                 ydk:log "INFO" "Downloading library: ${LIB_FILE} into ${LIB_PATH}"
#                 if ! curl -sfL "${LIB_URL}" -o "${LIB_PATH}" 2>&1; then
#                     ydk:throw 252 "ERR" "Failed to download ${LIB_FILE}"
#                 fi
#                 [[ ! -f "${LIB_PATH}" ]] && ydk:throw 252 "ERR" "Failed to download ${LIB_FILE}"
#             fi
#             ydk:log "INFO" "Installing library: ${LIB_FILE}"
#             # shellcheck source=/dev/null
#             source "${LIB_PATH}"
#         done
#         ydk:log "INFO" "All libraries are installed"
#         return 0
#     }
#     ydk:entrypoint() {
#         YDK_POSITIONAL=()
#         while [[ $# -gt 0 ]]; do
#             case "$1" in
#             -i | --install | install)
#                 shift
#                 ydk:log "INFO" "Installing ydk"
#                 if ! type -t "ydk:installer" = function >/dev/null 2>&1; then
#                     ydk:log "INFO" "Downloading installer library"
#                     if ! ydk:setup "$@"; then
#                         ydk:throw 253 "ERR" "Failed to install libraries"
#                     fi
#                 fi
#                 ydk:log "INFO" "Installing ydk"
#                 if ! ydk:installer install "$@"; then
#                     ydk:throw 254 "ERR" "Failed to install ydk"
#                 fi
#                 ydk:log "INFO" "Installation done"
#                 exit 0
#                 ;;
#             -v | --version)
#                 shift
#                 ydk:version | jq -c '.'
#                 exit 0
#                 ;;
#             -h | --help)
#                 shift
#                 ydk:usage 0 "ydk" "version" "usage" "install"
#                 exit 0
#                 ;;
#             esac
#             YDK_POSITIONAL+=("$1") && shift
#         done
#         set -- "${YDK_POSITIONAL[@]}"
#         return 0
#     }
#     ydk:welcome() {
#         ydk:version | jq '.'
#     }
#     trap 'ydk:catch $? "An error occurred"' ERR INT TERM
#     trap 'ydk:teardown $? "Exit with: $?"' EXIT
#     [[ "$1" != "install" ]] && ! ydk:require "${YDK_DEPENDENCIES[@]}" && ydk:throw 255 "ERR" "Failed to install required packages"
#     ydk:entrypoint "$@" || unset -f "ydk:entrypoint"
#     if ! ydk:boostrap >/dev/null 2>&1; then
#         ydk:throw 255 "ERR" "Failed to boostrap ydk"
#     fi
#     unset -f "ydk:boostrap"
#     ydk:argv flags "$@" || set -- "${YDK_POSITIONAL[@]}"
#     jq -c '.' <<<"$YDK_FLAGS"
#     ydk:nnf "$@"
#     YDK_STATUS=$? && [ -z "$YDK_STATUS" ] && YDK_STATUS=1
#     [ "$YDK_STATUS" -ne 0 ] && ydk:throw "$YDK_STATUS" "ERR" "Usage: ydk $YDK_USAGE_COMMAND"
#     return "${YDK_STATUS:-0}"
# }
# ydk2 "$@" || {
#     YDK_STATUS=$? && YDK_STATUS=${YDK_STATUS:-0} && exit "${YDK_STATUS:-0}"
# }
