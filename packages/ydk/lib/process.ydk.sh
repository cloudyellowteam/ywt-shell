#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:process() {
    etime() {
        if grep -q 'Alpine' /etc/os-release; then
            ps -o etime= "$$" | awk -F "[:]" '{ print ($1 * 60) + $2 }' | head -n 1
        else
            ps -o etime= -p "$$" | sed -e 's/^[[:space:]]*//' | sed -e 's/\://' | head -n 1
        fi
    }
    stdin() {
        [ ! -p /dev/stdin ] && [ ! -t 0 ] && return "$1"
        while IFS= read -r INPUT; do
            echo "$INPUT" >&0
        done
        unset INPUT
    }
    stdout() {
        [ ! -p /dev/stdout ] && [ ! -t 1 ] && return "$1"
        while IFS= read -r OUTPUT; do
            echo "$OUTPUT" >&1
        done
        unset OUTPUT
    }
    stderr() {
        [ ! -p /dev/stderr ] && [ ! -t 2 ] && return "$1"
        while IFS= read -r ERROR; do
            echo "$ERROR" >&2
        done
        unset ERROR
    }
    stdvalue(){
        local STD="${1:-4}"        
        [ -e /proc/$$/fd/"$STD" ] && echo "$@" >&"$STD" && return 0
        return 1
    }
    stdio() {
        stdin "$1" && stdout "$1" && stderr "$1"
    }
    
    inspect(){
        jq -cn \
            --arg pid "$$" \
            --arg etime "$(etime)" \
            --argjson cli "$(ydk:cli)" \
            --argjson package "{}" \
            '{ 
                pid: $pid,
                etime: $etime,
                cli: $cli,
                package: $package
            }'
    }
    ydk:try "$@"
    return $?
}
