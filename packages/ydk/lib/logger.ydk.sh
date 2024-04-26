#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:logger() {
    __logger:enabled() {
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
    __logger:is:level() {
        local LEVEL=${1:-info}
        for LEVEL_IDX in "${!YDK_LOGGER_LEVELS[@]}"; do
            [[ $LEVEL == "${YDK_LOGGER_LEVELS[$LEVEL_IDX]}" ]] && return 0
        done
        return 1
    }
    __logger:message:sanetize() {
        echo -e "$1" | sed -r "s/\x1B\[[0-9;]*[mK]//g" | sed 's/\x1b\[[0-9;]*m//g' >&4
    }
    __logger:message:truncate() {
        echo -e "$1"
        return 0
        local LOG_MESSAGE=$({
            if jq -e . <<<"$1" 2>/dev/null 1>/dev/null; then
                jq -c . <<<"$1" >&4
            else
                echo "$1" >&4
            fi
        } 4>&1)
        local LOG_CHARS=${2:-70}
        local LOG_MAX_LENGTH=${#LOG_MESSAGE}
        if [[ $LOG_MAX_LENGTH -le $((LOG_CHARS * 2)) ]]; then
            echo -en "$LOG_MESSAGE" >&4
        else
            local LOG_MESSAGE_SANETIZED=$(__logger:message:sanetize "$LOG_MESSAGE" 4>&1)
            local LOG_MESSAGE_START=${LOG_MESSAGE_SANETIZED:0:$LOG_CHARS}
            local LOG_MESSAGE_END=${LOG_MESSAGE_SANETIZED: -$LOG_CHARS}
            echo -e "${LOG_MESSAGE_START:-"Start"}...${LOG_MESSAGE_END:-"End"}" >&4
        fi
        return 0
    }
    __logger:write:file() {
        local LOGGER_OPTS=$1
        local LOG_JSON=$2
        local LOG_FILE=$(jq -r '.file' <<<"$LOGGER_OPTS")
        local LOG_MAXSIZE=$(jq -r '.maxsize' <<<"$LOGGER_OPTS")
        LOG_MAXSIZE=$(echo "$LOG_MAXSIZE" | sed -r 's/([0-9]+)([KMG])/\1 \2/' | awk '{print $1 * 1024^index("KMG", $2)}')
        if [[ -f "$LOG_FILE" ]]; then
            local LOG_FILE_SIZE=$(stat -c %s "$LOG_FILE")
            if [[ $LOG_FILE_SIZE -gt $LOG_MAXSIZE ]]; then
                local LOG_FILE_ROTATE=$(dirname "$LOG_FILE")/$(basename "$LOG_FILE" .log)-$(date +"%Y%m%d%H%M%S").log
                mv "$LOG_FILE" "$LOG_FILE_ROTATE"
                echo -n >"$LOG_FILE"
                echo "$LOG_MAXSIZE = $(stat -c %s "$LOG_FILE")" 1>&2
                echo "Rotated log file $LOG_FILE to $LOG_FILE_ROTATE" 1>&2
            fi
        fi
        jq -c . <<<"$LOG_JSON" >>"$LOG_FILE"
        return 0
    }
    __logger:write:console() {
        local LOG_MESSAGE=$1
        local LOGGER_OPTS=$2
        local LOG_JSON=$3
        local LOG_ENABLED=$(jq -r '.priority.enabled' <<<"$LOG_JSON")
        [[ $LOG_ENABLED != "true" ]] && return 0
        local LOG_LEVEL=$(jq -r '.priority.name' <<<"$LOG_JSON")
        local LOG_COLOR=$(jq -r '.priority.color' <<<"$LOG_JSON") && LOG_COLOR=${LOG_COLOR^^}
        local LOG_ICON=$(jq -r '.priority.icon' <<<"$LOG_JSON")
        local LOG_CONTEXT=$(jq -r '.context' <<<"$LOG_JSON")
        local LOG_MESSAGE=$(jq -r '.message' <<<"$LOG_JSON")
        local LOG_TIMESTAMP=$(jq -r '.timestamp' <<<"$LOG_JSON")
        local LOG_PID=$(jq -r '.pid' <<<"$LOG_JSON")
        local LOG_PPID=$(jq -r '.ppid' <<<"$LOG_JSON")
        local LOG_ETIME=$(jq -r '.etime' <<<"$LOG_JSON")
        local LOG_CLI=$(jq -r '.cli' <<<"$LOG_JSON")
        local LOG_NAME=$(jq -r '.name' <<<"$LOG_JSON")
        local LOG_FORMAT=$(jq -r '.format' <<<"$LOGGER_OPTS")
        local LOG_TEMPLATE=$(jq -r '.template' <<<"$LOGGER_OPTS")
        local LOG_FORMATTED=$(echo -e "$LOG_FORMAT" | sed 's/{{/\\(/g' | sed 's/}}/)/g' | sed -E 's/\{\{\.([^}]+)\}\}/.\1/g' | sed -E 's/\| ascii_upcase/| ascii_upcase/g')
        {
            # echo -e "\$${LOG_COLOR^^}ddd"
            echo -ne "[${YELLOW}${YDK_BRAND^^}${NC}] "
            echo -ne "[${BLUE}$LOG_PID${NC}] "
            # eval "echo -ne \"\$${LOG_COLOR:-YELLOW}\""
            echo -ne "${LOG_ICON} "
            # echo -ne "[${LOG_LEVEL^^}] "
            # echo -ne "${NC} "
            echo -ne "[${LOG_CONTEXT^^}] "
            echo -ne "$LOG_MESSAGE "
            eval "echo -ne \"\$${LOG_COLOR:-YELLOW}\""
            echo -ne "[${LOG_LEVEL^^}] "
            echo -ne "${NC} "
            echo -ne "[${BLUE}$LOG_TIMESTAMP${NC}] "
            echo -ne "[${DARK_GRAY}$LOG_ETIME${NC}]"
            echo
        } 1>&2
        return 0
    }
    __logger:write() {
        local LOGGER_OPTS=$1 && shift
        local LOG_LEVEL_NAME=${1} && shift
        local LOG_LEVEL=$(jq -cr ".[] | select(.name == \"$LOG_LEVEL_NAME\") | . // {}" < <(levels 4>&1))
        local LOG_MESSAGE=${*//$'\n'/\\n}
        local LOG_JSON=$({
            echo -n "{"
            echo -n "\"config\": $(
                jq -c '
                    del(.template) |
                    del(.format) |
                    del(.file) |
                    del(.maxsize)                     
                ' <<<"${LOGGER_OPTS:-"{}"}"
            ),"
            echo -n "\"priority\": $(jq -c . <<<"${LOG_LEVEL:-"{}"}"),"
            echo -n "\"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\","
            echo -n "\"host\": \"$(hostname | md5sum | cut -d' ' -f1)\","
            echo -n "\"context\": \"${YDK_LOGGER_CONTEXT:-ydk}\","
            echo -n "\"pid\": $$,"
            echo -n "\"ppid\": $PPID,"
            echo -n "\"etime\": \"$(ydk:process etime)\","
            echo -n "\"cli\": \"${YDK_CLI_NAME:-}\","
            echo -n "\"name\": \"${YDK_CLI_NAME:-}\","
            echo -n "\"message\": "
            if jq -e . <<<"$LOG_MESSAGE" 2>/dev/null 1>/dev/null; then
                jq -c . <<<"$LOG_MESSAGE"
            else
                echo -n "\"$(__logger:message:sanetize "$LOG_MESSAGE" 4>&1)\""
            fi
            echo -n "}"
            echo
        })
        {
            __logger:write:file "${LOGGER_OPTS}" "${LOG_JSON}" & #4>&1 
            __logger:write:console "${LOG_MESSAGE}" "${LOGGER_OPTS}" "${LOG_JSON}" #& #4>&1
        } 4>&1 

    }
    defaults() {
        local YDK_LOGGER_DEFAULTS=$({
            echo -n "{"
            echo -n "\"level\": \"${YDK_DEFAULTS_LOGGER[0]}\","
            echo -n "\"template\": \"${YDK_DEFAULTS_LOGGER[1]}\","
            echo -n "\"format\": \"${YDK_DEFAULTS_LOGGER[2]}\","
            echo -n "\"context\": \"${YDK_DEFAULTS_LOGGER[3]:-${YDK_LOGGER_CONTEXT:-ydk}}\","
            echo -n "\"file\": \"${YDK_DEFAULTS_LOGGER[4]}\","
            echo -n "\"maxsize\": \"${YDK_DEFAULTS_LOGGER[5]}\""
            echo -n "}"
        })
        jq -c . <<<"$YDK_LOGGER_DEFAULTS" >&4
        return 0
    }
    levels() {
        {
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
                    echo -n "\"color\": \"DARK_GRAY\","
                    echo -n "\"icon\": \"💬\""
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
                    echo -n "\"color\": \"BRIGHT_GREEN\","
                    echo -n "\"icon\": \"👍\""
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
                __logger:enabled "$LOG_LEVEL" && echo -n "true" || echo -n "false"
                echo -n "},"
            done | sed -e 's/,$//'
            echo -n "]"
        } >&4

    }
    activate() {
        echo "logger activated" 1>&2
        # return 233
    }
    local LOGGER_OPTS=$(defaults 4>&1)
    local LOGGER_ARGS=()
    while [[ $# -gt 0 ]]; do
        case $1 in
        -l | --level)
            LOGGER_OPTS=$(jq '. + {"level": "'"$2"'"}' <<<"$LOGGER_OPTS")
            shift 2
            ;;
        -c | --context)
            LOGGER_OPTS=$(jq '. + {"context": "'"$2"'"}' <<<"$LOGGER_OPTS")
            shift 2
            ;;
        -f | --format)
            LOGGER_OPTS=$(jq '. + {"format": "'"$2"'"}' <<<"$LOGGER_OPTS")
            shift 2
            ;;
        -t | --template)
            LOGGER_OPTS=$(jq '. + {"template": "'"$2"'"}' <<<"$YDK_LOGGER_DEFAULTS")
            shift 2
            ;;
        -m | --message)
            LOGGER_OPTS=$(jq '. + {"message": "'"$2"'"}' <<<"$LOGGER_OPTS")
            shift 2
            ;;
        *)
            LOGGER_ARGS+=("$1")
            shift
            ;;
        esac
    done
    set -- "${LOGGER_ARGS[@]}" && unset LOGGER_ARGS
    local LOG_LEVEL_OR_ACTION=${1} && shift
    local LOG_LINES=()
    if [[ -p /dev/stdin ]]; then
        while read -r LINE; do LOG_LINES+=("$LINE"); done <&0
    elif [[ -n "$1" ]]; then
        LOG_LINES+=("$@")
    fi
    if __logger:is:level "$LOG_LEVEL_OR_ACTION"; then
        __logger:write "${LOGGER_OPTS}" "$LOG_LEVEL_OR_ACTION" "${LOG_LINES[@]}" 4>&1
        return $?
    else
        ydk:try "$LOG_LEVEL_OR_ACTION" "$@" 4>&1
        return $?
    fi
    # __logger:message "${LOG_LINES[@]}" 4>&1 1>&2
    # __logger:json "$(__logger:message "${LOG_LINES[@]}" 4>&1)"
    # return 0
}
# ydk:logger:v2() {
#     enabled() {
#         local LOG_LEVEL=${1:-info}
#         local LOG_LEVEL_IDX=-1
#         local LOG_CONFIG_LEVEL=${YDK_DEFAULTS_LOGGER[0]:-output}
#         local LOG_CONFIG_LEVEL_IDX=-1
#         for YDK_LOGGER_LEVEL_IDX in "${!YDK_LOGGER_LEVELS[@]}"; do
#             local LEVEL=${YDK_LOGGER_LEVELS[$YDK_LOGGER_LEVEL_IDX]}
#             [[ $LOG_LEVEL == "$LEVEL" ]] && LOG_LEVEL_IDX=$YDK_LOGGER_LEVEL_IDX
#             [[ $LOG_CONFIG_LEVEL == "$LEVEL" ]] && LOG_CONFIG_LEVEL_IDX=$YDK_LOGGER_LEVEL_IDX
#         done
#         [[ $LOG_LEVEL_IDX -lt 0 ]] && return 1
#         [[ $LOG_CONFIG_LEVEL_IDX -lt 0 ]] && return 1
#         [[ $LOG_LEVEL_IDX -ge $LOG_CONFIG_LEVEL_IDX ]] && return 0
#         return 1
#     }
#     levels() {
#         echo -n "["
#         for YDK_LOGGER_LEVEL_IDX in "${!YDK_LOGGER_LEVELS[@]}"; do
#             local LOG_LEVEL=${YDK_LOGGER_LEVELS[$YDK_LOGGER_LEVEL_IDX]}
#             echo -n "{"
#             echo -n "\"level\": ${YDK_LOGGER_LEVEL_IDX},"
#             echo -n "\"name\": \"${LOG_LEVEL}\","
#             case $LOG_LEVEL in
#             trace)
#                 echo -n "\"color\": \"cyan\","
#                 echo -n "\"icon\": \"🔍\""
#                 ;;
#             debug)
#                 echo -n "\"color\": \"cyan\","
#                 echo -n "\"icon\": \"🐞\""
#                 ;;
#             info)
#                 echo -n "\"color\": \"green\","
#                 echo -n "\"icon\": \"📗\""
#                 ;;
#             warn)
#                 echo -n "\"color\": \"yellow\","
#                 echo -n "\"icon\": \"🔔\""
#                 ;;
#             error)
#                 echo -n "\"color\": \"red\","
#                 echo -n "\"icon\": \"🚨\""
#                 ;;
#             success)
#                 echo -n "\"color\": \"green\","
#                 echo -n "\"icon\": \"✅\""
#                 ;;
#             output)
#                 echo -n "\"color\": \"green\","
#                 echo -n "\"icon\": \"📝\""
#                 ;;
#             fatal)
#                 echo -n "\"color\": \"red\","
#                 echo -n "\"icon\": \"💀\""
#                 ;;
#             panic)
#                 echo -n "\"color\": \"red\","
#                 echo -n "\"icon\": \"🔥\""
#                 ;;
#             esac
#             echo -n ",\"enabled\":"
#             enabled "$LOG_LEVEL" && echo -n "true" || echo -n "false"
#             echo -n "},"
#         done | sed -e 's/,$//'
#         echo -n "]"
#     }
#     message() {
#         local MESSAGE=${1:-}
#         local LINES=()
#         [[ -n "$MESSAGE" ]] && LINES+=("$MESSAGE")
#         [[ -p /dev/stdin ]] && while read -r LINE; do LINES+=("$LINE"); done <&0
#         MESSAGE="${LINES[*]//$'\n'/\\n}"
#         MESSAGE=${MESSAGE//\"/\\\"}
#         echo "$MESSAGE" |
#             sed -r "s/\x1B\[[0-9;]*[mK]//g" |
#             sed 's/\x1b\[[0-9;]*m//g'
#     }
#     defaults() {
#         local OPTS=${1:-"{}"}
#         local YDK_LOGGER_DEFAULTS=$({
#             echo -n "{"
#             echo -n "\"level\": \"${YDK_DEFAULTS_LOGGER[0]}\","
#             echo -n "\"template\": \"${YDK_DEFAULTS_LOGGER[1]}\","
#             echo -n "\"format\": \"${YDK_DEFAULTS_LOGGER[2]}\","
#             echo -n "\"context\": \"${YDK_DEFAULTS_LOGGER[3]}\","
#             echo -n "\"file\": \"${YDK_DEFAULTS_LOGGER[4]}\","
#             echo -n "\"maxsize\": \"${YDK_DEFAULTS_LOGGER[5]}\""
#             echo -n "}"
#         } | jq -c .)
#         jq -cn \
#             --argjson opts "${OPTS}" \
#             --argjson defautls "${YDK_LOGGER_DEFAULTS}" \
#             '
#         {
#             "opts": $opts,
#             "defaults": $defautls,
#             "args_length": $opts | .__args | length,
#             "args": $opts | .__args,
#             "values": {
#                 "level": ($opts.level // $opts.l // $defautls.level),
#                 "template": ($opts.template // $opts.t //$defautls.template),
#                 "format": ($opts.format // $opts.f //$defautls.format),
#                 "context": ($opts.context // $opts.c //$defautls.context),
#                 "file": ($opts.file // $opts.fl //$defautls.file),
#                 "maxsize": ($opts.maxsize // $opts.s //$defautls.maxsize),
#                 "message": ($opts.message // $opts.m //$defautls.message)
#             }
#         } | del(.opts.__args)'

