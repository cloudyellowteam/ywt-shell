#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:colors() {
    inspect(){
        local COLORS=("${!YDK_COLORS[@]}")
        for COLOR in "${COLORS[@]}"; do
            echo -n "${COLOR}: "
            # echo -ne "${YDK_COLORS[$COLOR]}${COLOR}${NC}${NBG} / "
            ydk:colors:"${COLOR,,}" " ${COLOR} " && echo
        done
    
    }
    ydk:try "$@"
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
        [[ -n "$NO_COLOR" ]] && [[ "$NO_COLOR" == 1 || "$NO_COLOR" == true ]] && return 0
        for COLOR in "${!YDK_COLORS[@]}"; do
            COLOR_CODE="${YDK_COLORS[$COLOR]}"
            # export "${COLOR^^}=${COLOR_CODE}"
            declare -g "${COLOR^^}=${COLOR_CODE}"
            eval "ydk:colors:${COLOR,,}() { echo -en \"${COLOR_CODE}\${*}${NC}${NBG}\"; }"
            export -f "ydk:colors:${COLOR,,}"
            #echo "ydk:colors:${COLOR,,}"
            # "ydk:colors:${COLOR,,}" Cloud Yellow Team && echo
        done
    fi
}
