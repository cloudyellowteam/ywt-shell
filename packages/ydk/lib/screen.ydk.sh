#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:screen() {
    YDK_LOGGER_CONTEXT="screen"
    [[ -z "$YDK_SCREEN_REQUIRE_COLS" ]] && local YDK_SCREEN_REQUIRE_COLS=101 && readonly YDK_SCREEN_REQUIRE_COLS
    [[ -z "$YDK_SCREEN_REQUIRE_ROWS" ]] && local YDK_SCREEN_REQUIRE_ROWS=35 && readonly YDK_SCREEN_REQUIRE_ROWS
    size() {
        {
            if command -v stty &>/dev/null; then
                echo -n "{"
                stty size | {
                    read -r rows cols
                    echo -n "\"from\":\"stty\",\"rows\":$rows,\"cols\":$cols"
                }
                echo -n "}"
            elif command -v tput &>/dev/null; then
                echo -n "{"
                echo -n "\"from\":\"tput\",\"rows\":$(tput lines),\"cols\":$(tput cols)"
                echo -n "}"
            elif [[ -n "$COLUMNS" && -n "$LINES" ]]; then
                echo -n "{\"from\":\"env\",\"rows\":$LINES,\"cols\":$COLUMNS}"
            else
                echo -n "{"
                echo -n "\"\"from\":\"requirement\",rows\":$YDK_SCREEN_REQUIRE_ROWS,\"cols\":$YDK_SCREEN_REQUIRE_COLS"
                echo -n "}"
            fi
        } | jq -c >&4

    }
    defaults() {
        {
            echo -n "{"
            echo -n "\"rows\":$YDK_SCREEN_REQUIRE_ROWS,\"cols\":$YDK_SCREEN_REQUIRE_COLS"
            echo -n "}"
        } | jq -c >&4
    }
    expectSize() {
        local WIDTH=${1:-$YDK_SCREEN_REQUIRE_COLS}
        local HEIGHT=${2:-$YDK_SCREEN_REQUIRE_ROWS}
        local SCREEN_SIZE=$(size 4>&1)
        local CURRENT_WIDTH=$(echo "$SCREEN_SIZE" | jq -r '.cols')
        local CURRENT_HEIGHT=$(echo "$SCREEN_SIZE" | jq -r '.rows')
        if ((CURRENT_WIDTH >= WIDTH && CURRENT_HEIGHT >= HEIGHT)); then
            ydk:log info "Screen size is enough. Required: ${WIDTH}x${HEIGHT}. Actual: ${CURRENT_WIDTH}x${CURRENT_HEIGHT}"
            return 0
        fi
        ydk:log warn "Screen size is not enough. Required: ${WIDTH}x${HEIGHT}. Actual: ${CURRENT_WIDTH}x${CURRENT_HEIGHT}"
        return 1
    }
    align() {
        local ALIGNMENT="$1"
        local CURRENT_WIDTH=$(size 4>&1 | jq -r '.cols')
        while IFS= read -r LINE; do
            local TEXT_LENGHT=${#LINE}
            local SPACES=$((CURRENT_WIDTH - TEXT_LENGHT))
            if [ "$SPACES" -le 0 ]; then
                echo -e "$LINE" >&1
            else
                case "$ALIGNMENT" in
                left)
                    printf "%-${SPACES}s%s\n" "$LINE" "" >&1
                    ;;
                right)
                    printf "%${SPACES}s%s\n" "" "$LINE" >&1
                    ;;
                center)
                    local PADDING=$((SPACES / 2))
                    printf "%${PADDING}s$LINE%${PADDING}s\n" "" "" >&1
                    ;;
                *)
                    echo -e "$LINE" >&1
                    ;;
                esac
            fi
        done
        return 0
    }
    ydk:try "$@" 4>&1
    return $?
}
