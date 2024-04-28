#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:styles() {
    YWT_LOG_CONTEXT="styles"
    apply() {
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
        echo -ne "\e[${STYLE}m${TEXT}\e[0m" >&4
    }
    list() {
        local STYLES=("${!YDK_STYLES[@]}")
        {
            echo -e $'style\techo\tsdk\tcli'
            for STYLE in "${STYLES[@]}"; do
                echo -ne "${STYLE,,}\t"
                echo -ne "${YDK_STYLES[$STYLE]}echo \"\${$STYLE}ydk-shell\${\$NS}\"${YDK_STYLES[NS]}\t"
                echo -ne "$(
                    ydk:styles:"${STYLE,,}" "ydk:styles:${STYLE,,} \"ydk-shell\"" 2>/dev/null
                )\t"
                echo -ne "$(
                    apply "${STYLE,,}" "ydk styles apply ${STYLE,,} \"ydk-shell\"" 4>&1
                )"
                echo
            done
        } | column -t -s $'\t' >&4
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
        echo -e "${NS}${NSTL}${NBG}" >&4
        # local TEXT=${1}
        # local URL=${2}
        # echo -e "\e]8;;${URL}\e\\${TEXT}\e]8;;\e\\"
    }
    ydk:try "$@" 4>&1
    return $?
}
{
    [[ -z "$YDK_STYLES" ]] && declare -g -A YDK_STYLES=(
        [NS]="\033[0m"
        [BOLD]="\033[1m"
        [DIM]="\033[2m"
        [ITALIC]="\033[3m"
        [UNDERLINE]="\033[4m"
        [BLINK]="\033[5m"
        [INVERSE]="\033[7m"
        [HIDDEN]="\033[8m"
        [STRIKETHROUGH]="\033[9m"
    ) && readonly YDK_STYLES && {
        for STYLE in "${!YDK_STYLES[@]}"; do
            STYLE_CODE="${YDK_STYLES[$STYLE]}"
            declare -g "${STYLE^^}=${STYLE_CODE}"
            eval "ydk:styles:${STYLE,,}() { echo -en \"${STYLE_CODE}\${*}${NS}\"; }"
            export -f "ydk:styles:${STYLE,,}"
        done
    }
}

# styles() {
#     YWT_LOG_CONTEXT="styles"
#     apply() {
#         local STYLE=${1:-bold} && STYLE=${STYLE,,}
#         local TEXT=${2}
#         local KIND=${3:-normal} && KIND=${KIND,,}
#         [[ ! $KIND =~ ^(normal|italic|underline|blink|inverse|hidden)$ ]] && KIND=normal
#         case $STYLE in
#         bold) STYLE=1 ;;
#         dim) STYLE=2 ;;
#         italic) STYLE=3 ;;
#         underline) STYLE=4 ;;
#         blink) STYLE=5 ;;
#         inverse) STYLE=7 ;;
#         hidden) STYLE=8 ;;
#         esac
#         echo -e "\e[${STYLE}m${TEXT}\e[0m"
#     }
#     bold(){
#         apply bold "$@"
#     }
#     dim(){
#         apply dim "$@"
#     }
#     italic(){
#         apply italic "$@"
#     }
#     underline(){
#         apply underline "$@"
#     }
#     blink(){
#         apply blink "$@"
#     }
#     inverse(){
#         apply inverse "$@"
#     }
#     hidden(){
#         apply hidden "$@"
#     }
#     __nnf "$@" || usage "styles" "$?"  "$@" && return 1
#     return 0
# }
# (
#     export -f styles
# )
# export NSTL=$'\033[24m' && readonly NSTL
# export BOLD=$'\033[1m' && readonly BOLD
# export DIM=$'\033[2m' && readonly DIM
# export ITALIC=$'\033[3m' && readonly ITALIC
# export UNDERLINE=$'\033[4m' && readonly UNDERLINE
# export BLINK=$'\033[5m' && readonly BLINK
# export INVERSE=$'\033[7m' && readonly INVERSE
# export HIDDEN=$'\033[8m' && readonly HIDDEN
# export STRICKETHROUGH=$'\033[9m' && readonly STRICKETHROUGH
# export YWT_STYLE=(
#     bold dim italic underline blink inverse hidden
# ) && readonly YWT_STYLE
