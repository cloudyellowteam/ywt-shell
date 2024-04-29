#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:emojis() {
    [[ -z "$YDK_EMOJIS_FILE" ]] && local YDK_EMOJIS_FILE="/workspace/rapd-shell/assets/emojis.json" && [[ ! -f "$YDK_EMOJIS_FILE" ]] && YDK_EMOJIS_FILE="$(ydk:assets location emojis 4>&1)"
    list() {
        # ydk:log info "$(jq -cr "${YDK_AWAIT_SPECS[count]}" "$YDK_AWAIT_SPINNERS_FILE") spinners available"
        local YDK_EMOJIS=$(jq -cr . "$YDK_EMOJIS_FILE" 2>/dev/null)
        jq -cr . <<<"$YDK_EMOJIS" >&4
        return 0
    }
    get() {
        local EMOJI_NAME="$1"
        local EMOJI=$(jq -cr ".[\"$EMOJI_NAME\"]" "$YDK_EMOJIS_FILE" 2>/dev/null)
        echo -n "$EMOJI" >&4
        return 0
    }
    substr() {
        # "Hello from mars :satellite:." Becomes "Hello from mars 📡."
        local RAW_STR="$1"
        while IFS= read -r MATCH; do
            local EMOJI_NAME=${MATCH:1:-1} #"${MATCH:1:${#MATCH}-2}"
            local EMOJI_CHAR=$(jq -cr ".[\"$EMOJI_NAME\"]" "$YDK_EMOJIS_FILE" 2>/dev/null)
            [[ -n "$EMOJI_CHAR" ]] && RAW_STR=${RAW_STR//"$MATCH"/"$EMOJI_CHAR"}
        done < <(echo "$RAW_STR" | grep -o ':[a-zA-Z_]\+:')
        echo -n "$RAW_STR" >&4
        return 0
    }
    ydk:try "$@" 4>&1
    return $?
}
