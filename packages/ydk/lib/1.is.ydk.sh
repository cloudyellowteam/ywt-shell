#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:is() {
    case "$1" in
    not-defined)
        [ -z "$2" ] && return 0
        [ "$2" == "null" ] && return 0
        ;;
    defined)
        [ -n "$2" ] && return 0
        [ "$2" != "null" ] && return 0
        ;;
    rw)
        [ -r "$2" ] && [ -w "$2" ] && return 0
        ;;
    owner)
        [ -O "$2" ] && return 0
        ;;
    writable)
        [ -w "$2" ] && return 0
        ;;
    readable)
        [ -r "$2" ] && return 0
        ;;
    executable)
        [ -x "$2" ] && return 0
        ;;
    nil)
        [ -z "$2" ] && return 0
        [ "$2" == "null" ] && return 0
        ;;
    number)
        [ -n "$2" ] && [[ "$2" =~ ^[0-9]+$ ]] && return 0
        ;;
    string)
        [ -n "$2" ] && [[ "$2" =~ ^[a-zA-Z0-9_]+$ ]] && return 0
        ;;
    boolean)
        [ -n "$2" ] && [[ "$2" =~ ^(true|false)$ ]] && return 0
        ;;
    date)
        [ -n "$2" ] && [[ "$2" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && return 0
        ;;
    url)
        [ -n "$2" ] && [[ "$2" =~ ^https?:// ]] && return 0
        ;;
    json)
        jq -e . <<<"$2" >/dev/null 2>&1 && return 0
        ;;
    fnc | function)
        local TYPE="$(type -t "$2" >/dev/null 2>&1 && echo function)"
        [ -n "$TYPE" ] && [ "$TYPE" = function ] && return 0
        ;;
    cmd | command)
        command -v "$2" >/dev/null 2>&1 && return 0
        ;;
    f | file)
        [ -f "$2" ] && return 0
        ;;
    d | dir)
        [ -d "$2" ] && return 0
        ;;
    esac
    return 1
}
