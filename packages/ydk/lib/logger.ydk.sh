#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:logger() {
    enabled() {
        local LOG_LEVEL=${1:-info}
        local LOG_LEVEL_IDX=-1
        local LOG_CONFIG_LEVEL=${YDK_DEFAULTS_LOGGER[0]:-output}
        local LOG_CONFIG_LEVEL_IDX=-1
        for YDK_LOGGER_LEVEL_IDX in "${!YDK_LOGGER_LEVELS[@]}"; do
            local LEVEL=${YDK_LOGGER_LEVELS[$YDK_LOGGER_LEVEL_IDX]}
            [[ $LOG_LEVEL == "$LEVEL" ]] && LOG_LEVEL_IDX=$YDK_LOGGER_LEVEL_IDX
            [[ $LOG_CONFIG_LEVEL == "$LEVEL" ]] && LOG_CONFIG_LEVEL_IDX=$YDK_LOGGER_LEVEL_IDX
        done
        [[ $LOG_LEVEL_IDX -lt 0 ]] && return 1
        [[ $LOG_CONFIG_LEVEL_IDX -lt 0 ]] && return 1
        [[ $LOG_LEVEL_IDX -ge $LOG_CONFIG_LEVEL_IDX ]] && return 0
        return 1
    }
    levels() {
        echo -n "["
        for YDK_LOGGER_LEVEL_IDX in "${!YDK_LOGGER_LEVELS[@]}"; do
            local LOG_LEVEL=${YDK_LOGGER_LEVELS[$YDK_LOGGER_LEVEL_IDX]}
            echo -n "{"
            echo -n "\"level\": ${YDK_LOGGER_LEVEL_IDX},"
            echo -n "\"name\": \"${LOG_LEVEL}\","
            case $LOG_LEVEL in
            trace)
                echo -n "\"color\": \"cyan\","
                echo -n "\"icon\": \"🔍\""
                ;;
            debug)
                echo -n "\"color\": \"cyan\","
                echo -n "\"icon\": \"🐞\""
                ;;
            info)
                echo -n "\"color\": \"green\","
                echo -n "\"icon\": \"📗\""
                ;;
            warn)
                echo -n "\"color\": \"yellow\","
                echo -n "\"icon\": \"🔔\""
                ;;
            error)
                echo -n "\"color\": \"red\","
                echo -n "\"icon\": \"🚨\""
                ;;
            success)
                echo -n "\"color\": \"green\","
                echo -n "\"icon\": \"✅\""
                ;;
            output)
                echo -n "\"color\": \"green\","
                echo -n "\"icon\": \"📝\""
                ;;
            fatal)
                echo -n "\"color\": \"red\","
                echo -n "\"icon\": \"💀\""
                ;;
            panic)
                echo -n "\"color\": \"red\","
                echo -n "\"icon\": \"🔥\""
                ;;
            esac
            echo -n ",\"enabled\":"
            enabled "$LOG_LEVEL" && echo -n "true" || echo -n "false"
            echo -n "},"
        done | sed -e 's/,$//'
        echo -n "]"
    }
    message() {
        local MESSAGE=${1:-}
        local LINES=()
        [[ -n "$MESSAGE" ]] && LINES+=("$MESSAGE")
        [[ -p /dev/stdin ]] && while read -r LINE; do LINES+=("$LINE"); done <&0
        MESSAGE="${LINES[*]//$'\n'/\\n}"
        MESSAGE=${MESSAGE//\"/\\\"}
        echo "$MESSAGE" |
            sed -r "s/\x1B\[[0-9;]*[mK]//g" |
            sed 's/\x1b\[[0-9;]*m//g'
    }
    defaults() {
        local OPTS=${1:-"{}"}
        local YDK_LOGGER_DEFAULTS=$({
            echo -n "{"
            echo -n "\"level\": \"${YDK_DEFAULTS_LOGGER[0]}\","
            echo -n "\"template\": \"${YDK_DEFAULTS_LOGGER[1]}\","
            echo -n "\"format\": \"${YDK_DEFAULTS_LOGGER[2]}\","
            echo -n "\"context\": \"${YDK_DEFAULTS_LOGGER[3]}\","
            echo -n "\"file\": \"${YDK_DEFAULTS_LOGGER[4]}\","
            echo -n "\"maxsize\": \"${YDK_DEFAULTS_LOGGER[5]}\""
            echo -n "}"
        } | jq -c .)
        jq -cn \
            --argjson opts "${OPTS}" \
            --argjson defautls "${YDK_LOGGER_DEFAULTS}" \
            '
        {
            "opts": $opts,
            "defaults": $defautls,
            "args_length": $opts | .__args | length,
            "args": $opts | .__args,
            "values": {
                "level": ($opts.level // $opts.l // $defautls.level),
                "template": ($opts.template // $opts.t //$defautls.template),
                "format": ($opts.format // $opts.f //$defautls.format),
                "context": ($opts.context // $opts.c //$defautls.context),
                "file": ($opts.file // $opts.fl //$defautls.file),
                "maxsize": ($opts.maxsize // $opts.s //$defautls.maxsize),
                "message": ($opts.message // $opts.m //$defautls.message)
            }
        } | del(.opts.__args)'

    }
    watch() {
        # echo "$LOGGER_OPTS"
        local LOG_FORMAT=$(jq -r '.template' <<<"$LOGGER_OPTS")
        local LOG_FILE=$(jq -r '.file' <<<"$LOGGER_OPTS")
        LOG_FORMAT=$({
            echo "$LOG_FORMAT" |
                sed 's/{{/\\(/g' |
                sed 's/}}/)/g' |
                sed -E 's/\{\{\.([^}]+)\}\}/.\1/g' |
                sed -E 's/\| ascii_upcase/| ascii_upcase/g'
        })
        # echo -ne "${YELLOW}[${YDK_CLI_NAME^^}]${NC}"
        tail -f "${LOG_FILE}" | jq -r '
                . | " '"$LOG_FORMAT"'" | gsub("\\n"; "\n")
            ' >/dev/stderr
    }
    __is_log_level() {
        local LEVEL=${1:-info}
        for LEVEL_IDX in "${!YDK_LOGGER_LEVELS[@]}"; do
            [[ $LEVEL == "${YDK_LOGGER_LEVELS[$LEVEL_IDX]}" ]] && return 0
        done
        return 1
    }
    __json() {
        local LOG_OPTS=$1 && shift
        local LOG_LEVEL="$1" && shift
        local LOG_MESSAGE=$(message "$1") && shift
        if [[ -n "$LOG_MESSAGE" ]] && jq -e . >/dev/null 2>&1 <<<"$LOG_MESSAGE"; then
            LOG_MESSAGE="{\"data\": $(jq -c . <<<"$LOG_MESSAGE")}"
        else
            LOG_MESSAGE="{\"data\":\"$LOG_MESSAGE\"}"
        fi
        LOG_LEVEL=$(levels | jq -cr ".[] | select(.name == \"$LOG_LEVEL\") | . // {}")
        # echo "LOG_OPTS = ${LOG_OPTS:-"{}"}"
        # echo "LOG_LEVEL = ${LOG_LEVEL:-"{}"}"
        # echo "LOG_MESSAGE = ${LOG_MESSAGE:-"{}"}"
        jq -cn \
            --argjson config "$(jq '.' <<<"${YDK_CONFIG:-"{}"}")" \
            --argjson options "$(jq '.' <<<"${LOG_OPTS:-"{}"}" 2>/dev/null)" \
            --argjson priority "$(jq '.' <<<"${LOG_LEVEL:-"{}"}" 2>/dev/null)" \
            --argjson data "$(jq '.' <<<"${LOG_MESSAGE:-"{}"}" 2>/dev/null)" \
            '{
                "config": $config,
                "timestamp": (now | todate),
                "host": "'"$(hostname)"'",
                "color": $priority.color,
                "icon": $priority.icon,               
                "priority": $priority.level,
                "level": $priority.name,
                "enabled": $priority.enabled,
                "context": $options.context,
                "template": $options.template,
                "file": $options.file,
                "format": $options.format,
                "message": $data.data,
                "tags": [
                    "context:\($options.context)"
                ],
                "path": "",                    
                "type": "\($options.context)-log",                    
                "pid": '$$',
                "ppid": '$PPID',
                "etime": "'"$(ydk:process etime)"'",
                "cli": "'"${YDK_CLI_NAME:-}"'",
                "name": "'"${YDK_CLI_NAME:-}"'"
            }'
    }
    __text() {
        local LOG_JSON=$1
        local LOG_FORMAT=$(jq -r '.template' <<<"$LOG_JSON")
        LOG_FORMAT=$({
            echo "$LOG_FORMAT" |
                sed 's/{{/\\(/g' |
                sed 's/}}/)/g' |
                sed -E 's/\{\{\.([^}]+)\}\}/.\1/g' |
                sed -E 's/\| ascii_upcase/| ascii_upcase/g'
        })
        echo -ne "${YELLOW}[${YDK_BRAND^^}]${NC}" 1>&2
        local LOG_FORMATTED=$(
            jq -r '
                . | " '"$LOG_FORMAT"'" | gsub("\\n"; "\n")
            ' <<<"$LOG_JSON"
        )
        echo -e "$LOG_FORMATTED" 1>&2
        return 0

    }
    __write() {
        local LOG_JSON=$(__json "$@")
        local LOG_FILE=$(jq -r '.file' <<<"$LOG_JSON")
        jq -c . <<<"$LOG_JSON" >>"$LOG_FILE"
        __text "$LOG_JSON"
        # echo -ne "${YELLOW}[${YDK_CLI_NAME^^}]${NC} $$ "
        # echo -e "$LOG_CONTENT"
        # # if [[ "$(jq -r '.level' <<<"$LOG_JSON" 2>/dev/null)" == "output" ]]; then
        # local LOG_CONTENT=$(jq -r '.message' <<<"$LOG_JSON")
        # echo -ne "${YELLOW}[${YDK_CLI_NAME^^}]${NC} $$ " 1>&2
        # echo -e "$LOG_CONTENT" 1>&2
        # if jq -e . >/dev/null 2>&1 <<<"$LOG_CONTENT"; then
        #     jq -c . <<<"$LOG_CONTENT"
        # else
        #     echo -e "$LOG_CONTENT"
        # fi
        # echo -ne "${YELLOW}[${YDK_CLI_NAME^^}]${NC} $$ "
        # jq -rc '. + {
        #     "message": .message | gsub("\\n"; "\n")
        # } |
        # select(.message | length > 0) |
        # "\(.message) \(.pid)"
        # ' <<<"$LOG_JSON"
        # fi
        return 0
    }
    activate() {
        echo "logger activated" # >&1
        # return 233
    }
    __logger:opts() {
        local YDK_LOGGER_OPTS=()
        while [[ $# -gt 0 ]]; do
            case $1 in
            *)
                YDK_LOGGER_OPTS+=("$1")
                shift
                ;;
            esac
        done
        set -- "${YDK_LOGGER_OPTS[@]}"
        [[ "${#YDK_LOGGER_OPTS[@]}" -eq 0 ]] && {
            ydk:throw 252 "Failed to parse logger options"
            return 1
        }
        echo "${YDK_LOGGER_OPTS[@]}" >&4
        return 0
    }
    local LOGGER_OPTS="{\"context\":\"${YDK_LOGGER_CONTEXT:-ydk}\"}"
    local LOGGER_ARGS=()
    while [[ $# -gt 0 ]]; do
        case $1 in
        -l | --level)
            local LOGGER_OPTS=$(jq '. + {"level": "'"$2"'"}' <<<"$LOGGER_OPTS")
            shift 2
            ;;
        -c | --context)
            local LOGGER_OPTS=$(jq '. + {"context": "'"$2"'"}' <<<"$LOGGER_OPTS")
            shift 2
            ;;
        -f | --format)
            local LOGGER_OPTS=$(jq '. + {"format": "'"$2"'"}' <<<"$LOGGER_OPTS")
            shift 2
            ;;
        -t | --template)
            local LOGGER_OPTS=$(jq '. + {"template": "'"$2"'"}' <<<"$LOGGER_OPTS")
            shift 2
            ;;
        -m | --message)
            local LOGGER_OPTS=$(jq '. + {"message": "'"$2"'"}' <<<"$LOGGER_OPTS")
            shift 2
            ;;
        *)
            LOGGER_ARGS+=("$1")
            shift
            ;;
        esac
    done
    set -- "${LOGGER_ARGS[@]}"
    # set -- "$(__logger:opts "$@" 4>&1)"
    local LOGGER_OPTS=$(defaults "$LOGGER_OPTS") && LOGGER_OPTS=$(jq -c '.values' <<<"$LOGGER_OPTS")
    if __is_log_level "$1" 2>/dev/null; then
        __write "$LOGGER_OPTS" "${LOGGER_ARGS[@]}" # 2>/dev/null
        return $?
    else
        ydk:try "$@"
        return $?
    fi

    # local LOGGER_OPTS=$(ydk:argv walk "$@" | jq -cr .)
    # local LOG_ARGS=($(jq '.__args[]' <<<"$LOGGER_OPTS"))
    # IFS=$'\n' read -r -d '' -a LOG_ARGS <<<"$(jq -r '.__args[]' <<<"$LOGGER_OPTS")"
    # set -- "${LOG_ARGS[@]}"
    # local LOGGER_OPTS=$(defaults "$LOGGER_OPTS") && LOGGER_OPTS=$(jq -c '.values' <<<"$LOGGER_OPTS")
    # __is_log_level "$1" && echo "$1 is log level" || echo "$1 is not log level"
    # if __is_log_level "$1"; then
    #     __write "$LOGGER_OPTS" "${LOG_ARGS[@]}"
    #     return $?
    # else
    #     ydk:try "$@"
    #     return $?
    # fi
}
# ydk:logger() {
#     validate() {
#         level() {
#             local LEVEL=${1:-info} && [[ ! $LEVEL =~ ^(debug|info|warn|error|success)$ ]] && LEVEL=info
#             local LOG_LEVEL=${YWT_LOG_LEVEL:-debug}
#             [[ $LOG_LEVEL == "debug" ]] && [[ $LEVEL == "debug" ]] && return 0
#             [[ $LOG_LEVEL == "info" ]] && [[ $LEVEL == "info" ]] && return 0
#             [[ $LOG_LEVEL == "warn" ]] && [[ $LEVEL == "warn" ]] && return 0
#             [[ $LOG_LEVEL == "error" ]] && [[ $LEVEL == "error" ]] && return 0
#             [[ $LOG_LEVEL == "success" ]] && [[ $LEVEL == "success" ]] && return 0
#             return 1
#         }
#         ydk:try "$@"
#         return $?
#     }
#     build() {
#         level() {
#             local LEVEL=${1:-debug} && LEVEL=${LEVEL,,}
#             case $LEVEL in
#             debug)
#                 echo "{\"level\":\"debug\", \"color\":\"cyan\", \"icon\":\"🐞\"}"
#                 ;;
#             info)
#                 echo "{\"level\":\"info\", \"color\":\"green\", \"icon\":\"📗\"}"
#                 ;;
#             warn)
#                 echo "{\"level\":\"warn\", \"color\":\"yellow\", \"icon\":\"🔔\"}"
#                 ;;
#             error)
#                 echo "{\"level\":\"error\", \"color\":\"red\", \"icon\":\"🚨\"}"
#                 ;;
#             success)
#                 echo "{\"level\":\"success\", \"color\":\"green\", \"icon\":\"✅\"}"
#                 ;;
#             *)
#                 echo "{\"level\":\"info\", \"color\":\"green\", \"icon\":\"📗\"}"
#                 ;;
#             esac
#             return 0
#         }
#         message() {
#             local MESSAGE=${1:-}
#             local LINES=()
#             [[ -n "$MESSAGE" ]] && LINES+=("$MESSAGE")
#             [[ -p /dev/stdin ]] && while read -r LINE; do LINES+=("$LINE"); done <&0
#             MESSAGE="${LINES[*]//$'\n'/\\n}"
#             MESSAGE=$(echo "$MESSAGE" | sed -r "s/\x1B\[[0-9;]*[mK]//g")
#             echo -n "$MESSAGE"
#         }
#         json() {
#             local LOG_LEVEL="$(level "$1")"
#             local LOG_MESSAGE="$(message "$2")" && LOG_MESSAGE=${LOG_MESSAGE//\"/\\\"}
#             local LOG_CONTEXT="${YWT_LOG_CONTEXT:-ywt}" && [[ -n "$3" ]] && LOG_CONTEXT="$3" && LOG_CONTEXT=${LOG_CONTEXT,,}
#             # '$level + {message: $message}'
#             jq -cn \
#                 --argjson level "${LOG_LEVEL:-}" \
#                 --argjson config "${YWT_CONFIG:-{}}" \
#                 --arg message "${LOG_MESSAGE:-}" \
#                 '{
#                     "signal": $level.icon,
#                     "context": "'"${LOG_CONTEXT}"'",
#                     "level": $level.level,
#                     "message": $message,
#                     "timestamp": (now | todate),
#                     "version": $config.yellowteam.version,
#                     "tags": ["'"${LOG_CONTEXT}:context"'"],
#                     "path": "",
#                     "host": "'"$(hostname)"'",
#                     "type": "'"${LOG_CONTEXT}-log"'",
#                     "package": "\($config.yellowteam.name):\($config.yellowteam.version):\($config.yellowteam.license)",
#                     "color": $level.color,
#                     "icon": $level.icon,
#                     "pid": "'$$'",
#                     "ppid": "'"$PPID"'",
#                     "cmd": "'"$YWT_CMD_NAME"'",
#                     "name": "'"$YWT_CMD_NAME"'"
#                 }'

#         }
#         ydk:try "$@"
#         return $?
#     }
#     format() {
#         json() {
#             build json "$@"
#         }
#         text() {
#             local LOG_JSON=$1
#             local LOG_FORMAT="${YELLOW}[${YWT_CMD_NAME^^}]${NC}" &&
#                 LOG_FORMAT+=" ${BRIGHT_BLACK}[\(.pid)]${NC}" &&
#                 LOG_TEMPLATE+=" ${BLUE}[\(.timestamp)]${NC}" &&
#                 LOG_FORMAT+=" \(.signal)" &&
#                 LOG_FORMAT+=" \(.level | ascii_upcase)" &&
#                 LOG_FORMAT+=" ${YELLOW}\(.context | ascii_upcase)${NC}" &&
#                 LOG_FORMAT+=" \(.message)" &&
#                 # LOG_TEMPLATE+=" \(.package)" &&
#                 LOG_FORMAT+=" [${BRIGHT_BLACK}\(.etime)${NC}]"
#             # local LOG_FORMAT="${YELLOW}[\(.pid)]${NC} \(.signal) \(.level | ascii_upcase) \(.message) \(.package) \(.etime)"
#             echo "$LOG_JSON" | jq --arg format "$LOG_FORMAT" -rc '
#             . | "'"$LOG_FORMAT"'" | gsub("\\n"; "\n")'
#         }
#         loki() {
#             echo "loki"
#         }
#         upstash() {
#             echo "upstash"
#         }
#         ydk:try "$@"
#         return $?
#     }
#     log() {
#         local LOG_FORMAT="${YWT_LOG_FORMAT:-json}"
#         local LOG_ARGS=()
#         while [[ "$#" -gt 0 ]]; do
#             case $1 in
#             -l | --level)
#                 local YWT_LOG_LEVEL=${2:-info}
#                 shift 2
#                 ;;
#             -c | --context)
#                 local YWT_LOG_CONTEXT=${2:-ywt}
#                 shift 2
#                 ;;
#             -f | --format)
#                 local YWT_LOG_FORMAT=${2:-json}
#                 shift 2
#                 ;;
#             -t | --template)
#                 local YWT_LOG_TEMPLATE=${2:-}
#                 shift 2
#                 ;;
#             *)
#                 LOG_ARGS+=("$1")
#                 shift
#                 ;;
#             esac
#         done
#         if ! validate level "${LOG_ARGS[0]}"; then
#             return 0
#         fi
#         local LOG_JSON=$(format json "${LOG_ARGS[@]}")
#         case $LOG_FORMAT in
#         json)
#             echo "$LOG_JSON"
#             ;;
#         text)
#             format text "$LOG_JSON" "$YWT_LOG_TEMPLATE"
#             ;;
#         loki)
#             format loki "$LOG_JSON"
#             ;;
#         upstash)
#             format upstash "$LOG_JSON"
#             ;;
#         *)
#             echo "$LOG_JSON"
#             ;;
#         esac
#         return 0
#     }
#     ydk:try "$@"
#     return $?
# }
{
    [[ -z "$YDK_DEFAULTS_LOGGER" ]] && declare -g -a YDK_DEFAULTS_LOGGER=(
        # Log Level
        [0]="info"
        # Log Template
        [1]="[{{.pid}}] [{{.timestamp}}] {{.icon}} {{.level | ascii_upcase}} {{.context | ascii_upcase }} {{.message}} [{{.etime}}]"
        # Log Format
        [2]="text"
        # Log Context
        [3]="ydk"
        # Log file
        [4]="/var/log/ydk.log"
        # Log max size
        [5]="1M"
    ) && readonly YDK_DEFAULTS_LOGGER
    [[ -z "$YDK_LOGGER_LEVELS" ]] && declare -g -a YDK_LOGGER_LEVELS=(
        [0]="trace"
        [1]="debug"
        [2]="info"
        [3]="warn"
        [4]="error"
        [5]="success"
        [6]="output"
        [7]="fatal"
        [8]="panic"
    ) && readonly YDK_LOGGER_LEVELS
}
# #!/usr/bin/env bash
# # shellcheck disable=SC2044,SC2155,SC2317
# logger() {
#     # __debug "logger" "$@"
#     # YWT_LOG_CONTEXT=${YWT_LOG_CONTEXT:-logger}
#     _is_log_level() {
#         local LEVEL=${1:-info} && [[ ! $LEVEL =~ ^(debug|info|warn|error|success)$ ]] && LEVEL=info
#         local LOG_LEVEL=${YWT_LOG_LEVEL:-info}
#         [[ $LOG_LEVEL == "debug" ]] && [[ $LEVEL == "debug" ]] && return 0
#         [[ $LOG_LEVEL == "info" ]] && [[ $LEVEL == "info" ]] && return 0
#         [[ $LOG_LEVEL == "warn" ]] && [[ $LEVEL == "warn" ]] && return 0
#         [[ $LOG_LEVEL == "error" ]] && [[ $LEVEL == "error" ]] && return 0
#         [[ $LOG_LEVEL == "success" ]] && [[ $LEVEL == "success" ]] && return 0
#         return 1
#     }
#     _log_level() {
#         local LEVEL=${1:-info} && [[ ! $LEVEL =~ ^(debug|info|warn|error|success)$ ]] && LEVEL=info
#         local COLOR=white
#         local ICON=""
#         case $LEVEL in
#         debug)
#             COLOR=cyan
#             ICON="🐞"
#             ;;
#         info)
#             COLOR=green
#             ICON="📗"
#             ;;
#         warn)
#             COLOR=yellow
#             ICON="🔔"
#             ;;
#         error)
#             COLOR=red
#             ICON="🚨"
#             ;;
#         success)
#             COLOR=green
#             ICON="✅"
#             ;;
#         esac
#         LEVEL=$(printf "%-5s" "$LEVEL") #YWT_LOG_CONTEXT
#         echo -n "$(colors apply "yellow" "[${YWT_CMD_NAME^^}]") "
#         echo -n "$(colors apply "bright-black" "[$$]" "fg") "
#         # echo -n "$(style "underline" "[$(__etime)]" "fg") "
#         echo -n "$(colors apply "blue" "[$(date +"%Y-%m-%d %H:%M:%S")]" "fg") "
#         echo -n "$(colors apply "$COLOR" "$(styles bold "[${LEVEL^^}]")" "fg") "
#         [[ "${YWT_LOG_CONTEXT^^}" != "${YWT_CMD_NAME^^}" ]] && echo -n "$(colors apply "blue" "[${YWT_LOG_CONTEXT^^}]") "
#         [ -n "$ICON" ] && echo -n "$(colors apply "$COLOR" "$ICON" "fg")"
#         echo -n " "
#     }
#     _log_message() {
#         local MESSAGE=${1:-}
#         local LINES=()
#         [[ -n "$MESSAGE" ]] && LINES+=("$MESSAGE")
#         [[ -p /dev/stdin ]] && while read -r LINE; do LINES+=("$LINE"); done <&0
#         MESSAGE="${LINES[*]//$'\n'/$'\n' }"
#         echo -n "$MESSAGE"
#     }
#     _log:level() {
#         local LEVEL=${1:-info} && [[ ! $LEVEL =~ ^(debug|info|warn|error|success)$ ]] && LEVEL=info
#         local COLOR=white
#         local ICON=""
#         case $LEVEL in
#         debug)
#             COLOR=cyan
#             ICON="🐞"
#             ;;
#         info)
#             COLOR=green
#             ICON="📗"
#             ;;
#         warn)
#             COLOR=yellow
#             ICON="🔔"
#             ;;
#         error)
#             COLOR=red
#             ICON="🚨"
#             ;;
#         success)
#             COLOR=green
#             ICON="✅"
#             ;;
#         esac
#         {
#             echo -n "{"
#             echo -n "\"level\": \"${LEVEL}\","
#             echo -n "\"icon\": \"${ICON}\","
#             echo -n "\"color\": \"${COLOR}\""
#             echo -n "}"
#         } | jq -c .
#     }
#     _log:message() {
#         local MESSAGE=${1:-}
#         local LINES=()
#         [[ -n "$MESSAGE" ]] && LINES+=("$MESSAGE")
#         [[ -p /dev/stdin ]] && while read -r LINE; do LINES+=("$LINE"); done <&0
#         MESSAGE="${LINES[*]//$'\n'/\\n}"
#         MESSAGE=$(echo "$MESSAGE" | sed -r "s/\x1B\[[0-9;]*[mK]//g")
#         echo -n "$MESSAGE"
#     }
#     _log:json() {
#         local LOG_LEVEL="$(_log:level "$1")"
#         local LOG_MESSAGE="$(_log:message "$2")"
#         jq -cn \
#             --argjson level "$LOG_LEVEL" \
#             --argjson config "$YWT_CONFIG" \
#             --arg message "${LOG_MESSAGE:-}" \
#             '{
#                 "signal": $level.icon,
#                 "context": "'"${YWT_LOG_CONTEXT,,}"'",   
#                 "level": $level.level,
#                 "message": $message,
#                 "timestamp": (now | todate),
#                 "version": $config.yellowteam.version,                
#                 "tags": ["'"ywt:${YWT_LOG_CONTEXT,,}:context"'"],
#                 "path": "",
#                 "host": "'"$(hostname)"'",
#                 "type": "'"${YWT_LOG_CONTEXT,,}-log"'",
#                 "package": "\($config.yellowteam.name):\($config.yellowteam.version):\($config.yellowteam.license)",
#                 "color": $level.color,
#                 "icon": $level.icon,
#                 "pid": "'$$'",
#                 "ppid": "'"$PPID"'",
#                 "cmd": "'"$YWT_CMD_NAME"'",
#                 "name": "'"$YWT_CMD_NAME"'",                
#                 "etime": "'"$(__etime)"'"
#             }' | jq -c '
#                 . |
#                 map_values(
#                     if type == "string" then
#                         . | gsub("\n"; " ")
#                     else
#                         .
#                     end
#                 ) |
#                 .
#             '
#     }
#     _log:loki() {
#         local LOG_JSON=$1
#         echo "$LOG_JSON" | jq -r .
#     }
#     _log:upstash() {
#         local LOG_JSON=$1
#         echo "$LOG_JSON" | jq -r .
#     }
#     _log:template() {
#         local LOG_JSON=$1
#         local LOG_FORMAT="${YELLOW}[${YWT_CMD_NAME^^}]${NC}" &&
#             LOG_FORMAT+=" ${BRIGHT_BLACK}[\(.pid)]${NC}" &&
#             LOG_TEMPLATE+=" ${BLUE}[\(.timestamp)]${NC}" &&
#             LOG_FORMAT+=" \(.signal)" &&
#             LOG_FORMAT+=" \(.level | ascii_upcase)" &&
#             LOG_FORMAT+=" ${YELLOW}\(.context | ascii_upcase)${NC}" &&
#             LOG_FORMAT+=" \(.message)" &&
#             # LOG_TEMPLATE+=" \(.package)" &&
#             LOG_FORMAT+=" [${BRIGHT_BLACK}\(.etime)${NC}]"
#         # local LOG_FORMAT="${YELLOW}[\(.pid)]${NC} \(.signal) \(.level | ascii_upcase) \(.message) \(.package) \(.etime)"
#         echo "$LOG_JSON" | jq --arg format "$LOG_FORMAT" -rc '
#             . |
#             "'"$LOG_FORMAT"'"
#         '
#     }
#     log() {
#         [ "$1" == "debug" ] && __debug "logger:" "$@" && return 0
#         _log:template "$(_log:json "$@")"
#         return 0
#         # local LOG_LEVEL="$(_log:level "$1")"
#         # local LOG_MESSAGE="$(_log:message "$2")"
# 
#         # jq -cn \
#         #     --argjson level "$LOG_LEVEL" \
#         #     --argjson config "$YWT_CONFIG" \
#         #     --arg message "${LOG_MESSAGE:-}" \
#         #     '{
#         #         "signal": $level.icon,
#         #         "context": "'"${YWT_LOG_CONTEXT,,}"'",   
#         #         "level": $level.level,
#         #         "message": $message,
#         #         "@timestamp": (now | todate),
#         #         "@version": $config.yellowteam.version,                
#         #         "tags": ["'"ywt:${YWT_LOG_CONTEXT,,}:context"'"],
#         #         "path": "",
#         #         "host": "'"$(hostname)"'",
#         #         "type": "'"${YWT_LOG_CONTEXT,,}-log"'",
#         #         "package": "\($config.yellowteam.name):\($config.yellowteam.version):\($config.yellowteam.license)",
#         #         "color": $level.color,
#         #         "icon": $level.icon,
#         #         "pid": "'$$'",
#         #         "ppid": "'$PPID'",
#         #         "cmd": "'"$YWT_CMD_NAME"'",
#         #         "name": "'"$YWT_CMD_NAME"'",                
#         #         "etime": "'"$(__etime)"'"
#         #     }' | jq --arg format "$LOG_FORMAT" -rc '
#         #         . |
#         #         map_values(
#         #             if type == "string" then
#         #                 . | gsub("\n"; " ")
#         #             else
#         #                 .
#         #             end
#         #         ) |
#         #         "'"$LOG_FORMAT"'"
#         #     '
#         # #. | $format
#         # return 0
# 
#         # [ "$1" == "debug" ] && __debug "logger:" "$@" && return 0
#         # _log_level "$1"
#         # _log_message "$2"
#         # # elapsed time
#         # echo " $(colors apply "bright-black" "[$(styles "underline" "$(__etime)")]" "fg")"
#     }
#     json() {
#         _log_level "$1"
#         jq -cC . <<<"$(_log_message "$2")"
#     }
#     local LEVEL=${1}
#     if [[ $LEVEL =~ ^(debug|info|warn|error|success)$ ]]; then
#         # ARGS=("${@:2}")
#         # shift # && LEVEL="log ${LEVEL}"
#         log "${1}" "${@:2}" && return 0
#     elif [[ $LEVEL == "json" ]]; then
#         shift # && LEVEL="json ${LEVEL}"
#         json "${LEVEL}" "$@" && return 0
#     elif __nnf "$@"; then
#         return 0
#         usage "$?" "logger" "$@" && return 1
#     else
#         usage 1 "logger" "$@" && return 1
#     fi
# }
# (
#     export -f logger
# )
