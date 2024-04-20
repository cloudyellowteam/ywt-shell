#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
# Continuous Secutiry Scanner
ydk:css() {
    css:scanners() {
        local SCANNERS_FILE="/workspace/rapd-shell/assets/scanners.json"
        [ ! -f "$SCANNERS_FILE" ] && echo "[]" >&4 && ydk:log error "No scanners found" && return 1
        jq -cr '.' "$SCANNERS_FILE" >&4
        return 0
    }
    scanners() {
        ydk:log info "Listing scanners"
        local YDK_SCANNERS=$(css:scanners 4>&1)
        echo "$YDK_SCANNERS" >&4
        ydk:log success "$(jq -cr '. | length' <<<"$YDK_SCANNERS") scanners found"
        {
            echo -e "Id\Code\tDescription\tFeatures"
            jq -cr '
                    .[] |
                [
                    (.id),
                    (.name | @base64 | if length > 5 then .[0:5] + "" else . end),
                    (.description | if length > 40 then .[0:40] + "..." else . end)
                    ] | @tsv
                ' <<<"$YDK_SCANNERS"
        } | column -t -s $'\t' | awk '{print NR-1,$0}'
        return 0
    }
    css:get(){
        ydk:log info "Searching for scanner $1"
        local SCANNER=$(
            jq -cr --arg SCANNER_ID "$1" '
                .[] | 
                select(.name == $SCANNER_ID or .id == $SCANNER_ID)
            ' <<<"$(css:scanners 4>&1)"
        )
        [ -z "$SCANNER" ] && ydk:log error "Scanner not found" && return 22
        echo "$SCANNER" >&4
        ydk:log success "Scanner found $(jq -cr '.name' <<<"$SCANNER")"
        return 0
    }
    scanner(){
        local SCANNER=$(css:get "$1" 4>&1)
        [ -z "$SCANNER" ] && return 22
        jq -r '.description' <<<"$SCANNER"
        echo "$SCANNER"
        return 0
    }
    ydk:try "$@"
    return $?
}
