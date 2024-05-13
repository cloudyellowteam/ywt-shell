#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317,SC2120,SC2016
# @file onescan.ydk.sh
# @brief One Scan is a scan hub for lazy developers
# @description One Scan is a scan hub for lazy developers
# @option -i | auto-install | Auto install enabled. Default is true
# @option -u | auto-uninstall | Auto uninstall enabled. Default is false
# @option -k | keep-output | Keep output enabled. Default is false
# @option -na | --non-await | Await disabled. Default is true
# @option -o=* | --output-file=* | Output file set to ${YDK_ONESCAN_CONFIG["output-file"]}
# @example ydk onescan
ydk:onescan() {
    YDK_LOGGER_CONTEXT="onescan"
    [[ -z "${YDK_ONESCAN_CONFIG[*]}" ]] && declare -A YDK_ONESCAN_CONFIG=(
        ["scanners"]="/workspace/rapd-shell/assets/scanners.json"
        ["auto-install"]=true
        ["auto-uninstall"]=false
        ["keep-output"]=false
        ["non-await"]=true
    )
    [[ -z "$YDK_ONESCAN_SPECS" ]] && declare -A YDK_ONESCAN_SPECS=(
        ["all"]="."
        ["count"]=". | length"
        ["query"]=".[] | select(.name == \$SCANNER_ID or .id == \$SCANNER_ID)"
        ["installed"]="
            .[] | 
            if .id == \$SCANNER_ID then 
                .installed = \$SCANNER_INSTALLED
            else 
                .installed = true
            end"
        ["available"]=".[] | select(.installed == true or .installed == \"true\")"
        ["unavailable"]=".[] | select(.installed == false or .installed == \"false\")"
        ["packages"]=".packages[]"
        ["api-endpoints"]='
            . |
            to_entries[] |
            .value as $scanner |
            $scanner.flags as $flags |                
            "ydk onescan api \($scanner.cli.cmd)/" as $command |
            map(
                $scanner.api |
                to_entries[] |
                .key as $method |
                .value as $methodRef |
                [
                    $method, 
                    (
                        $methodRef.args |
                        (
                            .[] |
                            . |
                            if contains("{{") then 
                                . as $param |
                                . | sub("{{."; "") | sub("}}"; "") as $paramName | 
                                $flags |
                                to_entries[] |
                                select(.key == $paramName) |
                                .value as $paramRef |
                                [
                                    (
                                        if $paramRef.required == true then
                                            "*"
                                        else
                                            "?"
                                        end 
                                    ),
                                    "[\($paramRef.env)|\($paramRef.argv)]",                                        
                                    "(\($paramRef.type))",
                                    "=",
                                    "\"\($paramRef.default)\""
                                ] |
                                join("")
                            else 
                                null
                            end
                        )
                    )
                ] | join(" ")
            ) as $methods |   
            [
                $scanner.id,
                $scanner.name,
                "\(if $scanner.installed then "yes" else "no" end)",
                $command + 
                (
                    $methods |
                    flatten |
                    unique |
                    sort |
                    join("\n-\t-\t-\t" + $command)
                )
            ]
        '
        ["status-log"]='
            .[1] |
            if .status == 0 then
                "success"
            else
                "error"
            end'
        ["result-summary"]='
            .[0] as $scanner |
            .[1] as $result |
            "/\($scanner.name)/\($scanner.path) done with status \($result.status) in \($result.elapsed_time) seconds. Content type \($result.content.type), at \($result.location)"'
        ["result-output"]='
            .[0] as $scanner |
            .[1] as $result |
            {
                "scanner": $scanner,
                "result": $result
            }'
    ) && readonly YDK_ONESCAN_SPECS && export YDK_ONESCAN_SPECS
    # @internal
    __onescan:entrypoint() {
        local ONESCAN_SCANNER_NAME="$1"
        local ONESCAN_API_PATH=""
        [ -z "$ONESCAN_SCANNER_NAME" ] && ydk:log error "No entrypoint provided" && return 22
        [[ "$ONESCAN_SCANNER_NAME" == */* ]] && ONESCAN_SCANNER_NAME=$(cut -d'/' -f1 <<<"$1") && ONESCAN_API_PATH=$(cut -d'/' -f2- <<<"$1")
        [[ -z "$ONESCAN_SCANNER_NAME" ]] && ydk:log error "No scanner name provided" && return 22
        local ONESCAN_SCANNER=$({
            if ! scanners get "$ONESCAN_SCANNER_NAME" 4>&1 >&4; then
                ydk:log error "Scanner $ONESCAN_SCANNER_NAME not found"
                return 10
            fi
        } 4>&1)
        [[ -z "$ONESCAN_SCANNER" ]] && ydk:log error "Scanner $ONESCAN_SCANNER_NAME not found" && return 22
        if ! {
            jq -cnr \
                --arg API_SCANNER_NAME "$ONESCAN_SCANNER_NAME" \
                --arg API_SCANNER_PATH "${ONESCAN_API_PATH:-""}" \
                --argjson SCANNER "$(jq -c . <<<"$ONESCAN_SCANNER")" \
                '
                {
                    "scanner":$SCANNER,
                    "path":$API_SCANNER_PATH,
                    "name":$API_SCANNER_NAME
                }'
        } 2>/dev/null >&4; then
            ydk:log error "Scanner $ONESCAN_SCANNER_NAME endpoint unavailable"
            return 1
        fi
        return 0
    }
    # @internal
    __onescan:cli:arg() {
        {
            for ARG in "$@"; do
                case "$ARG" in
                *\{\{.*\}\}*)
                    echo -n "$(ydk:interpolate "$ARG" "$@" 4>&1),"
                    ;;
                *) ;;
                esac
                if ydk:is number "$ARG"; then
                    echo -n "$ARG,"
                elif ydk:is boolean "$ARG"; then
                    echo -n "$ARG,"
                elif jq -e . <<<"$ARG" 2>/dev/null 1>/dev/null; then
                    echo -n "$(jq -c . <<<"$ARG"),"
                else
                    echo -n "\"$ARG\","
                fi
            done
        } | sed 's/,$//' >&4
        return $?
    }
    # @internal
    __onescan:cli:result() {
        local SCANNER_OUTPUT_FILE=$1
        local SCANNER_STATUS=$2
        local SCANNER_PID=$3
        local SCANNER_START_AT=$4
        local SCANNER_END_AT=$(date +%s)
        local SCANNER_ELAPSED_TIME=$((SCANNER_END_AT - SCANNER_START_AT))
        {
            echo -n "{"
            echo -n "\"status\":$SCANNER_STATUS,"
            echo -n "\"pid\":$SCANNER_PID,"
            echo -n "\"location\":\"$SCANNER_OUTPUT_FILE\","
            echo -n "\"start_at\":$SCANNER_START_AT,"
            echo -n "\"end_at\":$SCANNER_END_AT,"
            echo -n "\"elapsed_time\":$SCANNER_ELAPSED_TIME,"
            echo -n "\"content\": $(__onescan:cli:result:content "$SCANNER_OUTPUT_FILE" 4>&1)"
            echo -n "}"
        } | jq -c . 2>/dev/null >&4
        return "$SCANNER_STATUS"
    }
    # @internal
    __onescan:cli:result:content() {
        local SCANNER_OUTPUT_FILE=$1
        {
            local SCANNER_OUTPUT_TYPE=$({
                if jq -e . "$SCANNER_OUTPUT_FILE" 2>/dev/null 1>/dev/null; then
                    if ydk:is sarif "$SCANNER_OUTPUT_FILE"; then
                        echo -n "sarif"
                    else
                        echo -n "json"
                    fi
                else
                    echo -n "plain"
                fi
            })
            echo -n "{"
            echo -n "\"type\":\"$SCANNER_OUTPUT_TYPE\","
            echo -n "\"data\":"
            case "$SCANNER_OUTPUT_TYPE" in
            "sarif" | "json")
                jq -c . "$SCANNER_OUTPUT_FILE" 2>/dev/null
                ;;
            "plain")
                echo -n "\"$(sed 's/"/\\"/g' <"$SCANNER_OUTPUT_FILE" 2>/dev/null)\""
                ;;
            *)
                echo -n "\"${SCANNER_OUTPUT_FILE}\""
                ;;
            esac
            echo -n "}"
        } | jq -c . >&4
    }
    # @internal
    __onescan:api:validate() {
        local ONESCAN_ENTRYPOINT=$(__onescan:entrypoint "$1" 4>&1)
        [ -z "$ONESCAN_ENTRYPOINT" ] && ydk:log error "No entrypoint provided" && return 22
        local ONESCAN_SCANNER_API=$(jq -cr '.scanner.api' <<<"$ONESCAN_ENTRYPOINT")
        local ONESCAN_SCANNER_NAME=$(jq -r '.name' <<<"$ONESCAN_ENTRYPOINT")
        # local ONESCAN_SCANNER_API_PATH=$(jq -r '.path' <<<"$ONESCAN_ENTRYPOINT")
        local ONESCAN_SCANNER_API_METHODS=$(jq -cr '.' <<<"$ONESCAN_SCANNER_API")
        local ONESCAN_SCANNER_API_METHODS_COUNT=$(jq -cr 'length' <<<"$ONESCAN_SCANNER_API_METHODS")
        [ -z "$ONESCAN_SCANNER_API" ] && ydk:log error "Scanner $ONESCAN_SCANNER_NAME api not exists" && return 1
        # [ -z "$ONESCAN_SCANNER_API_PATH" ] && ydk:log error "Scanner $ONESCAN_SCANNER_NAME api path not exists" && return 1
        [ -z "$ONESCAN_SCANNER_API_METHODS" ] && ydk:log error "Scanner $ONEONESCAN_SCANNER_NAMESCAN_NAME api methods not exists" && return 1
        [ "${ONESCAN_SCANNER_API_METHODS_COUNT:-0}" -eq 0 ] && ydk:log error "Scanner $ONESCAN_SCANNER_NAME api methods not exists" && return 1
        jq -c . <<<"$ONESCAN_ENTRYPOINT" >&4
        return 0
    }
    # @internal
    __onescan:api:endpoint() {
        local ONESCAN_ENTRYPOINT="${1}"
        local ONESCAN_SCANNER_API=$(jq -cr '.scanner.api' <<<"$ONESCAN_ENTRYPOINT")
        # local ONESCAN_SCANNER_API_METHODS=$(jq -cr '.' <<<"$ONESCAN_SCANNER_API")
        local ONESCAN_SCANNER_FLAGS=$(jq -cr '.scanner.flags' <<<"$ONESCAN_ENTRYPOINT")
        # local RANDOM_COLOR=$((RANDOM % ${#YDK_COLORS_NAMES[@]}))
        # local RANDOM_COLOR="${YDK_COLORS_NAMES[RANDOM_COLOR]}"
        # local RANDOM_COLOR="${YDK_COLORS[$RANDOM_COLOR]}"
        local RANDOM_COLOR=$(ydk:colors random 4>&1)
        {
            # echo -e "Command\tOptions\tDescription"
            jq -rc '. | to_entries[] | .key' <<<"$ONESCAN_SCANNER_API" | while read -r ONESCAN_SCANNER_API_METHOD && [ -n "$ONESCAN_SCANNER_API_METHOD" ]; do
                [ -z "$ONESCAN_SCANNER_API_METHOD" ] && continue
                echo -n "ydk onescan api "
                echo -ne "${RANDOM_COLOR}$(
                    jq -r '.name' <<<"$ONESCAN_ENTRYPOINT"
                )${NC}${NBG}"
                echo -n "/"
                # ydk:colors random "colored" 4>&1
                echo -en "$ONESCAN_SCANNER_API_METHOD\t"
                local ONESCAN_SCANNER_API_METHOD_REF=$(jq -cr '.["'"$ONESCAN_SCANNER_API_METHOD"'"]' <<<"$ONESCAN_SCANNER_API")
                local ONESCAN_SCANNER_API_METHOD_DESC=$(jq -r '.help' <<<"$ONESCAN_SCANNER_API_METHOD_REF")
                local ONESCAN_SCANNER_API_METHOD_ARGS="$(jq -cr '.args[]' <<<"$ONESCAN_SCANNER_API_METHOD_REF")"
                # [ -z "${ONESCAN_SCANNER_API_METHOD_ARGS[*]}" ] && continue
                readarray -t ONESCAN_SCANNER_API_METHOD_ARGS <<<"${ONESCAN_SCANNER_API_METHOD_ARGS}"
                # echo -n "${#ONESCAN_SCANNER_API_METHOD_ARGS[@]}/"
                # echo -n "${ONESCAN_SCANNER_API_METHOD_ARGS[*]}"
                for ARG_IDX in "${!ONESCAN_SCANNER_API_METHOD_ARGS[@]}"; do
                    local ARG_NAME="${ONESCAN_SCANNER_API_METHOD_ARGS[ARG_IDX]}"
                    ! [[ $ARG_NAME == *\{\{.*\}\}* ]] && continue
                    ARG_NAME=${ARG_NAME//\{\{./--}
                    ARG_NAME=${ARG_NAME//\}\}/}
                    # ${ARG_NAME}=
                    echo -n "$(
                        jq -cr '
                            .["'"${ARG_NAME//--/}"'"] |
                            if . == null then
                                "null"
                            else
                                "[\(.env) | \(.argv)]\(
                                    if .required then "*" else "?" end
                                )(\(.type))=\"\(.default)\" \(.description[:10])  "
                            end
                        ' <<<"$ONESCAN_SCANNER_FLAGS"
                    )"
                    [ "$ARG_IDX" -lt $((${#ONESCAN_SCANNER_API_METHOD_ARGS[@]} - 1)) ] && echo -en "\n\t"
                done
                echo -ne "\t$ONESCAN_SCANNER_API_METHOD_DESC"
                echo ""
            done #< <(jq -rc '. | to_entries[] | .key' <<<"$ONESCAN_SCANNER_API")
        } >&4
    }
    # @description CLI entrypoint
    # @arg $1 SCANNER_ID Scanner ID
    # @arg $2... CLI_ARGS CLI Arguments
    # @exitcode 22 If no entrypoint provided
    # @exitcode 1 If no CLI provided
    # @exitcode 1 If no command provided
    # @exitcode 1 If no default args provided
    # @exitcode 1 If no name provided
    # @exitcode 127 If scanner is not installed
    # @exitcode 1 If scanner cli metadata not exists
    # @exitcode 1 If scanner cli unavailable
    # @exitcode 1 If scanner cli command not exists
    # @exitcode 1 If scanner result not exists
    # @example
    #   ydk onescan cli scanner1 arg1 arg2
    #   ydk onescan --output-file=./output.json cli scanner1 arg1 arg2 arg3
    cli() {
        local ONESCAN_ENTRYPOINT=$(__onescan:entrypoint "$1" 4>&1)
        [ -z "$ONESCAN_ENTRYPOINT" ] && ydk:log error "No entrypoint provided" && return 22
        local ONESCAN_CLI=$(jq -r '.scanner.cli' <<<"$ONESCAN_ENTRYPOINT")
        local ONESCAN_CMD=$(jq -r '.scanner.cli.cmd' <<<"$ONESCAN_ENTRYPOINT")
        local ONESCAN_CMD_DEFAULT_ARGS=$(jq -r '.scanner.cli.args[]' <<<"$ONESCAN_ENTRYPOINT")
        local ONESCAN_API_PATH=$(jq -r '.path' <<<"$ONESCAN_ENTRYPOINT")
        local ONESCAN_SCANNER_NAME=$(jq -r '.name' <<<"$ONESCAN_ENTRYPOINT")
        {
            [ -z "$ONESCAN_CLI" ] && ydk:log error "No CLI provided" && return 22
            [ -z "$ONESCAN_CMD" ] && ydk:log error "No command provided" && return 22
            [ -z "$ONESCAN_CMD_DEFAULT_ARGS" ] && ydk:log error "No default args provided" && return 22
            # [ -z "$ONESCAN_API_PATH" ] && ydk:log error "No path provided" && return 22
            [ -z "$ONESCAN_SCANNER_NAME" ] && ydk:log error "No name provided" && return 22
            if ! command -v "$ONESCAN_CMD" 2>/dev/null 1>/dev/null; then
                ydk:log error "Scanner $ONESCAN_CMD is not installed"
                return 127
            fi
        }
        readarray -t ONESCAN_CMD_DEFAULT_ARGS <<<"$ONESCAN_CMD_DEFAULT_ARGS"
        [ -z "${ONESCAN_CMD_DEFAULT_ARGS[*]}" ] && ydk:log error "No default args provided" && return 22
        local ONESCAN_CLI_METADATA=$({
            {
                echo -n "{"
                echo -n "\"scanner\":$(jq -c '.scanner | del(.cli)' <<<"$ONESCAN_ENTRYPOINT"),"
                echo -n "\"cmd\":["
                echo -n "\"$ONESCAN_CMD\","
                __onescan:cli:arg "${ONESCAN_CMD_DEFAULT_ARGS[@]}" "$@" 4>&1
                echo -n ",\"\""
                echo -n "]"
                echo -n "}"
                return 0
            } | jq -c .
        })
        [ -z "$ONESCAN_CLI_METADATA" ] && ydk:log error "Scanner $ONESCAN_CMD cli metadata not exists" && return 1
        if ! jq . 2>/dev/null 1>/dev/null <<<"${ONESCAN_CLI_METADATA}"; then
            ydk:log error "Scanner $ONESCAN_CMD cli unavailable"
            return 1
        fi
        readarray -t ONESCAN_CLI_COMMAND <<<"$(jq -cr '.cmd[]' <<<"$ONESCAN_CLI_METADATA")"
        [ -z "${ONESCAN_CLI_COMMAND[*]}" ] && ydk:log error "Scanner $ONESCAN_CMD cli command not exists" && return 1
        [[ "${#ONESCAN_CLI_COMMAND[@]}" -eq 0 ]] && ydk:log error "Scanner $ONESCAN_CMD cli command not exists" && return 1
        local ONESCAN_CLI_COMMAND_ARGS=("${ONESCAN_CLI_COMMAND[@]:1}")
        # local ONESCAN_CLI_COMMAND_CMD="${ONESCAN_CLI_COMMAND[0]}"
        local ONESCAN_CLI_COMMAND_ARGS_COUNT="${#ONESCAN_CLI_COMMAND_ARGS[@]}"
        local ONESCAN_CLI_OUTPUT=$(ydk:temp "onescan-cli-output" 4>&1)
        ydk:log info "Running scanner $ONESCAN_SCANNER_NAME with (${ONESCAN_CLI_COMMAND_ARGS_COUNT}) ${ONESCAN_CLI_COMMAND_ARGS[*]}"
        local ONESCAN_CMD_START_AT=$(date +%s)
        ${ONESCAN_CMD} "${ONESCAN_CLI_COMMAND_ARGS[@]}" 2>/dev/null 1>"$ONESCAN_CLI_OUTPUT"
        local ONESCAN_CMD_PID=$!
        local ONESCAN_CMD_STATUS=$?
        local ONESCAN_CMD_LOG_ACTION="success"
        [ "$ONESCAN_CMD_STATUS" -ne 0 ] && ONESCAN_CMD_LOG_ACTION="error"
        local ONESCAN_CLI_RESULT=$(__onescan:cli:result "$ONESCAN_CLI_OUTPUT" "$ONESCAN_CMD_STATUS" "$ONESCAN_CMD_PID" "$ONESCAN_CMD_START_AT" 4>&1)
        [ -z "$ONESCAN_CLI_RESULT" ] && ydk:log error "Scanner $ONESCAN_SCANNER_NAME result not exists" && return 1
        jq -c . <<<"${ONESCAN_CLI_RESULT}" >"$ONESCAN_CLI_OUTPUT"
        local ONESCAN_CLI_OUTPUT_LOG=$(jq -rc '.content.data' "$ONESCAN_CLI_OUTPUT" 2>/dev/null)
        ONESCAN_CLI_OUTPUT_LOG=$(head -c 70 <<<"$ONESCAN_CLI_OUTPUT_LOG" 2>/dev/null)
        ydk:log "$ONESCAN_CMD_LOG_ACTION" "Scanner $ONESCAN_SCANNER_NAME exited with status $ONESCAN_CMD_STATUS. Results $([ "${YDK_ONESCAN_CONFIG["keep-output"]}" = false ] && echo -n "was" || echo -n "in") $ONESCAN_CLI_OUTPUT"
        ydk:log output "Result Data: $ONESCAN_CLI_OUTPUT_LOG"
        jq -c . "$ONESCAN_CLI_OUTPUT" >&4
        [ "${YDK_ONESCAN_CONFIG["output-file"]}" ] && cp -f "$ONESCAN_CLI_OUTPUT" "${YDK_ONESCAN_CONFIG["output-file"]}"
        [ "${YDK_ONESCAN_CONFIG["keep-output"]}" = false ] && rm -f "$ONESCAN_CLI_OUTPUT"
        return "$ONESCAN_CMD_STATUS"
        # jq . <<<"$ONESCAN_CLI_METADATA" >&4
        # cat "$ONESCAN_CLI_OUTPUT" >&4
        # rm -f "$ONESCAN_CLI_OUTPUT"
        # return 0
    }
    # @description List api endpoints
    # @arg $@ SCANNER_ID Scanner ID
    # @exitcode 22 If no entrypoint provided
    # @example
    #   ydk onescan endpoints
    #   ydk onescan endpoints scanner1 scanner2
    endpoints() {
        ydk:log info "Getting ${*:-"all"} endpoints"
        local SCANNERS_FILE="${YDK_ONESCAN_CONFIG[scanners]}"
        [ ! -f "$SCANNERS_FILE" ] && echo "[]" >&4 && ydk:log error "No scanners found" && return 1
        # local YDK_ONESCAN_ENDPOINT_ARGS=("${@}")
        # if [[ ${#YDK_ONESCAN_ENDPOINT_ARGS[@]} -eq 0 ]]; then
        #     readarray -t YDK_ONESCAN_ENDPOINT_ARGS <<<"$(jq -cr '.[] | .name' <<<"$(scanners list 4>&1)")"
        # fi
        {
            echo -e "Available\tAPI"
            jq -rc "${YDK_ONESCAN_SPECS["api-endpoints"]} | @tsv" \
                <<<"$(scanners list 4>&1)" | while IFS= read -r LINE; do
                local SCANNER_ID=$(cut -d$'\t' -f1 <<<"$LINE")
                local SCANNER_NAME=$(cut -d$'\t' -f2 <<<"$LINE")
                if [[ "${#@}" -gt 0 && ! ${*} =~ $SCANNER_NAME ]]; then
                    continue
                fi
                if [[ "$SCANNER_NAME" != "-" ]]; then
                    local RANDOM_COLOR=$(ydk:colors random 4>&1)
                fi
                LINE=${LINE//yes/"${GREEN}Yes${NC}"}
                LINE=${LINE//no/"${RED}No${NC}"}
                LINE=${LINE//${SCANNER_ID}/"${RANDOM_COLOR}${SCANNER_ID}${NC}"}
                LINE=${LINE//${SCANNER_NAME}/"${RANDOM_COLOR}${SCANNER_NAME}${NC}"}
                LINE=${LINE//"ydk"/"${YELLOW}ydk${NC}"}
                LINE=${LINE//"onescan api"/"${UNDERLINE}onescan api${NS}"}
                LINE=${LINE//\\t/$'\t'}
                LINE=${LINE//\\t/$'\n'}
                echo -e "$LINE" | cut -f3-
            done
        } | column -t -s $'\t' 2>/dev/null >&4
        return 0
        # local YDK_ONESCAN_ENDPOINT_ARGS=("${@}")
        # if [[ ${#YDK_ONESCAN_ENDPOINT_ARGS[@]} -eq 0 ]]; then
        #     # jq -r '. | map(.name) | join(" ")' <<<"$(scanners list 4>&1)"
        #     # jq -r '.[] | .name' <<<"$(scanners list 4>&1)"
        #     readarray -t YDK_ONESCAN_ENDPOINT_ARGS <<<"$(jq -cr '.[] | .name' <<<"$(scanners list 4>&1)")"
        # fi
        # {
        #     echo -e "Command\tOptions\tDescription"
        #     for SCANNER_ID in "${YDK_ONESCAN_ENDPOINT_ARGS[@]}"; do
        #         # __onescan:api:validate "$ARG"
        #         local ONESCAN_ENTRYPOINT=$(__onescan:api:validate "${SCANNER_ID,,}" 4>&1)
        #         [ -z "$ONESCAN_ENTRYPOINT" ] && ydk:log error "No entrypoint provided" && return 22
        #         ydk:log info "Getting $SCANNER_ID API endpoints"
        #         __onescan:api:endpoint "$ONESCAN_ENTRYPOINT" 4>&1 >&4
        #         # local ONESCAN_SCANNER_API=$(jq -cr '.scanner.api' <<<"$ONESCAN_ENTRYPOINT")
        #         # jq -c . <<<"$ONESCAN_SCANNER_API" >&4
        #         break
        #     done
        # } | column -t -s $'\t' >&4 &
        # # local YDK_ONESCAN_ENDPOINTS_PID=$!
        # ydk:await spin "$!" "Getting endpoints"
        # return 0
    }
    # @description Get endpoint help
    # @arg $1 <Scanner Identifier (Name or ID)>/<Api Path>
    # @example
    #   ydk onescan api <scanner>/<api path>
    #   ydk onescan api cloc/version
    #   ydk onescan api cloc/count --target=.
    endpoint() {
        local ONESCAN_ENTRYPOINT=$(__onescan:entrypoint "$1" 4>&1)
        [ -z "$ONESCAN_ENTRYPOINT" ] && ydk:log error "No entrypoint provided" && return 22
        local ONESCAN_API_PATH=$(jq -r '.path' <<<"$ONESCAN_ENTRYPOINT")
        local ONESCAN_SCANNER_NAME=$(jq -r '.name' <<<"$ONESCAN_ENTRYPOINT")
        {
            [ -z "$ONESCAN_API_PATH" ] && ydk:log error "No path provided" && return 22
            [ -z "$ONESCAN_SCANNER_NAME" ] && ydk:log error "No name provided" && return 22
        }
        jq -r --arg SCANNER_ID "$ONESCAN_SCANNER_NAME" \
            --arg API_PATH "$ONESCAN_API_PATH" \
            '
            '"${YDK_ONESCAN_SPECS["query"]}"' |
            . as $scanner |
            .api |
            .[$API_PATH] |
            if . == null then
                error("Endpoint \($SCANNER_ID)/\($API_PATH) not found")
            else
                . as $endpoint |
                .args |
                [
                    .[] |
                    . as $arg |
                    . | sub("{{."; "") | sub("}}"; "") as $argName |
                    $scanner.flags |
                    .[$argName] as $argRef |
                    [
                        "\($scanner.cli.cmd)/\($API_PATH)",
                        (
                            if $argRef.required == true then
                                "*"
                            else
                                "?"
                            end
                        ),
                        "[\($argRef.env)|\($argRef.argv)]",
                        "(\($argRef.type))",
                        "=",
                        "\"\($argRef.default)\"",
                        $endpoint.help
                    ] |
                    join(" ")
                ] |
                join(" ")
            end
        ' <<<"$(scanners list 4>&1)" >&4
        return 0
    }
    # @description API entrypoint
    # @arg $1 <Scanner Identifier (Name or ID)>/<Api Path>
    # @example
    #   ydk onescan api <scanner>/<api path>
    #   ydk onescan api cloc/version
    #   ydk onescan api cloc/count --target=.
    api() {
        # ydk:log info "OneScan API"
        local ONESCAN_ENTRYPOINT=$(__onescan:entrypoint "$1" 4>&1)
        [ -z "$ONESCAN_ENTRYPOINT" ] && ydk:log error "No entrypoint provided" && return 22
        shift
        local ONESCAN_API_PATH=$(jq -r '.path' <<<"$ONESCAN_ENTRYPOINT")
        local ONESCAN_SCANNER_NAME=$(jq -r '.name' <<<"$ONESCAN_ENTRYPOINT")
        {
            [ -z "$ONESCAN_API_PATH" ] && ydk:log error "No path provided" && return 22
            [ -z "$ONESCAN_SCANNER_NAME" ] && ydk:log error "No name provided" && return 22
        }
        local ONESCAN_ENDPOINT=$(
            jq -r '
                .scanner.api |
                .["'"$ONESCAN_API_PATH"'"] |
                if . == null then
                    ""
                else
                    .
                end
            ' <<<"$ONESCAN_ENTRYPOINT"
        )
        [ -z "$ONESCAN_ENDPOINT" ] && ydk:log error "Endpoint $ONESCAN_SCANNER_NAME/$ONESCAN_API_PATH not found" && return 22
        readarray -t ONESCAN_ENDPOINT_ARGS <<<"$(jq -cr '.args[]' <<<"$ONESCAN_ENDPOINT")"
        [ -z "${ONESCAN_ENDPOINT_ARGS[*]}" ] && ydk:log error "Endpoint $ONESCAN_SCANNER_NAME/$ONESCAN_API_PATH args not found" && return 22
        # ydk:log debug "Running endpoint $ONESCAN_SCANNER_NAME/$ONESCAN_API_PATH with (${#ONESCAN_ENDPOINT_ARGS[@]}) ${ONESCAN_ENDPOINT_ARGS[*]}"
        for ONESCAN_ENDPOINT_ARG_IDX in "${!ONESCAN_ENDPOINT_ARGS[@]}"; do
            local ONESCAN_ENDPOINT_ARG="${ONESCAN_ENDPOINT_ARGS[ONESCAN_ENDPOINT_ARG_IDX]}"
            [[ "$ONESCAN_ENDPOINT_ARG" != \{\{*.*\}\} ]] && continue
            local ONESCAN_ENDPOINT_ARG_NAME=$(cut -d'.' -f2 <<<"$ONESCAN_ENDPOINT_ARG")
            ONESCAN_ENDPOINT_ARG_NAME=${ONESCAN_ENDPOINT_ARG_NAME//\}\}/}
            local ONESCAN_ARG_FLAG=$(
                jq -rc --arg ONESCAN_ENDPOINT_ARG_NAME "$ONESCAN_ENDPOINT_ARG_NAME" '
                    .scanner.flags |
                    to_entries[] |
                    select(.key == $ONESCAN_ENDPOINT_ARG_NAME) |
                    .value
                ' <<<"$ONESCAN_ENTRYPOINT"
            )
            [ -z "$ONESCAN_ARG_FLAG" ] && ydk:log error "Endpoint $ONESCAN_SCANNER_NAME/$ONESCAN_API_PATH arg $ONESCAN_ENDPOINT_ARG_NAME not found" && return 22
            {
                # echo "ONESCAN_ENDPOINT_ARG_NAME = $ONESCAN_ENDPOINT_ARG_NAME"
                # echo "ONESCAN_ARG_FLAG = $ONESCAN_ARG_FLAG"
                # echo "ONESCAN_ENDPOINT_ARG_IDX = $ONESCAN_ENDPOINT_ARG_IDX"
                local ONESCAN_ARG_ENV=$(jq -r '.env' <<<"$ONESCAN_ARG_FLAG")
                local ONESCAN_ARG_ARGV=$(jq -r '.argv' <<<"$ONESCAN_ARG_FLAG")
                local ONESCAN_ARG_TYPE=$(jq -r '.type' <<<"$ONESCAN_ARG_FLAG")
                ONESCAN_ARG_TYPE=${ONESCAN_ARG_TYPE:-"string"}
                local ONESCAN_ARG_DEFAULT=$(jq -r '.default' <<<"$ONESCAN_ARG_FLAG")
                local ONESCAN_ARG_REQUIRED=$(jq -r '.required' <<<"$ONESCAN_ARG_FLAG")
                local ONESCAN_ARG_VALUE=""
                local ONESCAN_ERROR=(
                    "Endpoint $ONESCAN_SCANNER_NAME/$ONESCAN_API_PATH arg $ONESCAN_ENDPOINT_ARG_NAME"
                )                
                # declare -g YDK_ONESCAN_CLOC_TARGET='./from-env';
                ONESCAN_ARG_VALUE=$(eval "echo \$YDK_ONESCAN_$ONESCAN_ARG_ENV")
                # getopt -u --name "$ONESCAN_ARG_ARGV" --longoptions "--$ONESCAN_ARG_ARGV" -- "$@" 2>/dev/null | cut -d'=' -f2
                [[ -z "$ONESCAN_ARG_VALUE" ]] && ONESCAN_ARG_VALUE=$(getopt -uo '' --name "${ONESCAN_ENDPOINT_ARG_NAME}" --longoptions "${ONESCAN_ENDPOINT_ARG_NAME}:" -- "$@" 2>/dev/null | cut -d' ' -f3)
                [[ -n "$ONESCAN_ARG_DEFAULT" && -z "${ONESCAN_ARG_VALUE}" ]] && ONESCAN_ARG_VALUE="$ONESCAN_ARG_DEFAULT"
                [[ "$ONESCAN_ARG_REQUIRED" == true && -z "${ONESCAN_ARG_VALUE}" ]] && ydk:log error "${ONESCAN_ERROR[0]} is required" && return 22
                ONESCAN_ERROR[0]+=", got $ONESCAN_ARG_VALUE"
                case "$ONESCAN_ARG_TYPE" in
                "number")
                    ! ydk:is number "$ONESCAN_ARG_VALUE" && ONESCAN_ERROR+=("must be a number")
                    ;;
                "digit")
                    ! ydk:is digit "$ONESCAN_ARG_VALUE" && ONESCAN_ERROR+=("must be a digit")
                    ;;
                "string")
                    [[ -z "${ONESCAN_ARG_VALUE}" ]] && ONESCAN_ERROR+=("must be a string")
                    ;;
                "boolean")
                    ! ydk:is boolean "$ONESCAN_ARG_VALUE" && ONESCAN_ERROR+=("must be a boolean")
                    ;;
                "url")
                    ! ydk:is url "$ONESCAN_ARG_VALUE" && ONESCAN_ERROR+=("must be a url")
                    ;;
                "date/iso8601")
                    ! ydk:is date/iso8601 "$ONESCAN_ARG_VALUE" && ONESCAN_ERROR+=("must be a date/iso8601")
                    ;;
                "path")
                    [[ ! -d "$ONESCAN_ARG_VALUE" && ! -f "$ONESCAN_ARG_VALUE" ]] && ONESCAN_ERROR+=("must be a path")
                    ;;
                "dir")
                    [[ ! -d "$ONESCAN_ARG_VALUE" ]] && ONESCAN_ERROR+=("must be a directory")
                    ;;
                "file")
                    [[ ! -f "$ONESCAN_ARG_VALUE" ]] && ONESCAN_ERROR+=("must be a file")
                    ;;
                *) ;;
                esac
                if [[ "${#ONESCAN_ERROR[@]}" -gt 1 ]]; then
                    local ONESCAN_RAW_ERROR="${ONESCAN_ERROR[*]}"
                    ydk:log error "$ONESCAN_RAW_ERROR"
                    return 22
                fi
            } 1>&2
            ONESCAN_ENDPOINT_ARGS[ONESCAN_ENDPOINT_ARG_IDX]=$ONESCAN_ARG_VALUE
            # ONESCAN_ENDPOINT=${ONESCAN_ENDPOINT//\{\{.${ONESCAN_ENDPOINT_ARG_NAME}\}\}/$ONESCAN_ARG_VALUE}
        done
        ydk:log debug "Running endpoint $ONESCAN_SCANNER_NAME/$ONESCAN_API_PATH with (${#ONESCAN_ENDPOINT_ARGS[@]}) ${ONESCAN_ENDPOINT_ARGS[*]}"
        # echo "${#ONESCAN_ENDPOINT_ARGS[@]} - ${ONESCAN_ENDPOINT_ARGS[*]}" 1>&2
        # jq . <<<"$ONESCAN_ENDPOINT" >&4
        return 0
    }
    # @section Scanners
    # @description Scanners entrypoint
    # @exitcode 1 If no scanners found
    # @example ydk onescan scanners
    #
    scanners() {
        local SCANNERS_FILE="${YDK_ONESCAN_CONFIG[scanners]}"
        [ ! -f "$SCANNERS_FILE" ] && echo "[]" >&4 && ydk:log error "No scanners found" && return 1
        # @description List available scanners
        # @stdout JSON List of available scanners
        # @example ydk onescan scanners list
        list() {
            # ydk:log info "$(jq -cr "${YDK_ONESCAN_SPECS[count]}" "$SCANNERS_FILE") scanners available. Use 'onescan scanners available' to list available scanners"
            {
                jq -c "${YDK_ONESCAN_SPECS[all]} | .[]" "$SCANNERS_FILE" | while read -r SCANNER && [ -n "$SCANNER" ]; do
                    [ -z "$SCANNER" ] && continue
                    local SCANNER_ID=$(jq -r '.id' <<<"$SCANNER") && [ -z "$SCANNER_ID" ] && continue
                    local SCANNER_CMD=$(jq -r '.cli.cmd' <<<"$SCANNER") && [ -z "$SCANNER_CMD" ] && continue
                    local SCANNER_INSTALLED=false
                    ydk:is command "$SCANNER_CMD" && SCANNER_INSTALLED=true
                    # command -v "$SCANNER_NAME" >/dev/null 2>&1 && SCANNER_INSTALLED=true
                    jq -rc ". + {
                        installed: $SCANNER_INSTALLED
                    }" <<<"$SCANNER"
                    # jq -rc \
                    #     --arg SCANNER_ID "$SCANNER_ID" \
                    #     --arg SCANNER_INSTALLED "$SCANNER_INSTALLED" \
                    #     "${YDK_ONESCAN_SPECS[installed]}" "$SCANNERS_FILE"
                done # < <(jq -c "${YDK_ONESCAN_SPECS[all]} | .[]" "$SCANNERS_FILE")
            } | jq -rcs '
                sort_by(.name) |
                unique_by(.name) |
                to_entries |
                map(.value)
            ' >&4
            return 0
        }
        # @description Get scanner by ID
        # @arg $1 SCANNER_ID Scanner ID
        # @exitcode 22 If scanner not found
        # @stdout JSON Scanner
        # @example ydk onescan scanners get scanner1
        get() {
            local SCANNER_ID=$1
            local SCANNER=$(
                jq -cr --arg SCANNER_ID "$SCANNER_ID" "${YDK_ONESCAN_SPECS[query]}" <<<"$(list 4>&1)"
            )
            [ -z "$SCANNER" ] && echo "{}" >&4 && ydk:log error "Scanner ${SCANNER_ID} not found" && return 22
            # ydk:log success "Scanner found $(jq -cr '.name' <<<"$SCANNER")"
            jq -c . <<<"$SCANNER" >&4
            return 0
        }
        # @description Get installed scanners
        # @exitcode 251 If no scanners found
        # @stdout JSON List of installed scanners
        # @example ydk onescan scanners available
        available() {
            local SCANNERS=$(list 4>&1)
            local SCANNERS_INSTALLED=$(jq -cr "${YDK_ONESCAN_SPECS[available]}" <<<"$SCANNERS")
            jq -c . <<<"$SCANNERS_INSTALLED" >&4
            local SCANNERS_INSTALLED_COUNT=$(jq -cr "${YDK_ONESCAN_SPECS[count]}" <<<"$SCANNERS_INSTALLED") &&
                SCANNERS_INSTALLED_COUNT="${SCANNERS_INSTALLED_COUNT:-0}"
            [[ "$SCANNERS_INSTALLED_COUNT" -eq 0 ]] && ydk:log warn "No scanners available" && return 251
            [[ "$SCANNERS_INSTALLED_COUNT" -gt 0 ]] && ydk:log success "${SCANNERS_INSTALLED_COUNT} scanners available" && return 0
        }
        # @description Get uninstalled scanners
        # @example ydk onescan scanners unavailable
        unavailable() {
            local SCANNERS=$(list 4>&1)
            local SCANNERS_UNINSTALLED=$(jq -cr "${YDK_ONESCAN_SPECS[unavailable]}" <<<"$SCANNERS")
            jq -c . <<<"$SCANNERS_UNINSTALLED" >&4
            local SCANNERS_UNINSTALLED_COUNT=$(jq -cr "${YDK_ONESCAN_SPECS[count]}" <<<"$SCANNERS_UNINSTALLED") &&
                SCANNERS_UNINSTALLED_COUNT="${SCANNERS_UNINSTALLED_COUNT:-0}"
            ydk:log success "${SCANNERS_UNINSTALLED_COUNT} scanners unavailable"
            return 0
        }
        # @description Get scanner packages
        # @arg $1 install | uninstall
        # @arg $2... SCANNER_NAME Scanner name
        # @exitcode 22 If scanner not found
        # @stdout JSON Scanner packages
        # @example ydk onescan scanners packages install scanner1 scanner2
        manager() {
            local YDK_ONESCAN_MANAGER_ACTION=$1 && [ -z "$YDK_ONESCAN_MANAGER_ACTION" ] && return 22
            shift
            ydk:log info "OneScan Manager $YDK_ONESCAN_MANAGER_ACTION"
            for SCANNER_NAME in "$@"; do
                local SCANNER=$(jq -c --arg SCANNER_ID "$SCANNER_NAME" "${YDK_ONESCAN_SPECS[query]}" <<<"$(list 4>&1)")
                [ -z "$SCANNER" ] && echo "{}" >&4 && ydk:log error "Scanner ${SCANNER_NAME} not found" && return 22
                local SCANNER_ID=$(jq -r '.id' <<<"$SCANNER") && [ -z "$SCANNER_ID" ] && continue
                read -r -a SCANNER_PACKAGES <<<"$(jq -r '.packages[]' <<<"$SCANNER")" && [ -z "${SCANNER_PACKAGES[*]}" ] && continue
                local SCANNER_INSTALLED=false && command -v "$SCANNER_NAME" 2>/dev/null 1>/dev/null && SCANNER_INSTALLED=true
                ydk:log info "Scanner $SCANNER_NAME is installed: $SCANNER_INSTALLED, packages: ${SCANNER_PACKAGES[*]}"
                case "$YDK_ONESCAN_MANAGER_ACTION" in
                install)
                    if [ "$SCANNER_INSTALLED" = false ]; then
                        # ydk:upm cli "$SCANNER_NAME" 4>&1
                        ydk:upm install "$SCANNER_NAME" 4>&1
                    fi
                    ;;
                uninstall)
                    if [ "$SCANNER_INSTALLED" = true ]; then
                        ydk:upm cli 4>&1
                    fi
                    ;;
                *)
                    ydk:log error "Unsupported action $YDK_ONESCAN_MANAGER_ACTION"
                    return 22
                    ;;
                esac
            done
            return 0
        }
        # @description Install scanner
        # @arg $1... SCANNER_NAME Scanner name
        # @exitcode 1 If failed to install scanner
        # @example ydk onescan scanners install scanner1 scanner2
        install() {
            if ! manager install "$@"; then
                ydk:log error "Failed to install scanner $SCANNER_NAME"
                return 1
            fi
        }
        # @description Uninstall scanner
        # @arg $1... SCANNER_NAME Scanner name
        # @exitcode 1 If failed to uninstall scanner
        # @example ydk onescan scanners uninstall scanner1 scanner2
        uninstall() {
            if ! manager uninstall "$@"; then
                ydk:log error "Failed to uninstall scanner $SCANNER_NAME"
                return 1
            fi
        }
        ydk:try "$@" 4>&1
        return $?
    }
    __onescan:opts() {
        while [ "$#" -gt 0 ]; do
            case "$1" in
            -na | --non-await)
                YDK_ONESCAN_CONFIG["await"]=false
                ydk:log warn "Await enabled"
                ;;
            -i | auto-install)
                YDK_ONESCAN_CONFIG["auto-install"]=true
                ydk:log warn "Auto install enabled"
                ;;
            -u | auto-uninstall)
                YDK_ONESCAN_CONFIG["auto-uninstall"]=true
                ydk:log warn "Auto uninstall enabled"
                ;;
            -k | keep-output)
                YDK_ONESCAN_CONFIG["keep-output"]=true
                ydk:log warn "Keep output enabled"
                ;;
            -o=* | --output-file=*)
                YDK_ONESCAN_CONFIG["output-file"]="${1#*=}"
                ydk:log debug "Output file set to ${YDK_ONESCAN_CONFIG["output-file"]}"
                ;;
            *)
                YDK_ONESCAN_OPTS+=("$1")
                ;;
            esac
            shift
        done
        return 0
    }
    local YDK_ONESCAN_OPTS=() && __onescan:opts "$@" && set -- "${YDK_ONESCAN_OPTS[@]}" && unset YDK_ONESCAN_OPTS
    ydk:try "$@" 4>&1
    return $?
}
