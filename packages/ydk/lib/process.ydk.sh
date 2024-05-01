#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:process() {
    etime() {
        {
            if grep -q 'Alpine' /etc/os-release; then
                ps -o etime= "$$" | awk -F "[:]" '{ print ($1 * 60) + $2 }' | head -n 1
            else
                ps -o etime= -p "$$" | sed -e 's/^[[:space:]]*//' | sed -e 's/\://' | head -n 1
            fi
        } >&4
    }

    inspect() {
        jq -cn \
            --arg pid "$$" \
            --arg etime "$(etime 4>&1)" \
            --argjson cli "$(ydk:cli)" \
            --argjson package "{}" \
            '{ 
                pid: $pid,
                etime: $etime,
                cli: $cli,
                package: $package
            }' >&4
    }
    ydk:try "$@" 4>&1
    return $?
}
#!/usr/bin/env bash
# # shellcheck disable=SC2044,SC2155,SC2317
# process() {
#     local YWT_CMD_PROCESS=$$ && readonly YWT_CMD_PROCESS
#     local YWT_CMD_FILE=$0 && readonly YWT_CMD_FILE
#     local YWT_CMD_ARGS=$* && readonly YWT_CMD_ARGS
#     local YWT_CMD_ARGS_LEN=$# && readonly YWT_CMD_ARGS_LEN
#     local YWT_IS_BINARY=false
#     LC_ALL=C grep -a '[^[:print:][:space:]]' "$YWT_CMD_FILE" >/dev/null && YWT_IS_BINARY=true
#     info() {
#         local FILE="$YWT_CMD_FILE"
#         echo "{
#             \"pid\": \"$YWT_CMD_PROCESS\",
#             \"file\": \"$FILE\",
#             \"args\": \"$YWT_CMD_ARGS\",
#             \"args_len\": \"$YWT_CMD_ARGS_LEN\",
#             \"name\": \"$YWT_CMD_NAME\",
#             \"initialized\": \"$YWT_INITIALIZED\",
#             \"binary\": \"$YWT_IS_BINARY\"
#         }"
#     }
#     __nnf "$@" || usage "process" "$?" "$@" && return 1
#     return 0
# }
# (
#     export -f process
# )
