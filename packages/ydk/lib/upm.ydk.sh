#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
# universal package manager vendor schema
ydk:upm() {
    local YDK_LOGGER_CONTEXT="upm"
    ydk:require --throw jq 4>/dev/null
    [[ -z "$YDK_UPM_VENDORS_FILE" ]] && local YDK_UPM_VENDORS_FILE="/workspace/rapd-shell/assets/upm.vendors.json" && [[ ! -f "$YDK_UPM_VENDORS_FILE" ]] && YDK_UPM_VENDORS_FILE="$(ydk:assets location "upm-vendors" 4>&1)"
    detect() {
        ydk:require --throw uname awk tr sed 4>/dev/null
        local OS_NAME=$(uname -s | tr '[:upper:]' '[:lower:]')
        local OS_VENDOR=$({
            case $OS_NAME in
            linux)
                local OS_VENDOR_NAME=$(awk -F= '/^NAME/{print $2}' /etc/os-release | tr -d '"' | sed 's/ linux//')
                IFS=" " read -r -a OS_VENDOR_NAME <<<"$OS_VENDOR_NAME"
                local OS_VENDOR=${OS_VENDOR_NAME[0]}
                ;;
            darwin)
                local OS_VENDOR="macos"
                ;;
            cygwin* | mingw* | msys*)
                local OS_VENDOR="windows"
                ;;
            *)
                local OS_VENDOR="unknown"
                ;;
            esac
            OS_VENDOR=${OS_VENDOR,,}
            ydk:logger output "Detecting package managers for $OS_NAME/${OS_VENDOR}"
            echo -n "{"
            echo -n "\"os\":\"$OS_NAME\","
            echo -n "\"vendor\":\"$OS_VENDOR\","
            echo -n "\"managers\":{"
            local IFS=" "
            for PM in ${YDK_UPM_OS_MAP[$OS_VENDOR]}; do
                echo -n "\"$PM\":{ "
                echo -n "\"installed\":$(command -v "$PM" &>/dev/null && echo -n "true" || echo -n "false"),"
                echo -n "\"path\":\"$(command -v "$PM" 2>/dev/null)\","
                echo -n "\"version\":\"$($PM --version 2>/dev/null)\""
                echo -n "},"
            done | sed 's/,$//'
            echo -n "}"
            echo -n "}"
        } | jq -c .)
        ydk:logger output < <(
            jq -rc '
                "\(.os)/\(.vendor). \(.managers | length) package managers detected. \(.managers | keys | join(" "))"
            ' <<<"${OS_VENDOR}"
        )
        jq -c . <<<"${OS_VENDOR}" >&4
        return 0
    }
    vendor() {
        local MANAMGER_NAME=$1
        jq -cr "
            .[] | 
            select(.name == \"$MANAMGER_NAME\") |
            first(.)
        " "${YDK_UPM_VENDORS_FILE}" >&4
    }
    __upm:cli() {
        local YDK_UPM_DETECT=$(detect 4>&1) && [[ -z "$YDK_UPM_DETECT" ]] && ydk:throw 255 "No package manager detected"
        [[ "$(jq -r '.os' <<<"$YDK_UPM_DETECT")" == "unknown" ]] && ydk:throw 255 "Unsupported OS"
        # YDK_UPM_DETECT="{}" && detect && read -r -u 4 YDK_UPM_DETECT && ydk:logger output "$YDK_UPM_DETECT" || return $?
        # [[ -z "$YDK_UPM_DETECT" ]] && ydk:throw 255 "No package manager detected"
        # [[ "$(jq -r '.os' <<<"$YDK_UPM_DETECT")" == "unknown" ]] && ydk:throw 255 "Unsupported OS"
        local UPM_MANAGER=$(
            jq -r '
                if .managers != null then
                    .managers | 
                    to_entries[] |
                    select(.value.installed == true) | 
                    first(.key)
                else
                    empty
                end
            ' <<<"$YDK_UPM_DETECT"
        )
        [[ -z "$UPM_MANAGER" ]] && ydk:throw 255 "No package manager found"
        local UPM_MANAGER_VENDOR=$(vendor "$UPM_MANAGER" 4>&1)
        [[ -z "$UPM_MANAGER_VENDOR" ]] && ydk:throw 255 "No package manager vendor found"
        local UPM_MANAGER=$({
            jq -n \
                --argjson DETECT "$YDK_UPM_DETECT" \
                --arg UPM_MANAGER "$UPM_MANAGER" \
                --argjson UPM_VENDOR "$UPM_MANAGER_VENDOR" \
                '{
                os: $DETECT.os,
                vendor: $DETECT.vendor,
                manager: ($UPM_VENDOR + {
                    path: $DETECT.managers[$UPM_MANAGER].path,
                    version: $DETECT.managers[$UPM_MANAGER].version
                }),                
                managers: $DETECT.managers                
            }'
        })
        ydk:log info "Detected package manager $(jq -r '.manager.name' <<<"$UPM_MANAGER")"
        jq -c . <<<"$UPM_MANAGER" >&4
        return 0
    }
    cmd() {
        local UPM_MANAGER_CMD=$1 && [ -z "$UPM_MANAGER_CMD" ] && return 22
        shift
        local YDK_UPM_CLI=$(__upm:cli 4>&1) && [[ -z "$YDK_UPM_CLI" ]] && return 255
        local UPM_MANAGER=$(jq -r '.manager' <<<"$YDK_UPM_CLI") && [[ -z "$UPM_MANAGER" ]] && return 255
        local UPM_MANAGER_NAME=$(jq -r '.name' <<<"$UPM_MANAGER")
        # local UPM_MANAGER_PATH=$(jq -r '.path' <<<"$UPM_MANAGER")
        local UPM_MANAGER_VERSION=$(jq -r '.version' <<<"$UPM_MANAGER")
        local UPM_MANAGER_CONFIRM=$(jq -r '.confirm' <<<"$UPM_MANAGER")
        UPM_MANAGER_CONFIRM=${UPM_MANAGER_CONFIRM%%\/*}
        local UPM_MANAGER_COMMAND=$(jq -r '.'"${UPM_MANAGER_CMD}"'' <<<"$UPM_MANAGER")
        UPM_MANAGER_COMMAND=${UPM_MANAGER_COMMAND//\$/}
        [[ -z "$UPM_MANAGER_COMMAND" ]] && return 255
        local UPM_COMMAND="$UPM_MANAGER_COMMAND"
        case $UPM_MANAGER_CMD in
        install | remove | upgrade)
            UPM_COMMAND+=" $UPM_MANAGER_CONFIRM"
            ;;
        list_installed)
            # UPM_COMMAND is apk list -I/--installed, keep just one flag
            UPM_COMMAND=${UPM_COMMAND%%\/*}
            ;;
        *) ;;
        esac
        # local UPM_COMMAND="$UPM_MANAGER_CMD $UPM_MANAGER_CONFIRM"
        # ydk:log debug "Running ($UPM_MANAGER_CMD) $UPM_COMMAND $* with manager $UPM_MANAGER_NAME:$UPM_MANAGER_VERSION" >&1
        # ydk:require --throw "$UPM_COMMAND" 4>/dev/null
        $UPM_COMMAND "$@" 2>/dev/null >&4
        # local UPM_CMD_STATUS=$?
        # # sleep 40 &
        # local UPM_CMD_PID=$!
        # ydk:await spin "$UPM_CMD_PID" "Running $UPM_CMD_PID command" >&1
        ydk:log "$([[ $UPM_CMD_STATUS -eq 0 ]] && echo "success" || echo "error")" "Command  $UPM_MANAGER_NAME:$UPM_MANAGER_VERSION exited with status $UPM_CMD_STATUS" >&1
        #ydk:await process "$!" "Running $! $* with $UPM_MANAGER_NAME:$UPM_MANAGER_VERSION" >&1
        # local UPM_CMD_PID=$!
        # ydk:await process "$UPM_CMD_PID" "Running $UPM_MANAGER_CMD $* with $UPM_MANAGER_NAME:$UPM_MANAGER_VERSION" 4>&1
        return "${UPM_CMD_STATUS:-0}"
    }
    install() {
        cmd install "$@" >&4
        return $?
    }
    uninstall() {
        cmd remove "$@" >&4
        return $?
    }
    upgrade() {
        cmd upgrade "$@" >&4
        return $?
    }
    search() {
        cmd search "$@" >&4
        return $?
    }
    info() {
        cmd info "$@" >&4
        return $?
    }
    update() {
        cmd update_index >&4
        return $?
    }
    upgrade_all() {
        cmd upgrade_all >&4
        return $?
    }
    installed() {
        ydk:log info "Listing installed packages"
        cmd list_installed | awk '{print $1}' | tail -n +2 | sort | column >&4
        return 0
        # local INSTALLED_CMD_STATUS=$?
        # return "$INSTALLED_CMD_STATUS"
    }
    ydk:try "$@" 4>&1
    return $?
}
{
    declare -g -A YDK_UPM_OS_MAP=(
        [windows]="scoop choco winget"
        [macos]="brew port"
        [ubuntu]="apt"
        [debian]="apt"
        [linuxmint]="apt"
        [pop]="apt"
        [deepin]="apt"
        [elementray]="apt"
        [kali]="apt"
        [raspbian]="apt"
        [aosc]="apt"
        [zorin]="apt"
        [antix]="apt"
        [devuan]="apt"
        [bodhi]="apt"
        [lxle]="apt"
        [sparky]="apt"
        [fedora]="dnf yum"
        [redhat]="dnf yum"
        [rhel]="dnf yum"
        [amzn]="dnf yum"
        [ol]="dnf yum"
        [almalinux]="dnf yum"
        [rocky]="dnf yum"
        [oubes]="dnf yum"
        [centos]="dnf yum"
        [qubes]="dnf yum"
        [eurolinux]="dnf yum"
        [arch]="pacman"
        [manjaro]="pacman"
        [endeavouros]="pacman"
        [arcolinux]="pacman"
        [garuda]="pacman"
        [antergos]="pacman"
        [kaos]="pacman"
        [alpine]="apk"
        [postmarket]="apk"
        [opensuse]="zypper"
        [opensuse - leap]="zypper"
        [opensuse - tumbleweed]="zypper"
        [nixos]="nix-env"
        [gentoo]="emerge"
        [funtoo]="emerge"
        [void]="xbps"
        [mageia]="urpm"
        [slackware]="slackpkg"
        [solus]="eopkg"
        [openwrt]="opkg"
        [nutyx]="cards"
        [crux]="prt-get"
        [freebsd]="pkg"
        [ghostbsd]="pkg"
        [android]="pkg(termux)"
        [haiku]="pkgman"
    )
}
#!/usr/bin/env bash
# # shellcheck disable=SC2044,SC2155,SC2317
# # universal package manager
# # https://github.com/sigoden/upt/tree/main
# upm(){
#     install(){
#         echo "install"
#     }
#     __nnf "$@" || usage "upm" "$?"  "$@" && return 1
# }
# (
#     export -f upm
