#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:installer() {
    # install|setup|upgrade|uninstall|remove|purge
    YDK_LOGGER_CONTEXT="installer"
    path() {
        # ydk:log "INFO" "Getting path: $1"
        {
            local YDK_PATH_NAME="$1" && [[ -z "$YDK_PATH_NAME" ]] && pwd && return 1
            local YDK_PATH="${YDK_PATHS[$YDK_PATH_NAME]}"
            [[ -z "$YDK_PATH" ]] && pwd && return 1
            [[ "${YDK_PATH:0:1}" == "!" ]] && YDK_PATH="${YDK_PATH:1}"
            [[ ! -d "$YDK_PATH" ]] && echo "$YDK_PATH" && return 1
            echo "$YDK_PATH"
            return 0
        } >&4
    }
    paths() {
        # ydk:log "INFO" "Getting paths"
        {
            echo -n "{"
            for YDK_PATH_NAME in "${!YDK_PATHS[@]}"; do
                local YDK_PATH="${YDK_PATHS[$YDK_PATH_NAME]}"
                local YDK_PATH="${YDK_PATH//\/\//\/}"
                echo -n "\"$YDK_PATH_NAME\":\"$YDK_PATH\","
            done | sed 's/,$//'
            echo -n "}"
        } >&4

        return 0
    }
    check:path() {
        local YDK_PATH="$1"
        local YDK_PATH="${YDK_PATH//\/\//\/}"
        [[ "${YDK_PATH:0:1}" == "!" ]] && {
            YDK_PATH="${YDK_PATH:1}"
            # ydk:log "INFO" " - Removing path: $YDK_PATH"
            rm -rf "${YDK_PATH:1}"
        }
        [[ ! -d "$YDK_PATH" ]] && {
            # ydk:log "INFO" " - Create path: $YDK_PATH"
            mkdir -p "$YDK_PATH"
        }
        # ydk:log "INFO" " - Path exists: $YDK_PATH"
        return 0
    }
    check:paths() {
        # ydk:log "INFO" "Checking paths"
        for YDK_PATH_NAME in "${!YDK_PATHS[@]}"; do
            local YDK_PATH="${YDK_PATHS[$YDK_PATH_NAME]}"
            check:path "$YDK_PATH"
        done
        return 0
    }
    state() {
        local YDK_STATE_FILE="${YDK_PATHS["var"]}/state.json"
        local YDK_STATE=$(jq -c . <"$YDK_STATE_FILE" 2>/dev/null)
        [[ -z "$YDK_STATE" ]] && echo -n "{}" && return 1
        echo -n "$YDK_STATE"
        return 0
    }
    install() {
        check:paths
        local YDK_PATH_MAP=$(paths 4>&1) && echo "MAP: $YDK_PATH_MAP"
        local YDK_PATH_BIN=$(path "bin" 4>&1) && echo "BIN1: $YDK_PATH_BIN"
        return 0
    }
    __installer:opts() {
        local YDK_INSTALLER_OPTS=()
        while [[ $# -gt 0 ]]; do
            case "$1" in
            -h | --help)
                shift
                ydk:usage 0 "ydk" "install" "usage"
                exit 0
                ;;
            -b | --bin)
                YDK_PATHS["bin"]="${2}"
                shift 2
                ;;
            -l | --lib)
                YDK_PATHS["lib"]="${2}"
                shift 2
                ;;
            -e | --etc)
                YDK_PATHS["etc"]="${2}"
                shift 2
                ;;
            -v | --var)
                YDK_PATHS["var"]="${2}"
                shift 2
                ;;
            -c | --cache)
                YDK_PATHS["cache"]="${2}"
                shift 2
                ;;
            -L | --logs)
                YDK_PATHS["logs"]="${2}"
                shift 2
                ;;
            -r | --runtime)
                YDK_PATHS["runtime"]="${2}"
                shift 2
                ;;
            -d | --data)
                YDK_PATHS["data"]="${2}"
                shift 2
                ;;
            -C | --config)
                YDK_PATHS["config"]="${2}"
                shift 2
                ;;
            -t | --tmp)
                YDK_PATHS["tmp"]="${2}"
                shift 2
                ;;
            -H | --home)
                YDK_PATHS["home"]="${2}"
                shift 2
                ;;
            -s | --share)
                YDK_PATHS["share"]="${2}"
                shift 2
                ;;
            -D | --doc)
                YDK_PATHS["doc"]="${2}"
                shift 2
                ;;
            *)
                if [[ "$1" =~ ^- ]]; then
                    ydk:log "WARN" "Unknown option: $1 $2"
                    shift 2
                else 
                    YDK_INSTALLER_OPTS+=("$1")
                    shift
                fi
                # [[ "$1" =~ ^- ]] && ydk:log "WARN" "Unknown option: $1"
                # YDK_INSTALLER_OPTS+=("$1")
                # shift
                ;;
            esac
        done
        set -- "${YDK_INSTALLER_OPTS[@]}"
        # ydk:log "INFO" "Installer options: ${#YDK_INSTALLER_OPTS[@]} ${YDK_INSTALLER_OPTS[*]}"
        # for YDK_PATH_NAME in "${!YDK_PATHS[@]}"; do
        #     local YDK_PATH=$(path "$YDK_PATH_NAME" 4>&1)
        #     ydk:log "INFO" "Path: $YDK_PATH_NAME: $YDK_PATH"
        # done
        [[ "${#YDK_INSTALLER_OPTS[@]}" -eq 0 ]] && {
            ydk:throw 252 "Failed to parse installer options"
            return 1
        }
        echo "${YDK_INSTALLER_OPTS[@]}" >&4
        return 0
    }
    install:v1() {
        local YDK_BINARY_PATH="/usr/local/bin"
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
        # mkdir -p "$(dirname "${YDK_INSTALL_PATH}")"
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
                    # VERSION=${VERSION//$'\n'/\\n}
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
            # echo "Verifying dependency: $DEPENDENCY_NAME"
            if command -v "$DEPENDENCY_NAME" >/dev/null 2>&1; then
                continue
                # local INSTALLED_VERSION=$(jq -r '.version' <<<"${DEPENDENCY}")
                # if [ "$INSTALLED_VERSION" != "$DEPENDENCY_VERSION" ]; then
                #     echo "Dependency version mismatch: $DEPENDENCY_NAME"
                #     ydk:throw 251 "ERR" "Dependency version mismatch: $DEPENDENCY_NAME"
                # fi
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
    set -- "$(__installer:opts "$@" 4>&1)" && ydk:try "$@"
    return $?
}
{
    [[ -z "${YDK_PATHS[*]}" ]] && declare -g -A YDK_PATHS=(
        ["bin"]="${YDK_CONFIG_PATH_BIN:-"/usr/local/bin/ywteam/${YDK_PACKAGE_NAME}"}"
        ["lib"]="${YDK_CONFIG_PATH_LIB:-"/usr/local/lib/ywteam/${YDK_PACKAGE_NAME}"}"
        ["etc"]="${YDK_CONFIG_PATH_ETC:-"/etc/ywteam/${YDK_PACKAGE_NAME}"}"
        ["var"]="${YDK_CONFIG_PATH_VAR:-"/var/lib/ywteam/${YDK_PACKAGE_NAME}"}"
        ["cache"]="${YDK_CONFIG_PATH_CACHE:-"!/var/cache/ywteam/${YDK_PACKAGE_NAME}"}"
        ["logs"]="${YDK_CONFIG_PATH_LOGS:-"/var/log/ywteam/${YDK_PACKAGE_NAME}"}"
        ["runtime"]="${YDK_CONFIG_PATH_RUNTIME:-"/opt/ywteam/${YDK_PACKAGE_NAME}"}"
        ["data"]="${YDK_CONFIG_PATH_DATA:-"/var/lib/ywteam/${YDK_PACKAGE_NAME}"}"
        ["config"]="${YDK_CONFIG_PATH_CONFIG:-"/etc/ywteam/${YDK_PACKAGE_NAME}"}"
        ["tmp"]="${YDK_CONFIG_PATH_TMP:-"/tmp/ywteam/${YDK_PACKAGE_NAME}"}"
        ["home"]="${YDK_CONFIG_PATH_HOME:-"$HOME/ywteam/${YDK_PACKAGE_NAME}"}"
        ["share"]="${YDK_CONFIG_PATH_SHARE:-"/usr/share/ywteam/${YDK_PACKAGE_NAME}"}"
        ["doc"]="${YDK_CONFIG_PATH_DOC:-"/usr/share/ywteam/${YDK_PACKAGE_NAME}/doc"}"
        # ["bin"]="/usr/local/bin/ywteam/${YDK_PACKAGE_NAME}"
        # ["lib"]="/usr/local/lib/ywteam/${YDK_PACKAGE_NAME}"
        # ["etc"]="/etc/ywteam/${YDK_PACKAGE_NAME}"
        # ["var"]="/var/lib/ywteam/${YDK_PACKAGE_NAME}"
        # ["cache"]="!/var/cache/ywteam/${YDK_PACKAGE_NAME}"
        # ["logs"]="/var/log/ywteam/${YDK_PACKAGE_NAME}"
        # ["runtime"]="/opt/ywteam/${YDK_PACKAGE_NAME}"
        # ["data"]="/var/lib/ywteam/${YDK_PACKAGE_NAME}"
        # ["config"]="/etc/ywteam/${YDK_PACKAGE_NAME}"
        # ["tmp"]="/tmp/ywteam/${YDK_PACKAGE_NAME}"
        # ["home"]="$HOME/ywteam/${YDK_PACKAGE_NAME}"
        # ["share"]="/usr/share/ywteam/${YDK_PACKAGE_NAME}"
        # ["doc"]="/usr/share/ywteam/${YDK_PACKAGE_NAME}/doc"
    ) && export YDK_PATHS
    # && mkdir -p "${YDK_PATHS[@]}"
}
