#!/usr/bin/env bash
# # shellcheck disable=SC2044,SC2155,SC2317
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