#     }
#     watch() {
#         # echo "$LOGGER_OPTS"
#         local LOG_FORMAT=$(jq -r '.template' <<<"$LOGGER_OPTS")
#         local LOG_FILE=$(jq -r '.file' <<<"$LOGGER_OPTS")
#         LOG_FORMAT=$({
#             echo "$LOG_FORMAT" |
#                 sed 's/{{/\\(/g' |
#                 sed 's/}}/)/g' |
#                 sed -E 's/\{\{\.([^}]+)\}\}/.\1/g' |
#                 sed -E 's/\| ascii_upcase/| ascii_upcase/g'
#         })
#         # echo -ne "${YELLOW}[${YDK_CLI_NAME^^}]${NC}"
#         tail -f "${LOG_FILE}" | jq -r '
#                 . | " '"$LOG_FORMAT"'" | gsub("\\n"; "\n")
#             ' >/dev/stderr
#     }
#     __is_log_level() {
#         local LEVEL=${1:-info}
#         for LEVEL_IDX in "${!YDK_LOGGER_LEVELS[@]}"; do
#             [[ $LEVEL == "${YDK_LOGGER_LEVELS[$LEVEL_IDX]}" ]] && return 0
#         done
#         return 1
#     }
#     __json() {
#         local LOG_OPTS=$1 && shift
#         local LOG_LEVEL="$1" && shift
#         local LOG_MESSAGE=$(message "$1") && shift
#         if [[ -n "$LOG_MESSAGE" ]] && jq -e . >/dev/null 2>&1 <<<"$LOG_MESSAGE"; then
#             LOG_MESSAGE="{\"data\": $(jq -c . <<<"$LOG_MESSAGE")}"
#         else
#             LOG_MESSAGE="{\"data\":\"$LOG_MESSAGE\"}"
#         fi
#         LOG_LEVEL=$(levels | jq -cr ".[] | select(.name == \"$LOG_LEVEL\") | . // {}")
#         # echo "LOG_OPTS = ${LOG_OPTS:-"{}"}"
#         # echo "LOG_LEVEL = ${LOG_LEVEL:-"{}"}"
#         # echo "LOG_MESSAGE = ${LOG_MESSAGE:-"{}"}"
#         jq -cn \
#             --argjson config "$(jq '.' <<<"${YDK_CONFIG:-"{}"}")" \
#             --argjson options "$(jq '.' <<<"${LOG_OPTS:-"{}"}" 2>/dev/null)" \
#             --argjson priority "$(jq '.' <<<"${LOG_LEVEL:-"{}"}" 2>/dev/null)" \
#             --argjson data "$(jq '.' <<<"${LOG_MESSAGE:-"{}"}" 2>/dev/null)" \
#             '{
#                 "config": $config,
#                 "timestamp": (now | todate),
#                 "host": "'"$(hostname)"'",
#                 "color": $priority.color,
#                 "icon": $priority.icon,               
#                 "priority": $priority.level,
#                 "level": $priority.name,
#                 "enabled": $priority.enabled,
#                 "context": $options.context,
#                 "template": $options.template,
#                 "file": $options.file,
#                 "format": $options.format,
#                 "message": $data.data,
#                 "tags": [
#                     "context:\($options.context)"
#                 ],
#                 "path": "",                    
#                 "type": "\($options.context)-log",                    
#                 "pid": '$$',
#                 "ppid": '$PPID',
#                 "etime": "'"$(ydk:process etime)"'",
#                 "cli": "'"${YDK_CLI_NAME:-}"'",
#                 "name": "'"${YDK_CLI_NAME:-}"'"
#             }'
#     }
#     __text() {
#         local LOG_JSON=$1
#         local LOG_FORMAT=$(jq -r '.template' <<<"$LOG_JSON")
#         LOG_FORMAT=$({
#             echo "$LOG_FORMAT" |
#                 sed 's/{{/\\(/g' |
#                 sed 's/}}/)/g' |
#                 sed -E 's/\{\{\.([^}]+)\}\}/.\1/g' |
#                 sed -E 's/\| ascii_upcase/| ascii_upcase/g'
#         })
#         echo -ne "${YELLOW}[${YDK_BRAND^^}]${NC}" 1>&2
#         local LOG_FORMATTED=$(
#             jq -r '
#                 . | " '"$LOG_FORMAT"'" | gsub("\\n"; "\n")
#             ' <<<"$LOG_JSON"
#         )
#         echo -e "$LOG_FORMATTED" 1>&2
#         return 0

