#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:screen() {
    YDK_LOGGER_CONTEXT="screen"
    [[ -z "$YDK_SCREEN_REQUIRE_COLS" ]] && local YDK_SCREEN_REQUIRE_COLS=101 && readonly YDK_SCREEN_REQUIRE_COLS
    [[ -z "$YDK_SCREEN_REQUIRE_ROWS" ]] && local YDK_SCREEN_REQUIRE_ROWS=35 && readonly YDK_SCREEN_REQUIRE_ROWS
    size() {
        if command -v stty &>/dev/null; then
            {
                echo -n "{"
                stty size | {
                    read -r rows cols
                    echo -n "\"rows\":$rows,\"cols\":$cols"
                }
                echo -n "}"
            } | jq -c >&4
        elif command -v tput &>/dev/null; then
            {
                echo -n "{"
                echo -n "\"rows\":$(tput lines),\"cols\":$(tput cols)"
                echo -n "}"
            } | jq -c >&4
            # tput lines
            #  tput cols
        else
            echo -n "{"
            echo -n "\"rows\":$YDK_SCREEN_REQUIRE_ROWS,\"cols\":$YDK_SCREEN_REQUIRE_COLS"
            echo -n "}"
        fi
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
                echo -e "$LINE"
            else
                case "$ALIGNMENT" in
                left)
                    printf "%-${SPACES}s%s\n" "$LINE" ""
                    ;;
                right)
                    printf "%${SPACES}s%s\n" "" "$LINE"
                    ;;
                center)
                    local PADDING=$((SPACES / 2))
                    printf "%${PADDING}s$LINE%${PADDING}s\n" "" ""
                    ;;
                *)
                    echo -e "$LINE"
                    ;;
                esac
            fi
        done        
        return 0
    }
    ydk:try "$@" 4>&1
    return $?
}
