#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317

colors() {
    YWT_LOG_CONTEXT="colors"
    rainbow() {
        local TEXT=${1:-$YWT_CMD_FILE} && shift
        local COLORS=("${@}") && [ ${#COLORS[@]} -eq 0 ] && COLORS=("${YWT_COLORS[@]}")
        local COLOR_COUNT=${#COLORS[@]}
        local LENGTH=${#TEXT}
        local INDEX=0
        for ((i = 0; i < LENGTH; i++)); do
            local CHAR=${TEXT:$i:1}
            local COLOR=${COLORS[$INDEX]}
            local COLOR_CODE=$(colorize "$COLOR" "$CHAR")
            echo -n "$COLOR_CODE"
            INDEX=$((INDEX + 1))
            [[ $INDEX -ge $COLOR_COUNT ]] && INDEX=0
        done
        echo
    }
    apply() {
        local VAR=${1:-"NC"} && VAR=${VAR^^}
        local VARS=("${YWT_COLORS[@]}" "${YWT_STYLE[@]}")
        local IS_VALID=false
        for ITEM in "${VARS[@]}"; do
            [[ "${ITEM^^}" == "${VAR}" ]] && IS_VALID=true && break
        done
        [[ "$IS_VALID" == false ]] && VAR="NC"
        local KIND=fg
        [[ $VAR =~ bg$ ]] && KIND="bg"
        [[ $VAR =~ ^(bold|dim|italic|underline|blink|inverse|hidden)$ ]] && KIND=style
        VAR=${VAR//-/_}
        local COLOR=${VAR%%-*}
        [[ $KIND == "bg" || $KIND == "bg" ]] && COLOR=$((COLOR + 10))
        local TEXT=${2} # && while read -r LINE; do echo -e "$LINE"; done <<<"$TEXT"
        echo -e "\e[${!VAR}${TEXT}\e[0m${NC}"
        return 0        
    }
    hyperlink() {
        local OSC=$'\e]'
        local BEL=$'\a'
        local SEP=';'
        local PARAM_SEP=':'
        local EQ='='        
        local URI=$1
        local TEXT=$2
        local PARAMS=$3

        local PARAM_STR=""
        for PARAM in "${!PARAMS[@]}"; do
            PARAM_STR+="${PARAM}${EQ}${PARAMS[$param]}${PARAM_SEP}"
        done

        # Remove the trailing PARAM_SEP
        PARAM_STR=${PARAM_STR%"$PARAM_SEP"}

        printf "%s8%s%s%s%s%s%s%s8%s%s%s" "$OSC" "$SEP" "$PARAM_STR" "$SEP" "$URI" "$BEL" "$TEXT" "$OSC" "$SEP" "$SEP" "$BEL"
        echo -e "${NC}${NSTL}${NBG}"
        # local TEXT=${1}
        # local URL=${2}
        # echo -e "\e]8;;${URL}\e\\${TEXT}\e]8;;\e\\"
    }
    __nnf "$@" || usage "$?" "$@" && return 1
}
(
    export -f colors
)
export NO_COLOR=${NO_COLOR:-false} && readonly NO_COLOR
export YWT_COLORS=(
    black black-bg bright-black dark-gray dark-gray-bg red red-bg bright-red green green-bg bright-green yellow yellow-bg bright-yellow blue blue-bg bright-blue purple purple-bg bright-purple cyan cyan-bg bright-cyan gray gray-bg bright-gray white white-bg bright-white
) && readonly YWT_COLORS
export BLACK=$'\033[0;30m' && [ "$NO_COLOR" == true ] && BLACK="" && readonly BLACK BLACK
export BLACK_BG=$'\033[40m' && [ "$NO_COLOR" == true ] && BLACK_BG="" && readonly BLACK_BG
export BRIGHT_BLACK=$'\033[1;30m' && [ "$NO_COLOR" == true ] && BRIGHT_BLACK="" && readonly BRIGHT_BLACK
export DARK_GRAY=$'\033[1;30m' && [ "$NO_COLOR" == true ] && DARK_GRAY="" && readonly DARK_GRAY
export DARK_GRAY_BG=$'\033[100m' && [ "$NO_COLOR" == true ] && DARK_GRAY_BG="" && readonly DARK_GRAY_BG
export RED=$'\033[0;31m' && [ "$NO_COLOR" == true ] && RED="" && readonly RED
export RED_BG=$'\033[41m' && [ "$NO_COLOR" == true ] && RED_BG="" && readonly RED_BG
export BRIGHT_RED=$'\033[1;31m' && [ "$NO_COLOR" == true ] && BRIGHT_RED="" && readonly BRIGHT_RED
export GREEN=$'\033[0;32m' && [ "$NO_COLOR" == true ] && GREEN="" && readonly GREEN
export GREEN_BG=$'\033[42m' && [ "$NO_COLOR" == true ] && GREEN_BG="" && readonly GREEN_BG
export BRIGHT_GREEN=$'\033[1;32m' && [ "$NO_COLOR" == true ] && BRIGHT_GREEN="" && readonly BRIGHT_GREEN
export YELLOW=$'\033[0;33m' && [ "$NO_COLOR" == true ] && YELLOW="" && readonly YELLOW
export YELLOW_BG=$'\033[43m' && [ "$NO_COLOR" == true ] && YELLOW_BG="" && readonly YELLOW_BG
export BRIGHT_YELLOW=$'\033[1;33m' && [ "$NO_COLOR" == true ] && BRIGHT_YELLOW="" && readonly BRIGHT_YELLOW
export BLUE=$'\033[0;34m' && [ "$NO_COLOR" == true ] && BLUE="" && readonly BLUE
export BLUE_BG=$'\033[44m' && [ "$NO_COLOR" == true ] && BLUE_BG="" && readonly BLUE_BG
export BRIGHT_BLUE=$'\033[1;34m' &&[ "$NO_COLOR" == true ] && BRIGHT_BLUE="" && readonly BRIGHT_BLUE
export PURPLE=$'\033[0;35m' && [ "$NO_COLOR" == true ] && PURPLE="" && readonly PURPLE
export PURPLE_BG=$'\033[45m' && [ "$NO_COLOR" == true ] && PURPLE_BG="" && readonly PURPLE_BG
export BRIGHT_PURPLE=$'\033[1;35m' && [ "$NO_COLOR" == true ] && BRIGHT_PURPLE="" && readonly BRIGHT_PURPLE
export CYAN=$'\033[0;36m' && [ "$NO_COLOR" == true ] && CYAN="" && readonly CYAN
export CYAN_BG=$'\033[46m' && [ "$NO_COLOR" == true ] && CYAN_BG="" && readonly CYAN_BG
export BRIGHT_CYAN=$'\033[1;36m' && [ "$NO_COLOR" == true ] && BRIGHT_CYAN="" && readonly BRIGHT_CYAN
export GRAY=$'\033[0;37m' && [ "$NO_COLOR" == true ] && GRAY="" && readonly GRAY
export GRAY_BG=$'\033[47m' && [ "$NO_COLOR" == true ] && GRAY_BG="" && readonly GRAY_BG
export BRIGHT_GRAY=$'\033[1;37m' && [ "$NO_COLOR" == true ] && BRIGHT_GRAY="" && readonly BRIGHT_GRAY
export WHITE=$'\033[0;37m' && [ "$NO_COLOR" == true ] && WHITE="" && readonly WHITE
export WHITE_BG=$'\033[107m' && [ "$NO_COLOR" == true ] && WHITE_BG="" && readonly WHITE_BG
export BRIGHT_WHITE=$'\033[1;37m' && [ "$NO_COLOR" == true ] && BRIGHT_WHITE="" && readonly BRIGHT_WHITE
export NC=$'\033[0m' && [ "$NO_COLOR" == true ] && NC="" && readonly NC
export NBG=$'\033[49m' && [ "$NO_COLOR" == true ] && NBG="" && readonly NBG

