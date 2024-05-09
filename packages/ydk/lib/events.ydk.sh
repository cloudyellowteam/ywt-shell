#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317,SC2120,SC2016
# @file events.ydk.sh
# @brief Events is a event hub for lazy developers
# @description Events is a event hub for lazy developers
# @example ydk events
ydk:events() {
    [[ -z "${YDK_EVENTS_CONFIG[*]}" ]] && declare -A YDK_EVENTS_CONFIG=()
    # @description Publish an event
    publish(){
        ydk:log info "Publishing event $1"
        return 0
    }
    # @description Listen to an event
    on(){
        ydk:log info "Listening to event $1"
        return 0
    }
    # @description Listen to an event once
    once(){
        ydk:log info "Listening to event $1 once"
        return 0
    }
    # @description Remove event listener
    off(){
        ydk:log info "Removing event listener $1"
        return 0
    }
    __events:opts() {
        while [ "$#" -gt 0 ]; do
            case "$1" in            
            *)
                YDK_EVENTS_OPTS+=("$1")
                ;;
            esac
            shift
        done
        return 0
    }
    local YDK_EVENTS_OPTS=() && __events:opts "$@" && set -- "${YDK_EVENTS_OPTS[@]}" && unset YDK_EVENTS_OPTS
    ydk:try "$@" 4>&1
    return $?
}