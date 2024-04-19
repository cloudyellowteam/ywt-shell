#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:spinner() {
    ydk:try "$@"
    return $?
}

# spinner() {
#     local SPINNERS_TMP_FILE=/tmp/ywt-spinners.json
#     # local SPINNERS_LIST=
#     __spinner:list() {
#         if [[ -f "$SPINNERS_TMP_FILE" ]]; then
#             jq -c . "$SPINNERS_TMP_FILE"
#             return 0
#         fi
#         echo "Downloading spinners list..." | logger info
#         curl -sL https://raw.githubusercontent.com/sindresorhus/cli-spinners/main/spinners.json >"$SPINNERS_TMP_FILE"
#         jq -c . "$SPINNERS_TMP_FILE"
#         return 0
#     }
#     __spinner:shutdown() {
#         tput cnorm
#     }
#     __spinner:startup() {
#         tput civis
#     }
#     __spinner:trap() {
#         trap __spin:shutdown EXIT
#         trap __spin:shutdown INT
#         trap __spin:shutdown TERM
#     }
#     __spinner:cursor:back() {
#         local N=${1:-1}
#         echo -en "\033[${N}D"
#         # mac compatible, but goes back to the beginning of the line
#     }
#     names() {
#         __spinner:list >/dev/null
#         jq -r 'keys | .[]' "$SPINNERS_TMP_FILE" | tr '\n' ' '
#     }
#     random() {
#         if [ "${#SPINNERS_LIST}" -eq 0 ]; then
#             local SPINNERS_NAMES=($(names))
#         else
#             local SPINNERS_NAMES=("$@")
#         fi
#         local SPINNER_INDEX=$((RANDOM % ${#SPINNERS_NAMES[@]}))
#         local SPINNER_NAME="${SPINNERS_NAMES[$SPINNER_INDEX]}"
#         jq -r ".${SPINNER_NAME} | .name = \"${SPINNER_NAME}\"" "$SPINNERS_TMP_FILE"
#     }
#     spin() {
#         local SPINNER=$(random)
#         local SPINNER_NAME=$(jq -r '.name' <<<"$SPINNER")
#         local SPINNER_FRAMES=($(jq -r '.frames | .[]' <<<"$SPINNER" | tr '\n' ' '))
#         local SPINNER_INTERVAL=$(jq -r '.interval' <<<"$SPINNER")
#         local SPINNER_LENGTH=${#SPINNER_FRAMES[@]}
#         local SPINNER_INDEX=0
#         local SPINNER_TARGET_PID=$1
#         local SPINNER_MESSAGE="${2:-}"
#         #$(ps -p "$SPINNER_TARGET_PID" -o comm=) && SPINNER_MESSAGE="$SPINNER_MESSAGE($SPINNER_TARGET_PID)"
#         while ps a | awk '{print $1}' | grep -q "$SPINNER_TARGET_PID"; do
#             local FRAME=${SPINNER_FRAMES[$SPINNER_INDEX]}
#             printf " %s  %s\r" "$FRAME" "$SPINNER_MESSAGE"
#             SPINNER_INDEX=$(((SPINNER_INDEX + 1) % SPINNER_LENGTH))
#             sleep "$((SPINNER_INTERVAL / 500))"
#             __spinner:cursor:back 1
#             printf "\b\b\b\b\b\b"
#         done
#         printf "\b\b\b\b"
#     }
#     examples(){
#         # loop into each name
#         local COMMANDS=()
#         local SPINNERS_NAMES=($(names))
#         local SPINNER_INDEX=0
#         for SPINNER_NAME in "${SPINNERS_NAMES[@]}"; do
#             local MESSAGE="Spinner $SPINNER_NAME ${SPINNER_INDEX} of ${#SPINNERS_NAMES[@]}"
#             echo "$MESSAGE" | logger info
#             COMMANDS+=("sleep ${SPINNER_INDEX}; echo $MESSAGE")
#             SPINNER_INDEX=$((SPINNER_INDEX + 1))
#         done
#         async "${COMMANDS[@]}"
#     }
# 
#     __nnf "$@" || usage "$?" "spinner" "$@" && return 1
#     return 0
# }
