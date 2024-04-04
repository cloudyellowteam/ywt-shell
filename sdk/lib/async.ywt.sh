#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317,SC2120
async() {
    __spin() {
        local pid=$1
        local delay=0.50
        local spinstr='|/-\'
        while ps a | awk '{print $1}' | grep -q "$pid"; do
            local temp=${spinstr#?}
            printf " [%c]  " "$spinstr"
            local spinstr=$temp${spinstr%"$temp"}
            sleep "$delay"
            printf "\b\b\b\b\b\b"
        done
        printf "\b\b\b\b"        
    }
    YWT_LOG_CONTEXT="ASYNC"
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
        echo "Waiting (${YELLOW}$YPID${NC}) ${BLUE}${COMMANDS[$IDX]}${NC}" | logger info
        __spin "$YPID" & wait "${YPID}"
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
            if jq -e . "$RESULT" >/dev/null 2>&1; then
                echo -n "\"output\": $(jq -c . "$RESULT"),"
            else
                echo -n "\"output\": \"$RESULT\","
            fi
            if jq -e . "$ERROR" >/dev/null 2>&1 && [[ -n "$(cat "$ERROR")" ]]; then
                echo -n "\"error\": "
                jq -c '. | if . == "" then null else . end' "$ERROR"
            else
                echo -n "\"error\": \"${ERROR}\""
            fi
            echo -n "}"
            echo 
        } | jq -c . >>"$ASYNC_OUTPUT"

        if [ "$EXIT_CODE" -eq 0 ]; then
            echo "(${YELLOW}$YPID${NC}) ${BLUE}${COMMANDS[$IDX]}${NC} executed successfully" | logger success
            cat "$RESULT"
        else
            echo "(${YELLOW}$YPID${NC}) ${BLUE}${COMMANDS[$IDX]}${NC} failed with PID: " | logger error
            cat "$ERROR"
        fi
        rm -f "$RESULT" "$ERROR"
    done
    echo "All commands executed successfully" | logger success
    # cat "$ASYNC_OUTPUT"
    jq -s . "$ASYNC_OUTPUT"
    rm -f "$ASYNC_OUTPUT"
    return 0
}
