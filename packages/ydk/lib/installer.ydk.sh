#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:installer() {
    # install|setup|upgrade|uninstall|remove|purge
    check(){
        for YDK_PATH_NAME in "${!YDK_PATHS[@]}"; do
            local YDK_PATH="${YDK_PATHS[$YDK_PATH_NAME]}"
            local YDK_PATH="${YDK_PATH//\/\//\/}"
            echo "Checking path: $YDK_PATH_NAME -> $YDK_PATH"
            if [[ ! -d "$YDK_PATH" ]]; then
                echo "Path not found: $YDK_PATH"
                exit 254
            fi
        done
    }
    install() {
        echo "INFO Installing YDK"
        check
        echo "INFO Done"
        return 0
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
    ydk:try "$@"
    return $?
}
{
    [[ -z "$YDK_PATHS" ]] && declare -g -A YDK_PATHS=(
        ["bin"]="usr/local/bin/ywteam/${YDK_PACKAGE_NAME}"
        ["lib"]="usr/local/lib/ywteam/${YDK_PACKAGE_NAME}"
        ["etc"]="etc/ywteam/${YDK_PACKAGE_NAME}"
        ["var"]="var/lib/ywteam/${YDK_PACKAGE_NAME}"
        ["cache"]="var/cache/ywteam/${YDK_PACKAGE_NAME}"
        ["logs"]="var/log/ywteam/${YDK_PACKAGE_NAME}"
        ["runtime"]="opt/ywteam/${YDK_PACKAGE_NAME}"
        ["data"]="var/lib/ywteam/${YDK_PACKAGE_NAME}"
        ["config"]="etc/ywteam/${YDK_PACKAGE_NAME}"
        ["tmp"]="tmp/ywteam/${YDK_PACKAGE_NAME}"
        ["home"]="home/ywteam/${YDK_PACKAGE_NAME}"
        ["share"]="usr/share/ywteam/${YDK_PACKAGE_NAME}"
        ["doc"]="usr/share/doc/ywteam/${YDK_PACKAGE_NAME}"        
    ) && readonly YDK_PATHS && export YDK_PATHS && mkdir -p "${YDK_PATHS[@]}"    
}