#     }
#     __write() {
#         local LOG_JSON=$(__json "$@")
#         local LOG_FILE=$(jq -r '.file' <<<"$LOG_JSON")
#         jq -c . <<<"$LOG_JSON" >>"$LOG_FILE"
#         __text "$LOG_JSON"
#         # echo -ne "${YELLOW}[${YDK_CLI_NAME^^}]${NC} $$ "
#         # echo -e "$LOG_CONTENT"
#         # # if [[ "$(jq -r '.level' <<<"$LOG_JSON" 2>/dev/null)" == "output" ]]; then
#         # local LOG_CONTENT=$(jq -r '.message' <<<"$LOG_JSON")
#         # echo -ne "${YELLOW}[${YDK_CLI_NAME^^}]${NC} $$ " 1>&2
#         # echo -e "$LOG_CONTENT" 1>&2
#         # if jq -e . >/dev/null 2>&1 <<<"$LOG_CONTENT"; then
#         #     jq -c . <<<"$LOG_CONTENT"
#         # else
#         #     echo -e "$LOG_CONTENT"
#         # fi
#         # echo -ne "${YELLOW}[${YDK_CLI_NAME^^}]${NC} $$ "
#         # jq -rc '. + {
#         #     "message": .message | gsub("\\n"; "\n")
#         # } |
#         # select(.message | length > 0) |
#         # "\(.message) \(.pid)"
#         # ' <<<"$LOG_JSON"
#         # fi
#         return 0
#     }
#     activate() {
#         echo "logger activated" # >&1
#         # return 233
#     }
#     __logger:opts() {
#         local YDK_LOGGER_OPTS=()
#         while [[ $# -gt 0 ]]; do
#             case $1 in
#             *)
#                 YDK_LOGGER_OPTS+=("$1")
#                 shift
#                 ;;
#             esac
#         done
#         set -- "${YDK_LOGGER_OPTS[@]}"
#         [[ "${#YDK_LOGGER_OPTS[@]}" -eq 0 ]] && {
#             ydk:throw 252 "Failed to parse logger options"
#             return 1
#         }
#         echo "${YDK_LOGGER_OPTS[@]}" >&4
#         return 0
#     }
#     local LOGGER_OPTS="{\"context\":\"${YDK_LOGGER_CONTEXT:-ydk}\"}"
#     local LOGGER_ARGS=()
#     while [[ $# -gt 0 ]]; do
#         case $1 in
#         -l | --level)
#             local LOGGER_OPTS=$(jq '. + {"level": "'"$2"'"}' <<<"$LOGGER_OPTS")
#             shift 2
#             ;;
#         -c | --context)
#             local LOGGER_OPTS=$(jq '. + {"context": "'"$2"'"}' <<<"$LOGGER_OPTS")
#             shift 2
#             ;;
#         -f | --format)
#             local LOGGER_OPTS=$(jq '. + {"format": "'"$2"'"}' <<<"$LOGGER_OPTS")
#             shift 2
#             ;;
#         -t | --template)
#             local LOGGER_OPTS=$(jq '. + {"template": "'"$2"'"}' <<<"$LOGGER_OPTS")
#             shift 2
#             ;;
#         -m | --message)
#             local LOGGER_OPTS=$(jq '. + {"message": "'"$2"'"}' <<<"$LOGGER_OPTS")
#             shift 2
#             ;;
#         *)
#             LOGGER_ARGS+=("$1")
#             shift
#             ;;
#         esac
#     done
#     set -- "${LOGGER_ARGS[@]}"
#     # set -- "$(__logger:opts "$@" 4>&1)"
#     local LOGGER_OPTS=$(defaults "$LOGGER_OPTS") && LOGGER_OPTS=$(jq -c '.values' <<<"$LOGGER_OPTS")
#     if __is_log_level "$1" 2>/dev/null; then
#         __write "$LOGGER_OPTS" "${LOGGER_ARGS[@]}" # 2>/dev/null
#         return $?
#     else
#         ydk:try "$@"
#         return $?
#     fi

#     # local LOGGER_OPTS=$(ydk:argv walk "$@" | jq -cr .)
#     # local LOG_ARGS=($(jq '.__args[]' <<<"$LOGGER_OPTS"))
#     # IFS=$'\n' read -r -d '' -a LOG_ARGS <<<"$(jq -r '.__args[]' <<<"$LOGGER_OPTS")"
#     # set -- "${LOG_ARGS[@]}"
#     # local LOGGER_OPTS=$(defaults "$LOGGER_OPTS") && LOGGER_OPTS=$(jq -c '.values' <<<"$LOGGER_OPTS")
#     # __is_log_level "$1" && echo "$1 is log level" || echo "$1 is not log level"
#     # if __is_log_level "$1"; then
#     #     __write "$LOGGER_OPTS" "${LOG_ARGS[@]}"
#     #     return $?
#     # else
#     #     ydk:try "$@"
#     #     return $?
#     # fi
# }
{
    [[ -z "$YDK_DEFAULTS_LOGGER" ]] && declare -g -a YDK_DEFAULTS_LOGGER=(
        # Log Level
        [0]="trace"
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
