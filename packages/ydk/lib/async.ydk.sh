#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:async() {
    local YDK_LOGGER_CONTEXT="async"

    declare -a PIDS=()
    declare -a RESULTS=()
    declare -a ERRORS=()
    declare -a COMMANDS=()
    declare -a START_TIMES=()
    local ASYNC_OUTPUT=$(ydk:temp "async" 4>&1)
    for COMMAND in "$@"; do
        local CMD_OUTPUT=$(ydk:temp "async.out" 4>&1)
        local CMD_ERROR=$(ydk:temp "async.err" 4>&1)
        RESULTS+=("$CMD_OUTPUT")
        ERRORS+=("$CMD_ERROR")
        COMMANDS+=("$COMMAND")
        START_TIMES+=("$(date -u +%s.%N)")
        # ydk:log info "Running $COMMAND"
        {
            # source $YDK_SDK_FILE
            bash -c "$COMMAND" >"$CMD_OUTPUT" 2>"$CMD_ERROR"
        } &
        PIDS+=("$!")
    done
    ydk:log info "Waiting for ${#PIDS[@]} commands to finish"
    local TASKS_LENGTH=${#PIDS[@]}
    local TASKS_LEFT=${#PIDS[@]}
    local TASKS_DONE=0
    local TASKS_ERROR=0
    local TASKS_ID=1
    for PID_IDX in "${!PIDS[@]}"; do
        local YDK_ASYNC_PID="${PIDS[$PID_IDX]}"
        local YDK_ASYNC_RESULT="${RESULTS[$PID_IDX]}"
        local YDK_ASYNC_ERROR="${ERRORS[$PID_IDX]}"
        local YDK_ASYNC_COMMAND="${COMMANDS[$PID_IDX]}"
        local YDK_ASYNC_STARTED_AT="${START_TIMES[$PID_IDX]}"
        local YDK_ASYNC_COMMAND_NAME=$(echo "$YDK_ASYNC_COMMAND" | awk '{print $1}')
        local YDK_ASYNC_MESSAGE="($YDK_ASYNC_PID) ${YDK_ASYNC_COMMAND_NAME} ${TASKS_ID} of ${TASKS_LENGTH}, remaining ${TASKS_LEFT}, done ${TASKS_DONE}, errors ${TASKS_ERROR}"
        # ydk:log info "Waiting $YDK_ASYNC_MESSAGE"
        ydk:await spin "$YDK_ASYNC_PID" "Waiting $YDK_ASYNC_MESSAGE" >&1
        local YDK_ASYNC_STATUS=$?
        local YDK_ASYNC_EXIT_CODE="${YDK_ASYNC_STATUS}"
        local YDK_ASYNC_FINISHED_AT=$(date -u +%s.%N)
        local YDK_ASYNC_ELAPSED_TIME=$(awk "BEGIN {printf \"%.2f\", $YDK_ASYNC_FINISHED_AT - $YDK_ASYNC_STARTED_AT}")
        {
            echo -n "{"
            echo -n "\"idx\": ${PID_IDX},"
            echo -n "\"pid\": ${YDK_ASYNC_PID},"
            echo -n "\"started_at\": ${YDK_ASYNC_STARTED_AT},"
            echo -n "\"finished_at\": ${YDK_ASYNC_FINISHED_AT},"
            echo -n "\"elapsed_time\": ${YDK_ASYNC_ELAPSED_TIME:-0},"
            echo -n "\"command\": \"${YDK_ASYNC_COMMAND//\"/\\\"}\","
            echo -n "\"exit_code\": ${YDK_ASYNC_EXIT_CODE},"
            echo -n "\"result\": \"$YDK_ASYNC_RESULT\","
            echo -n "\"error\": \"$YDK_ASYNC_ERROR\""
            echo -n "}"
            echo
        } | jq -c . >>"$ASYNC_OUTPUT"
        TASKS_LEFT=$((TASKS_LEFT - 1))
        TASKS_ID=$((TASKS_ID + 1))
        TASKS_DONE=$((TASKS_DONE + 1))
        [ "$YDK_ASYNC_EXIT_CODE" -gt 0 ] && TASKS_ERROR=$((TASKS_ERROR + 1))
        ydk:log success "Done $YDK_ASYNC_MESSAGE"
        rm -f "$YDK_ASYNC_RESULT" "$YDK_ASYNC_ERROR"
    done
    ydk:log success "All commands executed successfully ${ASYNC_OUTPUT}"
    # jq -sc . "$ASYNC_OUTPUT" >&4
    if jq -se . "$ASYNC_OUTPUT" >/dev/null 2>&1; then
        jq -sc . "$ASYNC_OUTPUT" >&4
    else
        cat "$ASYNC_OUTPUT" >&4
    fi
    rm -f "$ASYNC_OUTPUT"
    return 0
    # ydk:try "$@" 4>&1
    # return $?
}
# async:v1() {
#     YWT_LOG_CONTEXT="ASYNC"

#     await() {
#         spinner spin "$@"
#     }
#     __content:extract:json() {
#         [[ -z "$1" ]] && echo -n "null" && return 0
#         if [ -f "$1" ]; then
#             sed -n '/{/,$p' "$1"
#         else
#             echo -n "$1" | sed -n '/{/,$p'
#         fi
#         return 0
#     }
#     __content:sanitize() {
#         local CONTENT="$1"
#         [ -f "$CONTENT" ] && CONTENT=$(cat "$CONTENT")
#         [[ -z "$CONTENT" ]] && echo -n "null" && return 0
#         # CONTENT="${CONTENT//$'\n'/\\n}"
#         echo -n "$CONTENT" |
#             sed -r 's/\x1B\[[0-9;]*[mK]//g' |
#             sed -r 's/\\x1B]8;; //g' |
#             sed -r 's/\\x1B]8;0=;//g'
#         return 0
#     }
#     __content:normatize() {
#         local FILE="$1"
#         {
#             echo -n "{"
#             echo -n "\"file\": \"${FILE}\","
#             echo -n "\"size\": $(stat -c%s "${FILE}"),"
#             if [ ! -f "${FILE}" ]; then
#                 echo -n "\"error\": \"File not found\""
#                 echo -n "}"
#                 return 1
#             fi
#             if [ ! -s "${FILE}" ]; then
#                 echo -n "\"error\": \"Empty file\""
#                 echo -n "}"
#                 return 1
#             fi
#             if jq -e . "${FILE}" >/dev/null 2>&1; then
#                 echo -n "\"format\": \"json1\","
#                 echo -n "\"content\": $(
#                     jq -c '
#                     map_values(
#                         if type == "string" then
#                             . | gsub("\n"; "\\n") | gsub("\""; "\\\"")
#                         else
#                             .
#                         end
#                     )
#                     ' "${FILE}"

#                 )"
#                 echo -n "}"
#                 return 0
#             fi
#             local CONTENT=$(__content:extract:json "$FILE")
#             if [[ -n "$CONTENT" ]] && jq -e . <<<"$CONTENT" >/dev/null 2>&1; then
#                 echo -n "\"format\": \"json2\","
#                 echo -n "\"content\": $(jq -c . <<<"$CONTENT" || echo -n "null")"
#                 echo -n "}"
#                 return 0
#             fi
#             local CONTENT=$(__content:sanitize "$FILE")
#             if [[ -n "$CONTENT" ]] && jq -e . <<<"$CONTENT" >/dev/null 2>&1; then
#                 echo -n "\"format\": \"json3\","
#                 echo -n "\"content\": $(jq -c . <<<"$CONTENT" || echo -n "null")"
#                 echo -n "}"
#                 return 0
#             fi
#             CONTENT="${CONTENT//$'\n'/\\n}"
#             CONTENT="${CONTENT//\"/\\\"}"
#             echo -n "\"format\": \"text\","
#             echo -n "\"content\": \"${CONTENT}\""
#             echo -n "}"
#         } | jq -c .
#         return 0
#     }
#     declare -a PIDS=()
#     declare -a RESULTS=()
#     declare -a ERRORS=()
#     declare -a COMMANDS=()
#     declare -a START_TIMES=()
#     # declare -a EXIT_CODES=()
#     local ASYNC_OUTPUT=$(mktemp -u -t "ywt-async-XXXXXX")
#     for COMMAND in "$@"; do
#         local CMD_OUTPUT=$(mktemp -u -t "ywt-async-XXXXXX" --suffix=".out")
#         local CMD_ERROR=$(mktemp -u -t "ywt-async-XXXXXX" --suffix=".err")
#         # local CMD_EXIT=0
#         RESULTS+=("$CMD_OUTPUT")
#         ERRORS+=("$CMD_ERROR")
#         COMMANDS+=("$COMMAND")
#         START_TIMES+=("$(date -u +%s.%N)")
#         {
#             bash -c "source $YWT_SDK_FILE $COMMAND" >"$CMD_OUTPUT" 2>"$CMD_ERROR"
#             # eval "$COMMAND" >"$CMD_OUTPUT" 2>"$CMD_ERROR"
#             # $COMMAND >"$CMD_OUTPUT" 2>"$CMD_ERROR" || CMD_EXIT=$? && EXIT_CODES+=("$CMD_EXIT")
#         } &
#         PIDS+=("$!")
#     done
#     echo "Waiting for ${#PIDS[@]} commands to finish" | logger info
#     local TASKS_LENGTH=${#PIDS[@]}
#     local TASKS_LEFT=${#PIDS[@]}
#     local TASKS_DONE=0
#     local TASKS_ERROR=0
#     local TASKS_ID=1
#     for IDX in "${!PIDS[@]}"; do
#         local YPID="${PIDS[$IDX]}"
#         local RESULT="${RESULTS[$IDX]}"
#         local ERROR="${ERRORS[$IDX]}"
#         local COMMAND="${COMMANDS[$IDX]}"
#         local STARTED_AT="${START_TIMES[$IDX]}"
#         local COMMAND_NAME=$(echo "$COMMAND" | awk '{print $1}')
#         local MESSAGE="(${YELLOW}$YPID${NC}) ${BLUE}${COMMAND_NAME}${NC} ${TASKS_ID} of ${TASKS_LENGTH}, remaining ${TASKS_LEFT}, done ${TASKS_DONE}, errors ${TASKS_ERROR}"
#         echo "Running $MESSAGE" | logger info
#         await "$YPID" "Waiting $MESSAGE" # & wait "${YPID}"
#         local STATUS=$?
#         local EXIT_CODE="${STATUS}" #"${EXIT_CODES[$IDX]}"
#         local FINISHED_AT=$(date -u +%s.%N)
#         local ELAPSED_TIME=$(awk "BEGIN {printf \"%.2f\", $FINISHED_AT - $STARTED_AT}")
#         {
#             echo -n "{"
#             echo -n "\"idx\": ${IDX},"
#             echo -n "\"pid\": ${YPID},"
#             echo -n "\"started_at\": ${STARTED_AT},"
#             echo -n "\"finished_at\": ${FINISHED_AT},"
#             echo -n "\"elapsed_time\": ${ELAPSED_TIME:-0},"
#             echo -n "\"command\": \"${COMMAND//\"/\\\"}\","
#             echo -n "\"exit_code\": ${EXIT_CODE},"
#             echo -n "\"result\": $(__content:normatize "$RESULT" 2>&1),"
#             echo -n "\"error\": $(__content:normatize "$ERROR" 2>&1)"
#             echo -n "}"
#             echo
#         } | jq -c . >>"$ASYNC_OUTPUT"
#         TASKS_LEFT=$((TASKS_LEFT - 1))
#         TASKS_ID=$((TASKS_ID + 1))
#         TASKS_DONE=$((TASKS_DONE + 1))
#         [ "$EXIT_CODE" -gt 0 ] && TASKS_ERROR=$((TASKS_ERROR + 1))
#         echo "Done $MESSAGE" | logger success
#         # if [ "$EXIT_CODE" -eq 0 ]; then
#         #     echo "(${YELLOW}$YPID${NC}) ${BLUE}${COMMANDS[$IDX]}${NC} executed successfully" | logger success
#         #     logger info < "$RESULT"
#         # else
#         #     echo "(${YELLOW}$YPID${NC}) ${BLUE}${COMMANDS[$IDX]}${NC} failed with PID: " | logger error
#         #     logger error < "$ERROR"
#         # fi
#         rm -f "$RESULT" "$ERROR"
#     done
#     echo "All commands executed successfully ${ASYNC_OUTPUT}" | logger success
#     if jq -se . "$ASYNC_OUTPUT" >/dev/null 2>&1; then
#         jq -sc . "$ASYNC_OUTPUT"
#     else
#         cat "$ASYNC_OUTPUT"
#     fi
#     # cat "$ASYNC_OUTPUT"
#     # jq -s . "$ASYNC_OUTPUT"
#     rm -f "$ASYNC_OUTPUT"
#     return 0
# }
#!/usr/bin/env bash
# # shellcheck disable=SC2044,SC2155,SC2317,SC2120
# async() {
#     YWT_LOG_CONTEXT="ASYNC"
#
#     await() {
#         spinner spin "$@"
#     }
#     __content:extract:json() {
#         [[ -z "$1" ]] && echo -n "null" && return 0
#         if [ -f "$1" ]; then
#             sed -n '/{/,$p' "$1"
#         else
#             echo -n "$1" | sed -n '/{/,$p'
#         fi
#         return 0
#     }
#     __content:sanitize() {
#         local CONTENT="$1"
#         [ -f "$CONTENT" ] && CONTENT=$(cat "$CONTENT")
#         [[ -z "$CONTENT" ]] && echo -n "null" && return 0
#         # CONTENT="${CONTENT//$'\n'/\\n}"
#         echo -n "$CONTENT" |
#             sed -r 's/\x1B\[[0-9;]*[mK]//g' |
#             sed -r 's/\\x1B]8;; //g' |
#             sed -r 's/\\x1B]8;0=;//g'
#         return 0
#     }
#     __content:normatize() {
#         local FILE="$1"
#         {
#             echo -n "{"
#             echo -n "\"file\": \"${FILE}\","
#             echo -n "\"size\": $(stat -c%s "${FILE}"),"
#             if [ ! -f "${FILE}" ]; then
#                 echo -n "\"error\": \"File not found\""
#                 echo -n "}"
#                 return 1
#             fi
#             if [ ! -s "${FILE}" ]; then
#                 echo -n "\"error\": \"Empty file\""
#                 echo -n "}"
#                 return 1
#             fi
#             if jq -e . "${FILE}" >/dev/null 2>&1; then
#                 echo -n "\"format\": \"json1\","
#                 echo -n "\"content\": $(
#                     jq -c '
#                     map_values(
#                         if type == "string" then
#                             . | gsub("\n"; "\\n") | gsub("\""; "\\\"")
#                         else
#                             .
#                         end
#                     )
#                     ' "${FILE}"
#
#                 )"
#                 echo -n "}"
#                 return 0
#             fi
#             local CONTENT=$(__content:extract:json "$FILE")
#             if [[ -n "$CONTENT" ]] && jq -e . <<<"$CONTENT" >/dev/null 2>&1; then
#                 echo -n "\"format\": \"json2\","
#                 echo -n "\"content\": $(jq -c . <<<"$CONTENT" || echo -n "null")"
#                 echo -n "}"
#                 return 0
#             fi
#             local CONTENT=$(__content:sanitize "$FILE")
#             if [[ -n "$CONTENT" ]] && jq -e . <<<"$CONTENT" >/dev/null 2>&1; then
#                 echo -n "\"format\": \"json3\","
#                 echo -n "\"content\": $(jq -c . <<<"$CONTENT" || echo -n "null")"
#                 echo -n "}"
#                 return 0
#             fi
#             CONTENT="${CONTENT//$'\n'/\\n}"
#             CONTENT="${CONTENT//\"/\\\"}"
#             echo -n "\"format\": \"text\","
#             echo -n "\"content\": \"${CONTENT}\""
#             echo -n "}"
#         } | jq -c .
#         return 0
#     }
#     declare -a PIDS=()
#     declare -a RESULTS=()
#     declare -a ERRORS=()
#     declare -a COMMANDS=()
#     declare -a START_TIMES=()
#     # declare -a EXIT_CODES=()
#     local ASYNC_OUTPUT=$(mktemp -u -t "ywt-async-XXXXXX")
#     for COMMAND in "$@"; do
#         local CMD_OUTPUT=$(mktemp -u -t "ywt-async-XXXXXX" --suffix=".out")
#         local CMD_ERROR=$(mktemp -u -t "ywt-async-XXXXXX" --suffix=".err")
#         # local CMD_EXIT=0
#         RESULTS+=("$CMD_OUTPUT")
#         ERRORS+=("$CMD_ERROR")
#         COMMANDS+=("$COMMAND")
#         START_TIMES+=("$(date -u +%s.%N)")
#         {
#             bash -c "source $YWT_SDK_FILE $COMMAND" >"$CMD_OUTPUT" 2>"$CMD_ERROR"
#             # eval "$COMMAND" >"$CMD_OUTPUT" 2>"$CMD_ERROR"
#             # $COMMAND >"$CMD_OUTPUT" 2>"$CMD_ERROR" || CMD_EXIT=$? && EXIT_CODES+=("$CMD_EXIT")
#         } &
#         PIDS+=("$!")
#     done
#     echo "Waiting for ${#PIDS[@]} commands to finish" | logger info
#     local TASKS_LENGTH=${#PIDS[@]}
#     local TASKS_LEFT=${#PIDS[@]}
#     local TASKS_DONE=0
#     local TASKS_ERROR=0
#     local TASKS_ID=1
#     for IDX in "${!PIDS[@]}"; do
#         local YPID="${PIDS[$IDX]}"
#         local RESULT="${RESULTS[$IDX]}"
#         local ERROR="${ERRORS[$IDX]}"
#         local COMMAND="${COMMANDS[$IDX]}"
#         local STARTED_AT="${START_TIMES[$IDX]}"
#         local COMMAND_NAME=$(echo "$COMMAND" | awk '{print $1}')
#         local MESSAGE="(${YELLOW}$YPID${NC}) ${BLUE}${COMMAND_NAME}${NC} ${TASKS_ID} of ${TASKS_LENGTH}, remaining ${TASKS_LEFT}, done ${TASKS_DONE}, errors ${TASKS_ERROR}"
#         echo "Running $MESSAGE" | logger info
#         await "$YPID" "Waiting $MESSAGE" # & wait "${YPID}"
#         local STATUS=$?
#         local EXIT_CODE="${STATUS}" #"${EXIT_CODES[$IDX]}"
#         local FINISHED_AT=$(date -u +%s.%N)
#         local ELAPSED_TIME=$(awk "BEGIN {printf \"%.2f\", $FINISHED_AT - $STARTED_AT}")
#         {
#             echo -n "{"
#             echo -n "\"idx\": ${IDX},"
#             echo -n "\"pid\": ${YPID},"
#             echo -n "\"started_at\": ${STARTED_AT},"
#             echo -n "\"finished_at\": ${FINISHED_AT},"
#             echo -n "\"elapsed_time\": ${ELAPSED_TIME:-0},"
#             echo -n "\"command\": \"${COMMAND//\"/\\\"}\","
#             echo -n "\"exit_code\": ${EXIT_CODE},"
#             echo -n "\"result\": $(__content:normatize "$RESULT" 2>&1),"
#             echo -n "\"error\": $(__content:normatize "$ERROR" 2>&1)"
#             echo -n "}"
#             echo
#         } | jq -c . >>"$ASYNC_OUTPUT"
#         TASKS_LEFT=$((TASKS_LEFT - 1))
#         TASKS_ID=$((TASKS_ID + 1))
#         TASKS_DONE=$((TASKS_DONE + 1))
#         [ "$EXIT_CODE" -gt 0 ] && TASKS_ERROR=$((TASKS_ERROR + 1))
#         echo "Done $MESSAGE" | logger success
#         # if [ "$EXIT_CODE" -eq 0 ]; then
#         #     echo "(${YELLOW}$YPID${NC}) ${BLUE}${COMMANDS[$IDX]}${NC} executed successfully" | logger success
#         #     logger info < "$RESULT"
#         # else
#         #     echo "(${YELLOW}$YPID${NC}) ${BLUE}${COMMANDS[$IDX]}${NC} failed with PID: " | logger error
#         #     logger error < "$ERROR"
#         # fi
#         rm -f "$RESULT" "$ERROR"
#     done
#     echo "All commands executed successfully ${ASYNC_OUTPUT}" | logger success
#     if jq -se . "$ASYNC_OUTPUT" >/dev/null 2>&1; then
#         jq -sc . "$ASYNC_OUTPUT"
#     else
#         cat "$ASYNC_OUTPUT"
#     fi
#     # cat "$ASYNC_OUTPUT"
#     # jq -s . "$ASYNC_OUTPUT"
#     rm -f "$ASYNC_OUTPUT"
#     return 0
# }
