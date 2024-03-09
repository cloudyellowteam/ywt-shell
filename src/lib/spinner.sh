#!/bin/bash
# shellcheck disable=SC2044,SC2155,SC2317
spinner() {
    local pid=$1
    local delay=0.75
    local spinstr='|/-\'
    while ps a | awk '{print $1}' | grep -q "$pid"; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"

    # local CMD="$*"
    # local SPIN='-\|/'
    # local PID=$(spwan "$CMD")
    # logger info "Spinning PID: $PID"
    # local i=1
    # while true; do
    #     printf "\b%s" "${SPIN:i++%${#SPIN}:1}"
    #     sleep .1
    # done
    # # while kill -0 "$PID" 2>/dev/null; do
    # #     i=$(((i + 1) % 4))
    # #     printf "\r%s" "${SPIN:$i:1}"
    # #     sleep .1
    # # done
    # # printf "\r"
    # # spin() {
    # #     local PID=$(spwan "$CMD")
    # #     logger info "Spinning PID: $PID"
    # #     local i=1
    # #     while true; do
    # #         printf "\b%s" "${SPIN:i++%${#SPIN}:1}"
    # #         sleep .1
    # #     done
    # #     # while kill -0 "$PID" 2>/dev/null; do
    # #     #     i=$(((i + 1) % 4))
    # #     #     printf "\r%s" "${SPIN:$i:1}"
    # #     #     sleep .1
    # #     # done
    # #     # printf "\r"
    # # }
    # # spin & local SPIN_PID=$!
    # # wait "$SPIN_PID"
    # # kill "$SPIN_PID"

    # # local PID_INDEX=$(echo "${RAPD_PIDS[@]}" | grep -n "$PID" | cut -d: -f1)
    # # [ -n "$PID_INDEX" ] && unset "RAPD_PIDS[$PID_INDEX]"
}
(
    export -f spinner
)
