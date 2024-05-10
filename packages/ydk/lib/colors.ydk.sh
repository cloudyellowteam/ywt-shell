#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:colors() {
    [[ -z "$LAST_RANDOM_COLOR_NAME" ]] && local LAST_RANDOM_COLOR_NAME="NC"
    inspect() {
        {
            local COLORS=("${!YDK_COLORS[@]}")
            for COLOR in "${COLORS[@]}"; do
                echo -n "${COLOR}: "
                # echo -ne "${YDK_COLORS[$COLOR]}${COLOR}${NC}${NBG} / "
                ydk:colors:"${COLOR,,}" " ${COLOR} " 4>&1 >&1
                echo
            done
        } >&4
    }
    random() {
        local RANDOM_KIND="${1}"
        # local TEXT=${1} && shift
        while true; do
            local RANDOM_COLOR=$((RANDOM % ${#YDK_COLORS_NAMES[@]}))
            case "$RANDOM_KIND" in
            f | fg | foreground)
                [[ "$RANDOM_COLOR" == *"_BG " ]] && continue
                ;;
            b | bg | background)
                [[ "$RANDOM_COLOR" != *"_BG " ]] && continue
                ;;
            *)
                local TEXT=${1}
                # local RANDOM_COLOR=$((RANDOM % ${#YDK_COLORS_NAMES[@]}))
                ;;
            esac
            [[ $LAST_RANDOM_COLOR_NAME != "$RANDOM_COLOR" ]] && break
        done
        LAST_RANDOM_COLOR_NAME=RANDOM_COLOR
        local RANDOM_COLOR="${YDK_COLORS_NAMES[RANDOM_COLOR]}"
        local RANDOM_COLOR="${YDK_COLORS[$RANDOM_COLOR]}"
        if [[ -n "$TEXT" ]]; then
            echo -ne "${RANDOM_COLOR}${TEXT}${NC}${NBG}" >&4
        else
            echo -en "${RANDOM_COLOR}" >&4
        fi

        return 0
        # local COLORS_RANDOM_INDEX=$((RANDOM % ${#YDK_COLORS[@]}))
        # local COLOR_RANDOM="${YDK_COLORS[$COLORS_RANDOM_INDEX]}"
        # echo -n "${COLOR_RANDOM}" >&4
    }
    rainbow() {
        local TEXT=${1} && shift
        local COLORS=("${@}") && [ ${#COLORS[@]} -eq 0 ] && COLORS=("${YDK_COLORS[@]}")
        # local COLOR_COUNT=${#YDK_COLORS[@]}
        local TEXT_LENGTH=${#TEXT}
        # local INDEX=0
        {
            for ((i = 0; i < TEXT_LENGTH; i++)); do
                local CHAR=${TEXT:$i:1}
                local CHAR_TRIM=$(echo -n "$CHAR" | tr -d '[:space:]')
                if [[ -n "$CHAR_TRIM" ]]; then
                    local RANDOM_COLOR=$((RANDOM % ${#COLORS[@]}))
                    local COLOR_CODE=${COLORS[$RANDOM_COLOR]}
                    # echo -en "$RANDOM_COLOR/${COLOR_CODE}"
                    echo -en "${COLOR_CODE}${CHAR}${NC}${NBG}"
                    # local COLOR_CODE=${COLORS[$INDEX]}
                    # echo -en "${COLOR_CODE}${CHAR}${NC}${NBG}"
                    # INDEX=$((INDEX + 1))
                    # [[ $INDEX -ge $COLOR_COUNT ]] && INDEX=0
                    continue
                fi
                echo -n "$CHAR"
                # random "${CHAR}" 4>&1
                # get random color from the list
                # local COLOR=$(random "${CHAR}" 4>&1)
                # echo -ne "${COLOR}${CHAR}${NC}${NBG}"
                # local COLOR=${COLORS[$INDEX]}
                # echo -n "${YDK_COLORS[$COLOR]}${CHAR}${NC}${NBG}"
                # local COLOR_CODE=$(colorize "$COLOR" "$CHAR")
                # echo -n "$COLOR_CODE"

            done
            echo
        } >&4
        return 0
    }
    ydk:try "$@" 4>&1
    return $?
}
{
    if [[ -z "$YDK_COLORS" ]]; then
        declare -g -A YDK_COLORS=(
            [NC]="\033[0m"
            [NBG]="\033[49m"
            [BLACK]="\033[0;30m"
            [BLACK_BG]="\033[40m"
            [BRIGHT_BLACK]="\033[1;30m"
            [BRIGHT_BLACK_BG]="\033[100m"
            [DARK_GRAY]="\033[1;30m"
            [DARK_GRAY_BG]="\033[100m"
            [RED]="\033[0;31m"
            [RED_BG]="\033[41m"
            [BRIGHT_RED]="\033[1;31m"
            [GREEN]="\033[0;32m"
            [GREEN_BG]="\033[42m"
            [BRIGHT_GREEN]="\033[1;32m"
            [YELLOW]="\033[0;33m"
            [YELLOW_BG]="\033[43m"
            [BRIGHT_YELLOW]="\033[1;33m"
            [BLUE]="\033[0;34m"
            [BLUE_BG]="\033[44m"
            [BRIGHT_BLUE]="\033[1;34m"
            [PURPLE]="\033[0;35m"
            [PURPLE_BG]="\033[45m"
            [BRIGHT_PURPLE]="\033[1;35m"
            [CYAN]="\033[0;36m"
            [CYAN_BG]="\033[46m"
            [BRIGHT_CYAN]="\033[1;36m"
            [GRAY]="\033[0;37m"
            [GRAY_BG]="\033[47m"
            [BRIGHT_GRAY]="\033[1;37m"
            [WHITE]="\033[0;37m"
            [WHITE_BG]="\033[107m"
            [BRIGHT_WHITE]="\033[1;37m"
        ) && readonly YDK_COLORS
        declare -g -a YDK_COLORS_NAMES=(
            "BLACK" "BLACK_BG" "BRIGHT_BLACK" "BRIGHT_BLACK_BG" "DARK_GRAY" "DARK_GRAY_BG" "RED" "RED_BG" "BRIGHT_RED" "GREEN" "GREEN_BG" "BRIGHT_GREEN" "YELLOW" "YELLOW_BG" "BRIGHT_YELLOW" "BLUE" "BLUE_BG" "BRIGHT_BLUE" "PURPLE" "PURPLE_BG" "BRIGHT_PURPLE" "CYAN" "CYAN_BG" "BRIGHT_CYAN" "GRAY" "GRAY_BG" "BRIGHT_GRAY" "WHITE" "WHITE_BG" "BRIGHT_WHITE"
        ) && readonly YDK_COLORS_NAMES && export YDK_COLORS_NAMES
        [[ -n "$NO_COLOR" ]] && [[ "$NO_COLOR" == 1 || "$NO_COLOR" == true ]] && return 0
        for COLOR in "${!YDK_COLORS[@]}"; do
            COLOR_CODE="${YDK_COLORS[$COLOR]}"
            # export "${COLOR^^}=${COLOR_CODE}"
            declare -g "${COLOR^^}=${COLOR_CODE}"
            eval "ydk:colors:${COLOR,,}() { echo -en \"${COLOR_CODE}\${*}${NC}${NBG}\" >&1; }"
            export -f "ydk:colors:${COLOR,,}"
            #echo "ydk:colors:${COLOR,,}"
            # "ydk:colors:${COLOR,,}" Cloud Yellow Team && echo
        done
    fi
}
#!/usr/bin/env bash
# # shellcheck disable=SC2044,SC2155,SC2317
#
# colors() {
#     YWT_LOG_CONTEXT="colors"
#     rainbow() {
#         local TEXT=${1:-$YWT_CMD_FILE} && shift
#         local COLORS=("${@}") && [ ${#COLORS[@]} -eq 0 ] && COLORS=("${YWT_COLORS[@]}")
#         local COLOR_COUNT=${#COLORS[@]}
#         local LENGTH=${#TEXT}
#         local INDEX=0
#         for ((i = 0; i < LENGTH; i++)); do
#             local CHAR=${TEXT:$i:1}
#             local COLOR=${COLORS[$INDEX]}
#             local COLOR_CODE=$(colorize "$COLOR" "$CHAR")
#             echo -n "$COLOR_CODE"
#             INDEX=$((INDEX + 1))
#             [[ $INDEX -ge $COLOR_COUNT ]] && INDEX=0
#         done
#         echo
#     }
#     apply() {
#         local VAR=${1:-"NC"} && VAR=${VAR^^}
#         local VARS=("${YWT_COLORS[@]}" "${YWT_STYLE[@]}")
#         local IS_VALID=false
#         for ITEM in "${VARS[@]}"; do
#             [[ "${ITEM^^}" == "${VAR}" ]] && IS_VALID=true && break
#         done
#         [[ "$IS_VALID" == false ]] && VAR="NC"
#         local KIND=fg
#         [[ $VAR =~ bg$ ]] && KIND="bg"
#         [[ $VAR =~ ^(bold|dim|italic|underline|blink|inverse|hidden)$ ]] && KIND=style
#         VAR=${VAR//-/_}
#         local COLOR=${VAR%%-*}
#         [[ $KIND == "bg" || $KIND == "bg" ]] && COLOR=$((COLOR + 10))
#         local TEXT=${2} # && while read -r LINE; do echo -e "$LINE"; done <<<"$TEXT"
#         echo -e "\e[${!VAR}${TEXT}\e[0m${NC}"
#         return 0
#     }
#     hyperlink() {
#         local OSC=$'\e]'
#         local BEL=$'\a'
#         local SEP=';'
#         local PARAM_SEP=':'
#         local EQ='='
#         local URI=$1
#         local TEXT=$2
#         local PARAMS=$3
#
#         local PARAM_STR=""
#         for PARAM in "${!PARAMS[@]}"; do
#             PARAM_STR+="${PARAM}${EQ}${PARAMS[$param]}${PARAM_SEP}"
#         done
#
#         # Remove the trailing PARAM_SEP
#         PARAM_STR=${PARAM_STR%"$PARAM_SEP"}
#
#         printf "%s8%s%s%s%s%s%s%s8%s%s%s" "$OSC" "$SEP" "$PARAM_STR" "$SEP" "$URI" "$BEL" "$TEXT" "$OSC" "$SEP" "$SEP" "$BEL"
#         echo -e "${NC}${NSTL}${NBG}"
#         # local TEXT=${1}
#         # local URL=${2}
#         # echo -e "\e]8;;${URL}\e\\${TEXT}\e]8;;\e\\"
#     }
#     __nnf "$@" || usage "colors" "$?" "$@" && return 1
# }
# (
#     export -f colors
# )
# export NO_COLOR=${NO_COLOR:-false} && readonly NO_COLOR
# export YWT_COLORS=(
#     black black-bg bright-black dark-gray dark-gray-bg red red-bg bright-red green green-bg bright-green yellow yellow-bg bright-yellow blue blue-bg bright-blue purple purple-bg bright-purple cyan cyan-bg bright-cyan gray gray-bg bright-gray white white-bg bright-white
# ) && readonly YWT_COLORS
# export BLACK=$'\033[0;30m' && [ "$NO_COLOR" == true ] && BLACK="" && readonly BLACK BLACK
# export BLACK_BG=$'\033[40m' && [ "$NO_COLOR" == true ] && BLACK_BG="" && readonly BLACK_BG
# export BRIGHT_BLACK=$'\033[1;30m' && [ "$NO_COLOR" == true ] && BRIGHT_BLACK="" && readonly BRIGHT_BLACK
# export DARK_GRAY=$'\033[1;30m' && [ "$NO_COLOR" == true ] && DARK_GRAY="" && readonly DARK_GRAY
# export DARK_GRAY_BG=$'\033[100m' && [ "$NO_COLOR" == true ] && DARK_GRAY_BG="" && readonly DARK_GRAY_BG
# export RED=$'\033[0;31m' && [ "$NO_COLOR" == true ] && RED="" && readonly RED
# export RED_BG=$'\033[41m' && [ "$NO_COLOR" == true ] && RED_BG="" && readonly RED_BG
# export BRIGHT_RED=$'\033[1;31m' && [ "$NO_COLOR" == true ] && BRIGHT_RED="" && readonly BRIGHT_RED
# export GREEN=$'\033[0;32m' && [ "$NO_COLOR" == true ] && GREEN="" && readonly GREEN
# export GREEN_BG=$'\033[42m' && [ "$NO_COLOR" == true ] && GREEN_BG="" && readonly GREEN_BG
# export BRIGHT_GREEN=$'\033[1;32m' && [ "$NO_COLOR" == true ] && BRIGHT_GREEN="" && readonly BRIGHT_GREEN
# export YELLOW=$'\033[0;33m' && [ "$NO_COLOR" == true ] && YELLOW="" && readonly YELLOW
# export YELLOW_BG=$'\033[43m' && [ "$NO_COLOR" == true ] && YELLOW_BG="" && readonly YELLOW_BG
# export BRIGHT_YELLOW=$'\033[1;33m' && [ "$NO_COLOR" == true ] && BRIGHT_YELLOW="" && readonly BRIGHT_YELLOW
# export BLUE=$'\033[0;34m' && [ "$NO_COLOR" == true ] && BLUE="" && readonly BLUE
# export BLUE_BG=$'\033[44m' && [ "$NO_COLOR" == true ] && BLUE_BG="" && readonly BLUE_BG
# export BRIGHT_BLUE=$'\033[1;34m' &&[ "$NO_COLOR" == true ] && BRIGHT_BLUE="" && readonly BRIGHT_BLUE
# export PURPLE=$'\033[0;35m' && [ "$NO_COLOR" == true ] && PURPLE="" && readonly PURPLE
# export PURPLE_BG=$'\033[45m' && [ "$NO_COLOR" == true ] && PURPLE_BG="" && readonly PURPLE_BG
# export BRIGHT_PURPLE=$'\033[1;35m' && [ "$NO_COLOR" == true ] && BRIGHT_PURPLE="" && readonly BRIGHT_PURPLE
# export CYAN=$'\033[0;36m' && [ "$NO_COLOR" == true ] && CYAN="" && readonly CYAN
# export CYAN_BG=$'\033[46m' && [ "$NO_COLOR" == true ] && CYAN_BG="" && readonly CYAN_BG
# export BRIGHT_CYAN=$'\033[1;36m' && [ "$NO_COLOR" == true ] && BRIGHT_CYAN="" && readonly BRIGHT_CYAN
# export GRAY=$'\033[0;37m' && [ "$NO_COLOR" == true ] && GRAY="" && readonly GRAY
# export GRAY_BG=$'\033[47m' && [ "$NO_COLOR" == true ] && GRAY_BG="" && readonly GRAY_BG
# export BRIGHT_GRAY=$'\033[1;37m' && [ "$NO_COLOR" == true ] && BRIGHT_GRAY="" && readonly BRIGHT_GRAY
# export WHITE=$'\033[0;37m' && [ "$NO_COLOR" == true ] && WHITE="" && readonly WHITE
# export WHITE_BG=$'\033[107m' && [ "$NO_COLOR" == true ] && WHITE_BG="" && readonly WHITE_BG
# export BRIGHT_WHITE=$'\033[1;37m' && [ "$NO_COLOR" == true ] && BRIGHT_WHITE="" && readonly BRIGHT_WHITE
# export NC=$'\033[0m' && [ "$NO_COLOR" == true ] && NC="" && readonly NC
# export NBG=$'\033[49m' && [ "$NO_COLOR" == true ] && NBG="" && readonly NBG
#
