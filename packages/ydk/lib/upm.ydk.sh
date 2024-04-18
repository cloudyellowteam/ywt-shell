#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:upm() {
    local YDK_LOGGER_CONTEXT="upm"
    detect() {
        local OS_NAME=$(uname -s | tr '[:upper:]' '[:lower:]')
        local OS_VENDOR=$({
            case $OS_NAME in
            linux)
                local OS_VENDOR=$(awk -F= '/^NAME/{print $2}' /etc/os-release | tr -d '"')
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
        ydk:logger info "detected $({
            jq -rc '"\(.os) \(.vendor)"' <<<"${OS_VENDOR}"
        } | tr -d '\n')"
        # ydk:logger -c "$YDK_LOGGER_CONTEXT" output ''"${OS_VENDOR}"'' #"${OS_VENDOR//\"/\'}"
        jq -c . <<<"${OS_VENDOR}" >&4
        return 0
    }
    vendor() {
        local MANAMGER_NAME=$1
        jq -r "
            .[] | 
            select(.name == \"$MANAMGER_NAME\") |
            first(.)
        " "/workspace/rapd-shell/assets/upm.vendors.json"
    }
    cli() {        
        YDK_UPM_DETECT="{}" && detect && read -r -u 4 YDK_UPM_DETECT && ydk:logger output "$YDK_UPM_DETECT" || return $?
        [[ -z "$YDK_UPM_DETECT" ]] && ydk:throw 255 "No package manager detected"
        [[ "$(jq -r '.os' <<<"$YDK_UPM_DETECT")" == "unknown" ]] && ydk:throw 255 "Unsupported OS"
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
        local UPM_MANAGER_VENDOR=$(vendor "$UPM_MANAGER")
        [[ -z "$UPM_MANAGER_VENDOR" ]] && ydk:throw 255 "No package manager vendor found"
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
    }
    ydk:try "$@"
    return $?
    # {
    #     local CMD=$1
    #     shift
    #     local ARGS=("$@")
    #     local UPM=$(cli)
    #     echo "UPM: $UPM"
    # }

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
