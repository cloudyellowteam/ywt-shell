#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317

wysiwyg() {
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
    style() {
        local STYLE=${1:-bold} && STYLE=${STYLE,,}
        local TEXT=${2}
        local KIND=${3:-normal} && KIND=${KIND,,}
        [[ ! $KIND =~ ^(normal|italic|underline|blink|inverse|hidden)$ ]] && KIND=normal
        case $STYLE in
        bold) STYLE=1 ;;
        dim) STYLE=2 ;;
        italic) STYLE=3 ;;
        underline) STYLE=4 ;;
        blink) STYLE=5 ;;
        inverse) STYLE=7 ;;
        hidden) STYLE=8 ;;
        esac
        echo -e "\e[${STYLE}m${TEXT}\e[0m"

    }
    colorize() {
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
        # local COLOR=${1:-white} && COLOR=${COLOR,,}
        # local TEXT=${2}
        # local KIND=${3:-foreground} && KIND=${KIND,,}
        # [[ ! $KIND =~ ^(foreground|background|fg|bg)$ ]] && KIND=foreground
        # case $COLOR in
        # black) COLOR=30 ;;
        # bright-black) COLOR=90 ;;
        # red) COLOR=31 ;;
        # bright-red) COLOR=91 ;;
        # green) COLOR=32 ;;
        # bright-green) COLOR=92 ;;
        # yellow) COLOR=33 ;;
        # bright-yellow) COLOR=93 ;;
        # blue) COLOR=34 ;;
        # bright-blue) COLOR=94 ;;
        # magenta) COLOR=35 ;;
        # bright-magenta) COLOR=95 ;;
        # cyan) COLOR=36 ;;
        # bright-cyan) COLOR=96 ;;
        # white) COLOR=37 ;;
        # bright-white) COLOR=97 ;;
        # gray) COLOR=90 ;;
        # bright-gray) COLOR=37 ;;
        # purple) COLOR=35 ;;
        # bright-purple) COLOR=95 ;;
        # esac
        # [[ $KIND == "background" || $KIND == "bg" ]] && COLOR=$((COLOR + 10))
        # echo -e "\e[${COLOR}m${TEXT}\e[0m"
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
        echo -en "${NC}${NSTL}${NBG}"
        # local TEXT=${1}
        # local URL=${2}
        # echo -e "\e]8;;${URL}\e\\${TEXT}\e]8;;\e\\"
    }
    nnf "$@" || usage "$?" "$@" && return 1
}
(
    export -f wysiwyg
)
export YWT_COLORS=(
    black black-bg bright-black dark-gray dark-gray-bg red red-bg bright-red green green-bg bright-green yellow yellow-bg bright-yellow blue blue-bg bright-blue purple purple-bg bright-purple cyan cyan-bg bright-cyan gray gray-bg bright-gray white white-bg bright-white
) && readonly YWT_COLORS
export YWT_STYLE=(
    bold dim italic underline blink inverse hidden
) && readonly YWT_STYLE
export BLACK=$'\033[0;30m' && readonly BLACK
export BLACK_BG=$'\033[40m' && readonly BLACK_BG
export BRIGHT_BLACK=$'\033[1;30m' && readonly BRIGHT_BLACK
export DARK_GRAY=$'\033[1;30m' && readonly DARK_GRAY
export DARK_GRAY_BG=$'\033[100m' && readonly DARK_GRAY_BG
export RED=$'\033[0;31m' && readonly RED
export RED_BG=$'\033[41m' && readonly RED_BG
export BRIGHT_RED=$'\033[1;31m' && readonly BRIGHT_RED
export GREEN=$'\033[0;32m' && readonly GREEN
export GREEN_BG=$'\033[42m' && readonly GREEN_BG
export BRIGHT_GREEN=$'\033[1;32m' && readonly BRIGHT_GREEN
export YELLOW=$'\033[0;33m' && readonly YELLOW
export YELLOW_BG=$'\033[43m' && readonly YELLOW_BG
export BRIGHT_YELLOW=$'\033[1;33m' && readonly BRIGHT_YELLOW
export BLUE=$'\033[0;34m' # export BLUE=$'\e[34m' && readonly BLUE
export BLUE_BG=$'\033[44m' && readonly BLUE_BG
export BRIGHT_BLUE=$'\033[1;34m' && readonly BRIGHT_BLUE
export PURPLE=$'\033[0;35m' && readonly PURPLE
export PURPLE_BG=$'\033[45m' && readonly PURPLE_BG
export BRIGHT_PURPLE=$'\033[1;35m' && readonly BRIGHT_PURPLE
export CYAN=$'\033[0;36m' && readonly CYAN
export CYAN_BG=$'\033[46m' && readonly CYAN_BG
export BRIGHT_CYAN=$'\033[1;36m' && readonly BRIGHT_CYAN
export GRAY=$'\033[0;37m' && readonly GRAY
export GRAY_BG=$'\033[47m' && readonly GRAY_BG
export BRIGHT_GRAY=$'\033[1;37m' && readonly BRIGHT_GRAY
export WHITE=$'\033[0;37m' && readonly WHITE
export WHITE_BG=$'\033[107m' && readonly WHITE_BG
export BRIGHT_WHITE=$'\033[1;37m' && readonly BRIGHT_WHITE
export BOLD=$'\033[1m' && readonly BOLD
export DIM=$'\033[2m' && readonly DIM
export ITALIC=$'\033[3m' && readonly ITALIC
export UNDERLINE=$'\033[4m' && readonly UNDERLINE
export BLINK=$'\033[5m' && readonly BLINK
export INVERSE=$'\033[7m' && readonly INVERSE
export HIDDEN=$'\033[8m' && readonly HIDDEN
export STRICKETHROUGH=$'\033[9m' && readonly STRICKETHROUGH
export NC=$'\033[0m' && readonly NC
export NBG=$'\033[49m' && readonly NBG
export NSTL=$'\033[24m' && readonly NSTL
