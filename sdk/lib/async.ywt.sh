#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317,SC2120
async() {
    YWT_LOG_CONTEXT="ASYNC"
    # local SPINNERS_TMP_FILE=/tmp/ywt-spinners.json
    # # local ASYNC_ARGS=()
    # # while [[ "$#" -gt 0 ]]; do
    # #     case $1 in
    # #     -s | --spinner)
    # #         local ASYNC_PARAM_SPINNER=$2
    # #         shift 2
    # #         ;;
    # #     *)
    # #         ASYNC_ARGS+=("$1")
    # #         shift
    # #         ;;
    # #     esac
    # # done
    # # set -- "${ASYNC_ARGS[@]}" && unset ASYNC_ARGS
    # __spin:spinners() {
    #     if [[ -f "$SPINNERS_TMP_FILE" ]]; then
    #         # jq -c . "$SPINNERS_TMP_FILE"
    #         return 0
    #     fi
    #     curl -sL https://raw.githubusercontent.com/sindresorhus/cli-spinners/main/spinners.json >"$SPINNERS_TMP_FILE"
    #     # jq -c . "$SPINNERS_TMP_FILE"
    #     return 0
    # }
    # __spin:spinners:names() {
    #     __spin:spinners
    #     jq -r 'keys | .[]' "$SPINNERS_TMP_FILE" | tr '\n' ' '
    # }
    # __spin:random:spinner() {
    #     local SPINNERS_NAMES=($(__spin:spinners:names))
    #     if [[ -n "$ASYNC_PARAM_SPINNER" ]]; then
    #         for SPINNER_NAME in "${SPINNERS_NAMES[@]}"; do
    #             if [[ "$SPINNER_NAME" == "$ASYNC_PARAM_SPINNER" ]]; then
    #                 jq -r ".${ASYNC_PARAM_SPINNER} | .name = \"${ASYNC_PARAM_SPINNER}\"" "$SPINNERS_TMP_FILE"
    #                 return 0
    #             fi
    #         done
    #     fi
    #     local SPINNER_INDEX=$((RANDOM % ${#SPINNERS_NAMES[@]}))
    #     local SPINNER_NAME="${SPINNERS_NAMES[$SPINNER_INDEX]}"
    #     jq -r ".${SPINNER_NAME} | .name = \"${SPINNER_NAME}\"" "$SPINNERS_TMP_FILE"
    # }
    # __spin:debug() {
    #     local SPINNER=$(__spin:random:spinner)
    #     local SPINNER_NAME=$(jq -r '.name' <<<"$SPINNER")
    #     local SPINNER_FRAMES=($(jq -r '.frames | .[]' <<<"$SPINNER" | tr '\n' ' '))
    #     local SPINNER_INTERVAL=$(jq -r '.interval' <<<"$SPINNER")
    #     local SPINNER_LENGTH=${#SPINNER_FRAMES[@]}
    #     local SPINNER_INDEX=0
    #     echo "Spinners: $(__spin:spinners:names)"
    #     echo "Spinner: ${SPINNER_NAME}"
    #     echo "Frames: ${SPINNER_FRAMES[*]}"
    #     echo "Interval: ${SPINNER_INTERVAL}"
    #     echo "Length: ${SPINNER_LENGTH}"
    #     echo "Index: ${SPINNER_INDEX}"
    #     exit 255
    # }
    # __spin:shutdown() {
    #     tput cnorm
    # }
    # __spin:startup() {
    #     tput civis
    # }
    # __spin:trap() {
    #     trap __spin:shutdown EXIT
    #     trap __spin:shutdown INT
    #     trap __spin:shutdown TERM
    # }
    # __spin:cursor:back() {
    #     local N=${1:-1}
    #     echo -en "\033[${N}D"
    #     # mac compatible, but goes back to the beginning of the line
    # }
    # __spin() {
    #     __spin:spinners
    #     local SPINNER=$(__spin:random:spinner)
    #     local SPINNER_NAME=$(jq -r '.name' <<<"$SPINNER")
    #     local SPINNER_FRAMES=($(jq -r '.frames | .[]' <<<"$SPINNER" | tr '\n' ' '))
    #     local SPINNER_INTERVAL=$(jq -r '.interval' <<<"$SPINNER")
    #     local SPINNER_LENGTH=${#SPINNER_FRAMES[@]}
    #     local SPINNER_INDEX=0
    #     local SPINNER_TARGET_PID=$1
    #     local SPINNER_MESSAGE="${2:-}" #$(ps -p "$SPINNER_TARGET_PID" -o comm=) && SPINNER_MESSAGE="$SPINNER_MESSAGE($SPINNER_TARGET_PID)"
    #     while ps a | awk '{print $1}' | grep -q "$SPINNER_TARGET_PID"; do
    #         local FRAME=${SPINNER_FRAMES[$SPINNER_INDEX]}
    #         printf " %s  %s\r" "$FRAME" "$SPINNER_MESSAGE"
    #         SPINNER_INDEX=$(((SPINNER_INDEX + 1) % SPINNER_LENGTH))
    #         sleep "$((SPINNER_INTERVAL / 500))"
    #         __spin:cursor:back 1
    #         printf "\b\b\b\b\b\b"
    #     done
    #     printf "\b\b\b\b"
    # }
    await(){
        spinner spin "$@"
    }
    declare -a PIDS=()
    declare -a RESULTS=()
    declare -a ERRORS=()
    declare -a COMMANDS=()
    declare -a START_TIMES=()
    # declare -a EXIT_CODES=()
    local ASYNC_OUTPUT=$(mktemp -u -t "ywt-async-XXXXXX")
    for COMMAND in "$@"; do
        local CMD_OUTPUT=$(mktemp -u -t "ywt-async-XXXXXX" --suffix=".out")
        local CMD_ERROR=$(mktemp -u -t "ywt-async-XXXXXX" --suffix=".err")
        # local CMD_EXIT=0
        RESULTS+=("$CMD_OUTPUT")
        ERRORS+=("$CMD_ERROR")
        COMMANDS+=("$COMMAND")
        START_TIMES+=("$(date -u +%s.%N)")
        {
            bash -c "source $YWT_SDK_FILE && $COMMAND" >"$CMD_OUTPUT" 2>"$CMD_ERROR"
            # eval "$COMMAND" >"$CMD_OUTPUT" 2>"$CMD_ERROR"
            # $COMMAND >"$CMD_OUTPUT" 2>"$CMD_ERROR" || CMD_EXIT=$? && EXIT_CODES+=("$CMD_EXIT")
        } &
        PIDS+=("$!")
    done
    echo "Waiting for ${#PIDS[@]} commands to finish" | logger info
    for IDX in "${!PIDS[@]}"; do
        local YPID="${PIDS[$IDX]}"
        local RESULT="${RESULTS[$IDX]}"
        local ERROR="${ERRORS[$IDX]}"
        local COMMAND="${COMMANDS[$IDX]}"
        local STARTED_AT="${START_TIMES[$IDX]}"
        local MESSAGE="(${YELLOW}$YPID${NC}) ${BLUE}${COMMANDS[$IDX]}${NC}"
        echo "Running $MESSAGE" | logger info
        await "$YPID" "Waiting $MESSAGE" # & wait "${YPID}"
        local STATUS=$?
        local EXIT_CODE="${STATUS}" #"${EXIT_CODES[$IDX]}"
        local FINISHED_AT=$(date -u +%s.%N)
        local ELAPSED_TIME=$(awk "BEGIN {printf \"%.2f\", $FINISHED_AT - $STARTED_AT}")
        {
            echo -n "{"
            echo -n "\"pid\": ${YPID},"
            echo -n "\"started_at\": ${STARTED_AT},"
            echo -n "\"finished_at\": ${FINISHED_AT},"
            echo -n "\"elapsed_time\": ${ELAPSED_TIME:-0},"
            echo -n "\"command\": \"${COMMAND}\","
            echo -n "\"exit_code\": ${EXIT_CODE},"
            local CONTENT_OUTPUT=$(cat "$RESULT") && [[ -z "$CONTENT_OUTPUT" ]] && CONTENT_OUTPUT="null"
            local CONTENT_ERROR=$(cat "$ERROR") && [[ -z "$CONTENT_ERROR" ]] && CONTENT_ERROR="null"
            if jq -e . <<<"$CONTENT_OUTPUT" >/dev/null 2>&1; then
                echo -n "\"result\": $(jq -c . "$RESULT"),"
            else
                echo -n "\"result\": \"$RESULT\","
            fi
            if jq -e . <<<"$CONTENT_ERROR" >/dev/null 2>&1; then
                echo -n "\"error\": "
                jq -c '. | if . == "" then null else . end' "$ERROR"
            else
                echo -n "\"error\": \"${ERROR}\","
            fi
            if [ "$CONTENT_OUTPUT" != "null" ]; then
                local CONTENT="$CONTENT_OUTPUT"
            elif [ "$CONTENT_ERROR" != "null" ]; then
                local CONTENT="$CONTENT_ERROR"
            else 
                local CONTENT="null"
            fi
            CONTENT=$(
                echo "$CONTENT" | jq -c . >/dev/null 2>&1 && echo "$CONTENT" | jq -c . || echo "\"$CONTENT\""
            )
            echo -n "\"output\": $CONTENT"
            echo -n "}"
            echo
        } | jq -c . >>"$ASYNC_OUTPUT"
        echo "Done $MESSAGE" | logger success
        # if [ "$EXIT_CODE" -eq 0 ]; then
        #     echo "(${YELLOW}$YPID${NC}) ${BLUE}${COMMANDS[$IDX]}${NC} executed successfully" | logger success
        #     logger info < "$RESULT"
        # else
        #     echo "(${YELLOW}$YPID${NC}) ${BLUE}${COMMANDS[$IDX]}${NC} failed with PID: " | logger error
        #     logger error < "$ERROR"
        # fi
        rm -f "$RESULT" "$ERROR"
    done
    echo "All commands executed successfully" | logger success
    # cat "$ASYNC_OUTPUT"
    jq -s . "$ASYNC_OUTPUT"
    rm -f "$ASYNC_OUTPUT"
    return 0
}
