#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
YDK_CLI_ARGS=("$@")
ydk() {
    set -e -o pipefail
    local YDK_INITIALIZED=false
    local YDK_POSITIONAL=()
    local YDK_DEPENDENCIES=()
    local YDK_MISSING_DEPENDENCIES=()
    ydk:require() {
        for DEPENDENCY in "${@}"; do
            YDK_DEPENDENCIES+=("${DEPENDENCY}")
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
    ydk:require:deps() {
        ydk:require "jq" "sed" "awk" "tr" "sort" "basename" "dirname" "pwd" "cd" "mktemp" "command" "source" "openssl"
        return $?
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
        {
            if [ "${YDK_EXIT_CODE}" -ne 0 ]; then
                echo "An error (${YDK_EXIT_CODE}) occurred, see you later"
                echo "Please report this issue at: ${YDK_BUGS_REPORT}"
            else
                echo "${YDK_EXIT_MESSAGE}, see you later"
            fi
        } 1>&2
        exit "${YDK_EXIT_CODE}"
    }
    ydk:terminate() {
        local YDK_TERM="${1:-"ERR"}"
        local YDK_TERM_MESSAGE="${2:-"terminate with: ${YDK_TERM}"}"
        echo "($YDK_TERM) ${YDK_TERM_MESSAGE}" 1>&2
        kill -s "${YDK_TERM}" $$ 2>/dev/null
    }
    ydk:catch() {
        local YDK_CATH_STATUS="${1:-$?}"
        local YDK_CATH_MESSAGE="${2:-"catch with: ${YDK_CATH_STATUS}"}"
        echo "($YDK_CATH_STATUS) ${YDK_CATH_MESSAGE}" 1>&2
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
    ydk:install() {
        ydk:require:deps
        echo "Installing required packages"
        # {
        #     apk add --update
        #     apk add --no-cache bash jq git parallel
        #     apk add --no-cache curl ca-certificates openssl ncurses coreutils python2 make gcc g++ libgcc linux-headers grep util-linux binutils findutils
        #     rm -rf /var/cache/apk/* /root/.npm /tmp/*
        # } >/dev/null 2>&1
        echo "Packages installed"
        echo "Getting version info"
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
                    # VERSION=${VERSION//$'\n'/\\n}
                    echo -n "\"version\": \"$VERSION\""
                else
                    echo -n "\"path\": \"null\""
                fi
                echo -n "}"
            done 
        } | jq -s '.' >/dev/null 2>&1
    }
    ydk:actions() {
        YDK_POSITIONAL=()
        while [[ $# -gt 0 ]]; do
            case "$1" in
            -i | --install)
                shift
                ydk:install "$@"
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
    trap 'ydk:catch $? "An error occurred"' ERR INT TERM
    trap 'ydk:teardown $? "Exit with: $?"' EXIT
    [[ "$1" != "install" ]] && ydk:require:deps
    ydk:actions "$@" || unset -f "ydk:actions"
    ydk:boostrap >/dev/null 2>&1 || unset -f "ydk:boostrap"
    ydk:argv flags "$@" || set -- "${YDK_POSITIONAL[@]}"
    jq -c '.' <<<"$YDK_FLAGS"
    ydk:nnf "$@"
    YDK_STATUS=$? && [ -z "$YDK_STATUS" ] && YDK_STATUS=1
    [ "$YDK_STATUS" -ne 0 ] && ydk:throw "$YDK_STATUS" "ERR" "Usage: ydk $YDK_USAGE_COMMAND"
    return "${YDK_STATUS:-0}"
}
ydk "$@" || YDK_STATUS=$? && YDK_STATUS=${YDK_STATUS:-0} && echo "done $YDK_STATUS" && exit "${YDK_STATUS:-0}"

# exit 1

# ydk() {
#     set -e -o pipefail
#     ydk:is() {
#         case "$1" in
#         not-defined)
#             [ -z "$2" ] && return 0
#             [ "$2" == "null" ] && return 0
#             ;;
#         defined)
#             [ -n "$2" ] && return 0
#             [ "$2" != "null" ] && return 0
#             ;;
#         rw)
#             [ -r "$2" ] && [ -w "$2" ] && return 0
#             ;;
#         owner)
#             [ -O "$2" ] && return 0
#             ;;
#         writable)
#             [ -w "$2" ] && return 0
#             ;;
#         readable)
#             [ -r "$2" ] && return 0
#             ;;
#         executable)
#             [ -x "$2" ] && return 0
#             ;;
#         nil)
#             [ -z "$2" ] && return 0
#             [ "$2" == "null" ] && return 0
#             ;;
#         number)
#             [ -n "$2" ] && [[ "$2" =~ ^[0-9]+$ ]] && return 0
#             ;;
#         string)
#             [ -n "$2" ] && [[ "$2" =~ ^[a-zA-Z0-9_]+$ ]] && return 0
#             ;;
#         boolean)
#             [ -n "$2" ] && [[ "$2" =~ ^(true|false)$ ]] && return 0
#             ;;
#         date)
#             [ -n "$2" ] && [[ "$2" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && return 0
#             ;;
#         url)
#             [ -n "$2" ] && [[ "$2" =~ ^https?:// ]] && return 0
#             ;;
#         json)
#             jq -e . <<<"$2" >/dev/null 2>&1 && return 0
#             ;;
#         fnc | function)
#             local TYPE="$(type -t "$2")"
#             [ -n "$TYPE" ] && [ "$TYPE" = function ] && return 0
#             ;;
#         cmd | command)
#             command -v "$2" >/dev/null 2>&1 && return 0
#             ;;
#         f | file)
#             [ -f "$2" ] && return 0
#             ;;
#         d | dir)
#             [ -d "$2" ] && return 0
#             ;;
#         esac
#         return 1
#     }
#     ydk:teardown() {
#         local YDK_EXIT_CODE="${1:-$?}"
#         local YDK_EXIT_MESSAGE="${2:-"exit with: ${YDK_EXIT_CODE}"}"
#         echo "${YDK_EXIT_MESSAGE}, see you later" 1>&2
#         exit "${YDK_EXIT_CODE}"
#     }
#     ydk:catch() {
#         local YDK_CATH_STATUS="${1:-$?}"
#         local YDK_CATH_MESSAGE="${2:-"catch with: ${YDK_CATH_STATUS}"}"
#         echo "($YDK_CATH_STATUS) ${YDK_CATH_MESSAGE}" 1>&2
#         return "${YDK_CATH_STATUS}"
#     }
#     ydk:throw() {
#         local YDK_THROW_STATUS="${1:-$?}"
#         local YDK_TERM="${2:-"ERR"}"
#         local YDK_THROW_MESSAGE="${2:-"throw with: ${YDK_THROW_STATUS}"}"
#         ydk:catch "${YDK_THROW_STATUS}" "${YDK_THROW_MESSAGE}"
#         kill -s "${YDK_TERM}" $$ 2>/dev/null
#     }
#     ydk:dependencies() {
#         [[ ! -d "${1}" ]] && echo -n "[]" | jq -c '.' && return 1
#         {
#             while read -r LIB_ENTRYPOINT; do
#                 local LIB_ENTRYPOINT_NAME && LIB_ENTRYPOINT_NAME=$(basename -- "$LIB_ENTRYPOINT") && LIB_ENTRYPOINT_NAME=$(echo "$LIB_ENTRYPOINT_NAME" | tr '[:upper:]' '[:lower:]')
#                 local LIB_NAME="${LIB_ENTRYPOINT_NAME//.ydk.sh/}"
#                 local LIB_ENTRYPOINT_TYPE="$(type -t "ydk:$LIB_NAME")"
#                 {
#                     echo -n "{"
#                     echo -n "\"file\": \"${LIB_ENTRYPOINT_NAME}\","
#                     echo -n "\"name\": \"${LIB_NAME}\","
#                     echo -n "\"entrypoint\": \"${LIB_ENTRYPOINT}\","
#                     echo -n "\"path\": \"${1}\","
#                     echo -n "\"type\": \"${LIB_ENTRYPOINT_TYPE}\","
#                     if [ -n "$LIB_ENTRYPOINT_TYPE" ] && [ "$LIB_ENTRYPOINT_TYPE" = function ]; then
#                         echo -n "\"imported\": false"
#                     else
#                         echo -n "\"imported\": true,"
#                         # shellcheck source=/dev/null # echo "source $FILE" 1>&2 &&
#                         source "${LIB_ENTRYPOINT}" && echo -n "\"activated\": true"
#                         echo -n ",\"echo\": \"$(ydk:strings)\""
#                         export -f "ydk:$LIB_NAME"
#                     fi
#                     echo -n "}"
#                 } | jq -c '.'
#             done < <(find "$1" -type f -name "*.ydk.sh" | sort)
#         } | jq -sc '.'
#         return 0
#     }
#     ydk:info() {
#         YDK_PKG_ENTRYPOINT="${BASH_SOURCE[0]:-$0}" && readonly YDK_PKG_ENTRYPOINT
#         YDK_PKG_ENTRYPOINT_NAME=$(basename "${YDK_PKG_ENTRYPOINT}") && readonly YDK_PKG_ENTRYPOINT_NAME
#         YDK_PKG_NAME="${YDK_PKG_ENTRYPOINT_NAME//.cli.sh/}" && readonly YDK_PKG_NAME
#         YDK_PKG_DIR=$(cd "$(dirname "${YDK_PKG_ENTRYPOINT}")" && pwd) && readonly YDK_PKG_DIR
#         YDK_PKG_VERSION="0.0.0-dev-0"
#         [ -f "${YDK_PKG_DIR}/package.json" ] && {
#             YDK_PKG_VERSION=$(jq -r '.version' "${YDK_PKG_DIR}/package.json")
#         } || [ -f "${YDK_PKG_DIR}/VERSION" ] && {
#             YDK_PKG_VERSION=$(cat "./VERSION")
#         }
#         {
#             echo -n "{"
#             echo -n "\"file\": \"${YDK_PKG_ENTRYPOINT_NAME}\","
#             echo -n "\"name\": \"${YDK_PKG_NAME}\","
#             echo -n "\"entrypoint\": \"${YDK_PKG_ENTRYPOINT}\","
#             echo -n "\"path\": \"${YDK_PKG_DIR}\","
#             echo -n "\"version\": \"${YDK_PKG_VERSION:-"0.0.0-local-0"}\","
#             echo -n "\"dependencies\": "
#             ydk:dependencies "${YDK_PKG_DIR}/lib"
#             echo -n "}"
#         } | jq -c '.'
#         return 0
#     }
#     trap 'ydk:catch $? "An error occurred"' ERR INT TERM
#     trap 'ydk:teardown $? "Exit with: $?"' EXIT
#     local YDK_PACKAGE="$(jq -c . <<<"$(ydk:info "$@")")"
#     local YDK_PKG_DIR="${YDK_PKG_DIR:-$(jq -r '.path' <<<"${YDK_PACKAGE}")}"
#     # shellcheck source=/dev/null # echo "source $FILE" 1>&2 &&
#     source "${YDK_PKG_DIR}/lib/strings.ydk.sh" # && export -f ydk:strings
#     if ! ydk:strings 2>/dev/null; then ydk:throw "$?" "An error occurred in ydk:strings"; fi

#     # echo "DONE"
#     return 0
# }
# ydk "$@" && echo "thank's for usage" && exit 0
