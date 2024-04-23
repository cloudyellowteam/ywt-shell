#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:await() {
    local YDK_LOGGER_CONTEXT="await"
    [[ -z "$YDK_AWAIT_SPINNERS_FILE" ]] && local YDK_AWAIT_SPINNERS_FILE="/workspace/rapd-shell/assets/spinners.json"
    [[ -z "$YDK_AWAIT_SPECS" ]] && declare -A YDK_AWAIT_SPECS=(
        ["all"]=".[]"
        ["count"]="keys | length"
        ["names"]="keys | .[]"
    ) && readonly YDK_AWAIT_SPECS
    __cursor:back() {
        local N=${1:-1}
        echo -en "\033[${N}D"
        # mac compatible, but goes back to the beginning of the line
    }
    spinners() {
        startup() {
            tput civis
        }

        list() {
            ydk:log info "$(jq -cr "${YDK_AWAIT_SPECS[count]}" "$YDK_AWAIT_SPINNERS_FILE") spinners available"
            jq -c . "$YDK_AWAIT_SPINNERS_FILE" >&4
            return 0
        }
        names() {
            list 4>&1 | jq -cr "${YDK_AWAIT_SPECS[names]}" | tr '\n' ' ' >&4
            return 0
        }
        random() {
            local SPINNERS_NAMES=($(names 4>&1))
            local SPINNER_INDEX=$((RANDOM % ${#SPINNERS_NAMES[@]}))
            local SPINNER_NAME="${SPINNERS_NAMES[$SPINNER_INDEX]}"
            jq -cr ".${SPINNER_NAME} | .name = \"${SPINNER_NAME}\"" "$YDK_AWAIT_SPINNERS_FILE" #>&4
            # list 4>&1 | jq -r "${YDK_AWAIT_SPECS[random]}"
        }
        trap "tput cnorm" EXIT
        trap "tput cnorm" INT
        trap "tput cnorm" TERM
        ydk:try "$@"
        return $?
    }
    spin() {
        local SPINNER_TARGET_PID=$1 && [[ -z "$SPINNER_TARGET_PID" ]] && SPINNER_TARGET_PID=$$
        local SPINNER_MESSAGE="${2:-}"
        local SPINNER=$(spinners random 4>&1)
        local SPINNER_NAME=$(jq -r '.name' <<<"$SPINNER" 2>/dev/null)
        local SPINNER_FRAMES=($(jq -r '.frames | .[]' <<<"$SPINNER" 2>/dev/null | tr '\n' ' '))
        local SPINNER_INTERVAL=$(jq -r '.interval' <<<"$SPINNER" 2>/dev/null)
        local SPINNER_LENGTH=${#SPINNER_FRAMES[@]}
        local SPINNER_INDEX=0

        local SPINNER_MESSAGE="${2:-}"
        #$(ps -p "$SPINNER_TARGET_PID" -o comm=) && SPINNER_MESSAGE="$SPINNER_MESSAGE($SPINNER_TARGET_PID)"
        while ps a | awk '{print $1}' | grep -q "$SPINNER_TARGET_PID"; do
            local FRAME=${SPINNER_FRAMES[$SPINNER_INDEX]}
            printf " %s  %s\r" "$FRAME" "$SPINNER_MESSAGE" 1>&2
            SPINNER_INDEX=$(((SPINNER_INDEX + 1) % SPINNER_LENGTH))
            sleep "$((SPINNER_INTERVAL / 500))"
            __cursor:back 1
            printf "\b\b\b\b\b\b" 1>&2
        done
        printf "\b\b\b\b" 1>&2
        return 0
    }
    examples() {
        # loop into each name
        local COMMANDS=()
        local SPINNERS_NAMES=($(spinners names 4>&1))
        local SPINNER_INDEX=0
        for SPINNER_NAME in "${SPINNERS_NAMES[@]}"; do
            local MESSAGE="Spinner $SPINNER_NAME ${SPINNER_INDEX} of ${#SPINNERS_NAMES[@]}"
            # ydk:log info "$MESSAGE"
            COMMANDS+=("sleep $((SPINNER_INDEX + 1 * 30)); echo $MESSAGE")
            SPINNER_INDEX=$((SPINNER_INDEX + 1))
        done
        ydk:async "${COMMANDS[@]}" 1>&2
    }

    ydk:try "$@"
    return $?
}
