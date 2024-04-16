#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:logger() {
    validate() {
        level() {
            local LEVEL=${1:-info} && [[ ! $LEVEL =~ ^(debug|info|warn|error|success)$ ]] && LEVEL=info
            local LOG_LEVEL=${YWT_LOG_LEVEL:-debug}
            [[ $LOG_LEVEL == "debug" ]] && [[ $LEVEL == "debug" ]] && return 0
            [[ $LOG_LEVEL == "info" ]] && [[ $LEVEL == "info" ]] && return 0
            [[ $LOG_LEVEL == "warn" ]] && [[ $LEVEL == "warn" ]] && return 0
            [[ $LOG_LEVEL == "error" ]] && [[ $LEVEL == "error" ]] && return 0
            [[ $LOG_LEVEL == "success" ]] && [[ $LEVEL == "success" ]] && return 0
            return 1
        }
        ydk:try "$@"
        return $?
    }
    build() {
        level() {
            local LEVEL=${1:-debug} && LEVEL=${LEVEL,,}
            case $LEVEL in
            debug)
                echo "{\"level\":\"debug\", \"color\":\"cyan\", \"icon\":\"🐞\"}"
                ;;
            info)
                echo "{\"level\":\"info\", \"color\":\"green\", \"icon\":\"📗\"}"
                ;;
            warn)
                echo "{\"level\":\"warn\", \"color\":\"yellow\", \"icon\":\"🔔\"}"
                ;;
            error)
                echo "{\"level\":\"error\", \"color\":\"red\", \"icon\":\"🚨\"}"
                ;;
            success)
                echo "{\"level\":\"success\", \"color\":\"green\", \"icon\":\"✅\"}"
                ;;
            *)
                echo "{\"level\":\"info\", \"color\":\"green\", \"icon\":\"📗\"}"
                ;;
            esac
            return 0
        }
        message() {
            local MESSAGE=${1:-}
            local LINES=()
            [[ -n "$MESSAGE" ]] && LINES+=("$MESSAGE")
            [[ -p /dev/stdin ]] && while read -r LINE; do LINES+=("$LINE"); done <&0
            MESSAGE="${LINES[*]//$'\n'/\\n}"
            MESSAGE=$(echo "$MESSAGE" | sed -r "s/\x1B\[[0-9;]*[mK]//g")
            echo -n "$MESSAGE"
        }
        json() {
            local LOG_LEVEL="$(level "$1")"
            local LOG_MESSAGE="$(message "$2")" && LOG_MESSAGE=${LOG_MESSAGE//\"/\\\"}
            local LOG_CONTEXT="${YWT_LOG_CONTEXT:-ywt}" && [[ -n "$3" ]] && LOG_CONTEXT="$3" && LOG_CONTEXT=${LOG_CONTEXT,,}
            # '$level + {message: $message}'
            jq -cn \
                --argjson level "${LOG_LEVEL:-}" \
                --argjson config "${YWT_CONFIG:-{}}" \
                --arg message "${LOG_MESSAGE:-}" \
                '{
                    "signal": $level.icon,
                    "context": "'"${LOG_CONTEXT}"'",
                    "level": $level.level,
                    "message": $message,
                    "timestamp": (now | todate),
                    "version": $config.yellowteam.version,                
                    "tags": ["'"${LOG_CONTEXT}:context"'"],
                    "path": "",
                    "host": "'"$(hostname)"'",
                    "type": "'"${LOG_CONTEXT}-log"'",
                    "package": "\($config.yellowteam.name):\($config.yellowteam.version):\($config.yellowteam.license)",
                    "color": $level.color,
                    "icon": $level.icon,
                    "pid": "'$$'",
                    "ppid": "'"$PPID"'",
                    "cmd": "'"$YWT_CMD_NAME"'",
                    "name": "'"$YWT_CMD_NAME"'"
                }'

        }
        ydk:try "$@"
        return $?
    }
    format() {
        json() {
            build json "$@"
        }
        text() {
            local LOG_JSON=$1
            local LOG_FORMAT="${YELLOW}[${YWT_CMD_NAME^^}]${NC}" &&
                LOG_FORMAT+=" ${BRIGHT_BLACK}[\(.pid)]${NC}" &&
                LOG_TEMPLATE+=" ${BLUE}[\(.timestamp)]${NC}" &&
                LOG_FORMAT+=" \(.signal)" &&
                LOG_FORMAT+=" \(.level | ascii_upcase)" &&
                LOG_FORMAT+=" ${YELLOW}\(.context | ascii_upcase)${NC}" &&
                LOG_FORMAT+=" \(.message)" &&
                # LOG_TEMPLATE+=" \(.package)" &&
                LOG_FORMAT+=" [${BRIGHT_BLACK}\(.etime)${NC}]"
            # local LOG_FORMAT="${YELLOW}[\(.pid)]${NC} \(.signal) \(.level | ascii_upcase) \(.message) \(.package) \(.etime)"
            echo "$LOG_JSON" | jq --arg format "$LOG_FORMAT" -rc '
            . | "'"$LOG_FORMAT"'" | gsub("\\n"; "\n")'
        }
        loki() {
            echo "loki"
        }
        upstash() {
            echo "upstash"
        }
        ydk:try "$@"
        return $?
    }
    log() {
        local LOG_FORMAT="${YWT_LOG_FORMAT:-json}"
        local LOG_ARGS=()
        while [[ "$#" -gt 0 ]]; do
            case $1 in
            -l | --level)
                local YWT_LOG_LEVEL=${2:-info}
                shift 2
                ;;
            -c | --context)
                local YWT_LOG_CONTEXT=${2:-ywt}
                shift 2
                ;;
            -f | --format)
                local YWT_LOG_FORMAT=${2:-json}
                shift 2
                ;;
            -t | --template)
                local YWT_LOG_TEMPLATE=${2:-}
                shift 2
                ;;
            *)
                LOG_ARGS+=("$1")
                shift
                ;;
            esac
        done
        if ! validate level "${LOG_ARGS[0]}"; then
            return 0
        fi
        local LOG_JSON=$(format json "${LOG_ARGS[@]}")
        case $LOG_FORMAT in
        json)
            echo "$LOG_JSON"
            ;;
        text)
            format text "$LOG_JSON" "$YWT_LOG_TEMPLATE"
            ;;
        loki)
            format loki "$LOG_JSON"
            ;;
        upstash)
            format upstash "$LOG_JSON"
            ;;
        *)
            echo "$LOG_JSON"
            ;;
        esac
        return 0
    }
    ydk:try "$@"
    return $?
}
