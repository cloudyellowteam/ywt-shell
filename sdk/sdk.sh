#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
export YWT_SDK_FILE="${BASH_SOURCE[0]:-$0}" && readonly YWT_SDK_FILE
sdk() {
    set -e -o pipefail
    # trap '__teardown' EXIT
    # trap '__fail $? "An error occurred"' ERR INT TERM
    ___create_unit_tests() {
        while read -r FILE; do
            local FILE_REALPATH=$(realpath -- "$FILE") && [ ! -f "$FILE_REALPATH" ] && continue
            local FILE_DIR=$(dirname -- "$FILE_REALPATH")
            local FILE_NAME && FILE_NAME=$(basename -- "$FILE_REALPATH") && FILE_NAME="${FILE_NAME%.*}" && FILE_NAME=$(echo "$FILE_NAME" | tr '[:upper:]' '[:lower:]')
            local LIB_NAME="${FILE_NAME%.*}" && LIB_NAME="${LIB_NAME//-/:}" && LIB_NAME="${LIB_NAME//_/:}" && LIB_NAME="${LIB_NAME//./:}" && LIB_NAME="${LIB_NAME// /:}" && LIB_NAME="${LIB_NAME//-/:}"
            local TEST_NAME="${LIB_NAME//:/-}" && TEST_NAME="${TEST_NAME//_/-}" && TEST_NAME="${TEST_NAME// /-}"
            #$(jq -r '.tests' <<<"$YWT_PATHS")
            local TEST_FILE="$FILE_DIR/${LIB_NAME}.bats" && TEST_FILE="${TEST_FILE//:/-}" && TEST_FILE="${TEST_FILE//_/-}" && TEST_FILE="${TEST_FILE// /-}"
            local CMD_NAME="${TEST_NAME//:/-}" && CMD_NAME="${CMD_NAME//_/-}" && CMD_NAME="${CMD_NAME// /-}"
            [ -f "$TEST_FILE" ] && continue
            {
                echo "#!/usr/bin/env bats"
                echo "# bats file_tags=${TEST_NAME}"
                echo
                echo "# LIB_NAME=${LIB_NAME}"
                echo "# FILE_REALPATH=${FILE_REALPATH}"
                echo "# FILE_DIR=${FILE_DIR}"
                echo "# FILE_NAME=${FILE_NAME}"
                echo "# TEST_FILE=${TEST_FILE}"
                echo "# TEST_NAME=${TEST_NAME}"
                echo "# CMD_NAME=${CMD_NAME}"
                echo "# bats test_tags=${TEST_NAME}, usage"
                echo "@test \"ywt ${TEST_NAME} should be called\" {"
                echo "  run ywt ${CMD_NAME}"
                echo "  test_report"
                echo "  assert_success \"${LIB_NAME} should be called\""
                echo "  assert_output --partial \"Available functions\""
                echo "  assert_output --partial \"YWT Usage\""
                echo "}"
            } >"$TEST_FILE"
            echo "Created $TEST_FILE" | logger info
        done < <(find "$(jq -r '.lib' <<<"$YWT_PATHS")" -type f -name "*.ywt.sh" | sort)
        return 0
    }
    __rename_bats_tests() {
        while read -r FILE; do
            local DEST="${FILE%.*}.bat"
            mv -f "$FILE" "$DEST"
            echo "Moved $FILE, to ${DEST}" | logger info
        done < <(find "$(jq -r '.lib' <<<"$YWT_PATHS")" -type f -name "*.bats" | sort)
    }
    __teardown() {
        __debug "__teardown"
        [ -p "$YWT_DEBUG_FIFO" ] && rm -f "$YWT_DEBUG_FIFO" 2>/dev/null
        [ -p "$YWT_LOGGER_FIFO" ] && rm -f "$YWT_LOGGER_FIFO" 2>/dev/null
        [ -p "$YWT_TRACE_FIFO" ] && rm -f "$YWT_TRACE_FIFO" 2>/dev/null
        [ -p "$YWT_OUTPUT_FIFO" ] && rm -f "$YWT_OUTPUT_FIFO" 2>/dev/null
        # [ -p "$YWT_FIFO" ] && rm -f "$YWT_FIFO" 2>/dev/null
    }
    __fail() {
        __log "__fail"
        local RESULT=${1:$?} && shift
        [[ "$RESULT" -eq 0 ]] && return 0
        local MESSAGE=${1:-"An error occurred"} && shift
        local ERROR && ERROR=$(jq -n --arg result "$RESULT" --arg message "$MESSAGE" --arg caller "${FUNCNAME[*]}" --arg args "$* ($!)" '{result: $result, message: $message, caller: $caller, args: $args}')
        __log error "$ERROR"
        __teardown
        kill -s EXIT $$ 2>/dev/null
        # echo "$MESSAGE" 1>&2
    }
    export YWT_LOG_DEFAULT_CONTEXT="ywt" && readonly YWT_LOG_DEFAULT_CONTEXT
    export YWT_LOG_CONTEXT="$YWT_LOG_DEFAULT_CONTEXT"
    local YWT_CMD_NAME="$YWT_LOG_DEFAULT_CONTEXT" && readonly YWT_CMD_NAME
    local YWT_INITIALIZED=false
    local YWT_DEBUG=${YWT_CONFIG_DEBUG:-false}
    local YWT_MISSING_DEPENDENCIES=()
    local YWT_LOGS=()
    local YWT_POSITIONAL=()
    __etime() {
        if grep -q 'Alpine' /etc/os-release; then
            ps -o etime= "$$" | awk -F "[:]" '{ print ($1 * 60) + $2 }' | head -n 1
        else
            ps -o etime= -p "$$" | sed -e 's/^[[:space:]]*//' | sed -e 's/\://' | head -n 1
        fi
    }
    __debug() {
        [ -z "$YWT_DEBUG" ] || [ "$YWT_DEBUG" == false ] && return 0
        [ -z "$*" ] && return 0
        [ ! -p "$YWT_DEBUG_FIFO" ] && return 0
        __is "function" "debug" && debug "${*}" && return 0
        local MESSAGE=(
            "${YELLOW}[${YWT_CMD_NAME^^}]"
            "${DARK_GRAY}[$$]"
            "${BLUE}[$(date +"%Y-%m-%d %H:%M:%S")]"
            "${CYAN}[DEBUG]"
            "${PURPLE}[${YWT_LOG_CONTEXT^^}]🐞"
            "${WHITE}${*}"
            "${DARK_GRAY}[$(__etime)]"
            "${NC}"
        )
        # echo "${MESSAGE[*]}" 1>&2
        (echo "${MESSAGE[*]}" >"$YWT_DEBUG_FIFO") &
        true
    }
    __require() {
        local DEPENDENCIES=("$@")
        for DEPENDENCY in "${DEPENDENCIES[@]}"; do
            if ! __is command "${DEPENDENCY}"; then
                __debug "required ${DEPENDENCY} (command not found)" &&
                    YWT_MISSING_DEPENDENCIES+=("${DEPENDENCY}")
                # return 1
            fi
        done
        [ "${#YWT_MISSING_DEPENDENCIES[@]}" -eq 0 ] && return 0
        local MSG="Missing dependencies: ${YWT_MISSING_DEPENDENCIES[*]}"
        __is "function" "logger" && logger error "$MSG" && exit 255
        __debug "$MSG" && __verbose "$MSG"
        exit 255
    }
    __verbose() {
        echo "$1" 1>&2
    }
    __stdin() {
        [ ! -p /dev/stdin ] && [ ! -t 0 ] && return "$1"
        while IFS= read -r INPUT; do
            echo "$INPUT"
        done
        unset INPUT
    }
    __log() {
        __is "function" "logger" && logger "$@" && return $?
        __debug "$@" && return $?
    }
    __is() {
        case "$1" in
        not-defined)
            [ -z "$2" ] && return 0
            [ "$2" == "null" ] && return 0
            ;;
        defined)
            [ -n "$2" ] && return 0
            [ "$2" != "null" ] && return 0
            ;;
        rw)
            [ -r "$2" ] && [ -w "$2" ] && return 0
            ;;
        owner)
            [ -O "$2" ] && return 0
            ;;
        writable)
            [ -w "$2" ] && return 0
            ;;
        readable)
            [ -r "$2" ] && return 0
            ;;
        executable)
            [ -x "$2" ] && return 0
            ;;
        nil)
            [ -z "$2" ] && return 0
            [ "$2" == "null" ] && return 0
            ;;
        number)
            [ -n "$2" ] && [[ "$2" =~ ^[0-9]+$ ]] && return 0
            ;;
        string)
            [ -n "$2" ] && [[ "$2" =~ ^[a-zA-Z0-9_]+$ ]] && return 0
            ;;
        boolean)
            [ -n "$2" ] && [[ "$2" =~ ^(true|false)$ ]] && return 0
            ;;
        date)
            [ -n "$2" ] && [[ "$2" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && return 0
            ;;
        url)
            [ -n "$2" ] && [[ "$2" =~ ^https?:// ]] && return 0
            ;;
        json)
            jq -e . <<<"$2" >/dev/null 2>&1 && return 0
            ;;
        fnc | function)
            local TYPE="$(type -t "$2")"
            [ -n "$TYPE" ] && [ "$TYPE" = function ] && return 0
            ;;
        cmd | command)
            command -v "$2" >/dev/null 2>&1 && return 0
            ;;
        f | file)
            [ -f "$2" ] && return 0
            ;;
        d | dir)
            [ -d "$2" ] && return 0
            ;;
        esac
        return 1
    }
    __functions() {
        if [ -f "${1}" ]; then
            local FUNC_LIST=$(
                grep -E '^\s*(function\s+)?[a-zA-Z_][a-zA-Z0-9_]*\s*\(\)' "${1}" | awk '{print $1}' | sort | tr '\n' ' ' | sed -e 's/()//g' -e 's/ $//'
            )
            [ "$2" == true ] && FUNC_LIST+=" $(declare -F | awk '{print $3}')"
            FUNC_LIST=$(echo "${FUNC_LIST}" | tr ' ' '\n' | sort | uniq | tr '\n' ' ' | sed -e 's/ $//')
        else
            local FUNC_LIST=$(declare -F | awk '{print $3}')
        fi
        local RESULT=()
        for FUNC in $FUNC_LIST; do
            [[ "$FUNC" == _* ]] && continue
            [[ "$FUNC" == bats_* ]] && continue
            [[ "$FUNC" == batslib_* ]] && continue
            [[ "$FUNC" == assert_* ]] && continue
            RESULT+=("$FUNC")
        done
        echo "${RESULT[*]}" | sed -e 's/ /\n/g' | grep -v '^_' | sort | tr '\n' ' ' | sed -e 's/ $//' | sed -e 's/ /, /g'
    }
    __libraries() {
        # list files in CONTEXT_PATH and find the first file that matches the CONTEXT
        [ ! -d "${1}" ] && echo "{}" && return 0
        local JSON="{" && local FIRST=true
        while read -r FILE; do
            local FILE_NAME && FILE_NAME=$(basename -- "$FILE") && FILE_NAME="${FILE_NAME%.*}" && FILE_NAME=$(echo "$FILE_NAME" | tr '[:upper:]' '[:lower:]')
            local LIB_NAME="${FILE_NAME%.*}" && LIB_NAME="${LIB_NAME//-/:}" && LIB_NAME="${LIB_NAME//_/:}" && LIB_NAME="${LIB_NAME//./:}" && LIB_NAME="${LIB_NAME// /:}" && LIB_NAME="${LIB_NAME//-/:}"
            [ "$FIRST" == true ] && FIRST=false || JSON+=","
            JSON+="\"$LIB_NAME\": {\"entrypoint\": \"${LIB_NAME}\", \"name\":\"${FILE_NAME}\",\"src\":\"${FILE}\",\"methods\":["
            local METHODS=$(__functions "$FILE" false) && [ -z "$METHODS" ] && METHODS=""
            IFS=',' read -r -d '' -a METHODS <<<"$METHODS"
            for FUNC in "${METHODS[@]}"; do
                # trim and replace new lines
                FUNC=$(echo "$FUNC" | tr -d '\n' | tr -d '\r' | tr -d '\t' | tr -d ' ') && FUNC="${FUNC//\{/}"
                [[ "$FUNC" == _* ]] && continue
                [[ "$FUNC" == bats_* ]] && continue
                [[ "$FUNC" == batslib_* ]] && continue
                [[ "$FUNC" == assert_* ]] && continue
                JSON+="\"$FUNC\","
            done
            JSON+="\"usage\"]}"
        done < <(find "${1}" -type f -name "*.ywt.sh" | sort)
        JSON+="}"
        echo "$JSON" | jq -C .
    }
    __ioc() {
        __resolve() {
            local FILE="${1:-}" && [ ! -f "$FILE" ] && return 1
            local FILE_NAME && FILE_NAME=$(basename -- "$FILE") && FILE_NAME="${FILE_NAME%.*}" && FILE_NAME=$(echo "$FILE_NAME" | tr '[:upper:]' '[:lower:]')
            __is function "$FILE_NAME" && return 0
            __debug "Sourcing ${FILE_NAME} $FILE"
            # shellcheck source=/dev/null # echo "source $FILE" 1>&2 &&
            source "$FILE" && return 0
        }
        __inject() {
            local LIB="${1:-}" && [ ! -d "$LIB" ] && return 1
            __debug "Injecting $LIB"
            while read -r FILE; do
                [[ "$FILE" = *"ioc.ywt.sh" ]] && continue
                __resolve "$FILE"
            done < <(find "$LIB" -type f -name "*.ywt.sh" | sort)
            return 0
        }
        __lib() {
            local TARGET="${1:-"$(jq -r '.lib' <<<"$YWT_PATHS")"}" && [ ! -d "$TARGET" ] && return 0
            __inject "$TARGET"
        }
        __extension() {
            local TARGET="${1:-"$(jq -r '.extensions' <<<"$YWT_PATHS")"}" && [ ! -d "$TARGET" ] && return 0
            __inject "$TARGET"
        }
        __nnf() {
            local FUNC=${1} && [ -z "$FUNC" ] && return 1
            FUNC=${FUNC#_} && FUNC=${FUNC#__} && FUNC="${FUNC//_/-5f}" && FUNC="${FUNC//-/-2d}" && FUNC="${FUNC// /_}"
            local ARGS=("${@:2}") # local ARGS=("${@}")
            if __is function "$FUNC"; then
                # __debug "Running $FUNC with args: ${ARGS[*]}" 1>&2
                local START_TIME=$(date +%s)
                exec 3>&1
                trap 'exec 3>&-' EXIT
                local STATUS
                # local OUTPUT && OUTPUT=$($FUNC "${ARGS[@]}" 1>&3) # 2>&1
                # $FUNC "${ARGS[@]}" 1>&3

                if [[ "$FUNC" != *logger* ]] && [ -p "$YWT_OUTPUT_FIFO" ]; then
                    $FUNC "${ARGS[@]}" 1>&3
                    # ($FUNC "${ARGS[@]}" 1>&3 >"$YWT_OUTPUT_FIFO") & true
                    # (exec 3>"$YWT_OUTPUT_FIFO" && $FUNC "${ARGS[@]}" 1>&3)
                else
                    $FUNC "${ARGS[@]}" 1>&3
                fi
                # local OUTPUT && OUTPUT=$(tail -n 1 <<< "$(<&3)")
                # [ -n "$OUTPUT" ] && __output "$OUTPUT"
                local END_TIME=$(date +%s)
                local ELAPSED_TIME=$((END_TIME - START_TIME))
                STATUS=$?
                [ "$STATUS" -eq 0 ] && STATUS=success || STATUS=error
                __debug "Function $FUNC status: $STATUS, in ${ELAPSED_TIME} seconds" # 1>&2
                exec 3>&-
                return 0
            else
                __log error "Function $FUNC not found"
                return 1
            fi
        }
        case "$1" in
        resolve) __resolve "${@:2}" && return 0 ;;
        inject) __inject "${@:2}" && return 0 ;;
        lib) __lib "${@:2}" && return 0 ;;
        extension) __extension "${@:2}" && return 0 ;;
        nff) __nnf "${@:2}" && return $? ;;
        *) usage "$?" "ioc" "$@" && return 1 ;;
        esac
    }
    __paths() {
        [ -n "$YWT_PATHS" ] && echo "$YWT_PATHS" | jq -c . && return 0
        local CMD && CMD=$(cd "$(dirname "${YWT_SDK_FILE}")" && pwd) && readonly CMD
        local SDK="${CMD}"
        local PROJECT && PROJECT=$(dirname -- "$SDK") && PROJECT=$(realpath -- "$PROJECT") && readonly PROJECT
        local WORKSPACE && WORKSPACE=$(dirname -- "$PROJECT") && WORKSPACE=$(realpath -- "$WORKSPACE") && readonly WORKSPACE
        local TMP="${YWT_CONFIG_PATH_TMP:-"$(dirname -- "$(mktemp -d -u)")"}/${YWT_CMD_NAME}"
        export YWT_PATHS=$(
            {
                echo -n "{"
                echo -n "\"cmd\":\"$CMD\","
                echo -n "\"workspace\":\"$WORKSPACE\","
                echo -n "\"project\":\"$PROJECT\","
                echo -n "\"sdk\":\"$SDK\"",
                echo -n "\"lib\":\"$SDK/lib\"",
                echo -n "\"src\":\"$PROJECT/src\"",
                echo -n "\"extensions\":\"$PROJECT/extensions\"",
                echo -n "\"packages\":\"$PROJECT/packages\"",
                echo -n "\"scripts\":\"$PROJECT/scripts\"",
                echo -n "\"tools\":\"$PROJECT/tools\"",
                echo -n "\"cli\":\"$PROJECT/cli\"",
                echo -n "\"apps\":\"$PROJECT/apps\"",
                echo -n "\"tests\":\"$PROJECT/tests\"",
                echo -n "\"bin\":\"$PROJECT/bin\"",
                echo -n "\"dist\":\"$PROJECT/dist\"",
                echo -n "\"tmp\":\"$TMP\"",
                echo -n "\"logs\":\"${YWT_CONFIG_PATH_LOGS:-"/var/log/$YWT_CMD_NAME"}\"",
                echo -n "\"cache\":\"${YWT_CONFIG_PATH_CACHE:-"/var/cache/${YWT_CMD_NAME}"}\"",
                echo -n "\"data\":\"${YWT_CONFIG_PATH_DATA:-"/var/lib/$YWT_CMD_NAME"}\"",
                echo -n "\"etc\":\"${YWT_CONFIG_PATH_ETC:-"/etc/$YWT_CMD_NAME"}\"",
                echo -n "\"pwd\":\"${YWT_CONFIG_PATH_CWD:-"${PWD}"}\""
                echo -n "}"
                echo ""
            }
        ) && readonly YWT_PATHS
        echo "$YWT_PATHS" | jq -c . #| sed -e 's/\\//g'
    }
    __argv() {
        [ -n "$YWT_FLAGS" ] && echo "$YWT_FLAGS" | jq -c . && return 0
        # __argv "$@" && set -- "${YWT_POSITIONAL[@]}"
        # flag declarations
        # -f -f1=value -f2:value --flag --flag1=value --flag2:value returns {"flag":true,"flag1":"value","flag2":"value"}
        # -d -d=true -d:/tmp/ywt-debug --debug --debug=true --debug:/tmp/ywt-debug returns {"debug":"/tmp/ywt-debug"}
        YWT_POSITIONAL=()
        export YWT_FLAGS=$(
            {
                local JSON="{" && local FIRST=true
                while [[ $# -gt 0 ]]; do
                    local FLAG="$1"
                    [[ "$FLAG" != --* ]] && [[ "$FLAG" != -* ]] && YWT_POSITIONAL+=("$1") && shift && continue
                    local KEY=${FLAG#--} && KEY=${KEY#-} && KEY=${KEY%%=*} && KEY=${KEY%%:*}
                    local VALUE=${FLAG#*=} && VALUE=${VALUE#*:} && VALUE=${VALUE#*=} && VALUE=${VALUE#--} && VALUE=${VALUE#-}
                    [ "$KEY" == "$VALUE" ] && VALUE=true
                    [ -z "$VALUE" ] && VALUE=true
                    [ "$FIRST" == true ] && FIRST=false || JSON+=","
                    JSON+="\"$KEY\":\"$VALUE\"" && shift
                done
                JSON+="}"
                echo "$JSON"
            }
        ) # && readonly YWT_FLAGS
        echo "$YWT_FLAGS" | jq -c .
    }
    __params() {
        [ -n "$YWT_PARAMS" ] && echo "$YWT_PARAMS" | jq -c . && return 0
        YWT_POSITIONAL=()
        export YWT_PARAMS=$({
            local JSON="{" && local FIRST=true
            while [[ $# -gt 0 ]]; do
                # params are kv=key:value
                local PARAM="$1"
                [[ "$PARAM" != kv=* ]] && YWT_POSITIONAL+=("$1") && shift && continue
                local KEY=${PARAM#kv=} #&& KEY=${KEY#p=} # && KEY=${KEY#param} && KEY=${KEY#p}
                local VALUE=${KEY#*:} && VALUE=${VALUE#*:} && VALUE=${VALUE#=}
                KEY=${KEY%%:*}
                [ "$KEY" == "$VALUE" ] && VALUE=true
                [ -z "$VALUE" ] && VALUE=true
                [ "$FIRST" == true ] && FIRST=false || JSON+=","
                JSON+="\"$KEY\":\"$VALUE\"" && shift
            done
            JSON+="}"
            echo "$JSON"
        }) && readonly YWT_PARAMS
        echo "$YWT_PARAMS" | jq -c .
    }
    __flags() {
        # __argv "$@" && set -- "${YWT_POSITIONAL[@]}"
        # local FLAGS=$(__argv "$@") #&& set -- "${YWT_POSITIONAL[@]}"
        # echo "$FLAGS" | jq -r '.'
        YWT_POSITIONAL=()
        while [[ $# -gt 0 ]]; do
            case "$1" in
            -q | --quiet)
                export YWT_QUIET=true && readonly YWT_QUIET
                shift
                ;;
            -t | --trace)
                local VALUE=$(jq -r '.trace' <<<"$YWT_FLAGS")
                [ "$VALUE" == "null" ] && shift && continue
                [ "$VALUE" == true ] && VALUE="/tmp/ywt.trace"
                [ -p "$VALUE" ] && rm -f "$VALUE"
                export YWT_TRACE_FIFO="$VALUE"
                [ ! -p "$YWT_TRACE_FIFO" ] && mkfifo "$YWT_TRACE_FIFO" && readonly YWT_TRACE_FIFO
                YWT_LOGS+=("Trace FIFO enabled. In another terminal use 'tail -f $YWT_TRACE_FIFO' to watch logs or 'rapd debugger trace watch $YWT_TRACE_FIFO'.")
                YWT_FLAGS=$(jq -n --argjson flags "$YWT_FLAGS" --arg trace "$VALUE" '$flags | .trace=$trace')
                # exec 4>"$YWT_TRACE_FIFO"
                # set -x >&4
                shift
                ;;
            -l | --logger)
                local VALUE=$(jq -r '.logger' <<<"$YWT_FLAGS")
                [ "$VALUE" == "null" ] && shift && continue
                [ "$VALUE" == true ] && VALUE="/tmp/ywt.logger"
                [ -p "$YWT_LOGGER_FIFO" ] && rm -f "$YWT_LOGGER_FIFO"
                export YWT_LOGGER_FIFO="$VALUE"
                [ ! -p "$YWT_LOGGER_FIFO" ] && mkfifo "$YWT_LOGGER_FIFO" && readonly YWT_LOGGER_FIFO
                YWT_LOGS+=("Logger FIFO enabled. In another terminal use 'tail -f $YWT_LOGGER_FIFO' to watch logs or 'rapd logger watch $YWT_LOGGER_FIFO'.")
                YWT_FLAGS=$(jq -n --argjson flags "$YWT_FLAGS" --arg logger "$VALUE" '$flags | .logger=$logger')
                shift
                ;;
            -d | --debug)
                [ "$YWT_DEBUG" == true ] && shift && continue
                YWT_DEBUG=true && readonly YWT_DEBUG
                local VALUE=$(jq -r '.debug' <<<"$YWT_FLAGS")
                [ "$VALUE" == "null" ] && shift && continue
                [ "$VALUE" == true ] && VALUE="/tmp/ywt.debugger"
                [ -p "$YWT_DEBUG_FIFO" ] && rm -f "$YWT_DEBUG_FIFO"
                export YWT_DEBUG_FIFO="$VALUE"
                [ ! -p "$YWT_DEBUG_FIFO" ] && mkfifo "$YWT_DEBUG_FIFO" && readonly YWT_DEBUG_FIFO
                YWT_LOGS+=("Debug enabled. In another terminal use 'tail -f $YWT_DEBUG_FIFO' to watch logs or 'rapd debugger watch $YWT_DEBUG_FIFO'.")
                YWT_FLAGS=$(jq -n --argjson flags "$YWT_FLAGS" --arg debug "$VALUE" '$flags | .debug=$debug')
                shift
                ;;
            -o | --output)
                local VALUE=$(jq -r '.output' <<<"$YWT_FLAGS")
                [ "$VALUE" == "null" ] && shift && continue
                [ "$VALUE" == true ] && VALUE="/tmp/ywt.output"
                [ -p "$VALUE" ] && rm -f "$VALUE"
                export YWT_OUTPUT_FIFO="$VALUE"
                [ ! -p "$YWT_OUTPUT_FIFO" ] && mkfifo "$YWT_OUTPUT_FIFO" && readonly YWT_OUTPUT_FIFO
                YWT_LOGS+=("Output FIFO enabled. In another terminal use 'tail -f $YWT_OUTPUT_FIFO' to watch logs or 'rapd output watch $YWT_OUTPUT_FIFO'.")
                YWT_FLAGS=$(jq -n --argjson flags "$YWT_FLAGS" --arg output "$VALUE" '$flags | .output=$output')
                shift
                ;;
            -p* | --param*)
                # params already parsed using __params
                shift
                ;;
            *)
                YWT_POSITIONAL+=("$1")
                shift
                ;;
            esac
        done
        readonly YWT_FLAGS
        return 0
    }
    __bootstrap() {
        [ "$YWT_INITIALIZED" == true ] && return 0
        YWT_INITIALIZED=true && readonly YWT_INITIALIZED
        __require jq sed grep sort tr
        __ioc lib "$(jq -r '.lib' <<<"$YWT_PATHS")"
        __ioc extension "$(jq -r '.extensions' <<<"$YWT_PATHS")"
        [ -z "$YWT_APPINFO" ] && local YWT_APPINFO && YWT_APPINFO=$(ywt:info package) && readonly YWT_APPINFO
        [ -z "$YWT_PROCESS" ] && local YWT_PROCESS && YWT_PROCESS=$(process info) && readonly YWT_PROCESS
        local DOTENV_FILE=$(jq -r '.project' <<<"$YWT_PATHS")/.env
        [ -f "$DOTENV_FILE" ] && export YWT_DOTENV && YWT_DOTENV=$(dotenv load "$DOTENV_FILE") && readonly YWT_DOTENV
        [ -z "$YWT_DOTENV" ] && local YWT_DOTENV && YWT_DOTENV="{}" && readonly YWT_DOTENV
        export YWT_CONFIG && YWT_CONFIG=$(
            jq -n \
                --argjson package "$YWT_APPINFO" \
                --argjson path "$YWT_PATHS" \
                --argjson process "$YWT_PROCESS" \
                --argjson env "$YWT_DOTENV" \
                --argjson flags "$YWT_FLAGS" \
                --argjson params "$YWT_PARAMS" \
                '{yellowteam: $package, path: $path, process: $process, env: $env, flags: $flags, params: $params}'
        ) && readonly YWT_CONFIG
        __debug "Package Info $(jq -C .yellowteam <<<"$YWT_CONFIG")"
        __debug "Paths $(jq -C .path <<<"$YWT_CONFIG")"
        __debug "Process $(jq -C .process <<<"$YWT_CONFIG")"
        __debug "Dotenv $(jq -C .env <<<"$YWT_CONFIG")"
        __debug "Flags $(jq -C .flags <<<"$YWT_CONFIG")"
        __debug "Params $(jq -C .params <<<"$YWT_CONFIG")"
        ywt:info welcome
        for LOG in "${YWT_LOGS[@]}"; do logger info "$LOG"; done
        # ___create_unit_tests && logger info "Unit tests created" && exit 244
        # __rename_bats_tests && logger info "Unit tests created" && exit 244
        return 0
    }
    inspect() {
        logger info "inspect $#"
        jq -r '.' <<<"$YWT_CONFIG"
        YWT_LOG_CONTEXT="inspect"
        local PARAMS=$({
            param kv -r -n key -- \
                --required --name key2 -- \
                --default value --required --name key3 -- \
                --default value --required --name key4 -- \
                --type number --default "fd1" --required --name key5 -- \
                --message "custom message" --type number --default 1 --required --name key6 -- \
                --required --name flag-value -- \
                --required --name flag -- \
                --default '{}' --type json --required --name jsons -- \
                --default "{}" --type json --required --name jsons2
        })
        if ! param validate "$PARAMS"; then return 1; fi
        echo "$PARAMS" | jq -C .
    }
    usage() {
        local ERROR_CODE=${1:-0} && shift
        local CONTEXT=${1:-} && [ -z "$CONTEXT" ] && CONTEXT=""
        local CONTEXT_PATH=$(jq -r ".lib" <<<"$YWT_PATHS")
        local CONTEX_FILE=$(find "$CONTEXT_PATH" -type f -name "${CONTEXT}.ywt.sh" | head -n 1) && [ ! -f "$CONTEX_FILE" ] && CONTEX_FILE="${YWT_SDK_FILE}"

        # local LIBS=$(__libraries "$CONTEXT_PATH")
        # __libraries "$CONTEXT_PATH"
        # if [ -d "$CONTEXT_PATH" ]; then
        #     while read -r FILE; do
        #         local FILE_NAME && FILE_NAME=$(basename -- "$FILE") && FILE_NAME="${FILE_NAME%.*}" && FILE_NAME=$(echo "$FILE_NAME" | tr '[:upper:]' '[:lower:]')
        #         local LIB_NAME="${FILE_NAME%.*}" && LIB_NAME="${LIB_NAME//-/:}" && LIB_NAME="${LIB_NAME//_/:}" && LIB_NAME="${LIB_NAME//./:}" && LIB_NAME="${LIB_NAME// /:}" && LIB_NAME="${LIB_NAME//-/:}"
        #         [ -z "$CONTEXT" ] && __log info "Available libraries: ${LIB_NAME}" #| logger info
        #     done < <(find "$CONTEXT_PATH" -type f -name "*.ywt.sh" | sort)
        # fi
        local FUNC_LIST="" # && FUNC_LIST=$(__functions "$CONTEX_FILE" true)
        [ -z "$*" ] && return 0
        local ARGS=("${@:2}")
        [ -n "${ARGS[0]}" ] && ARGS[0]="${RED}${UNDERLINE}${ARGS[0]}${NC}${NSTL}"
        __log info "(${RED}$ERROR_CODE${NC}) ${YELLOW}YWT Usage${NC}: ${YELLOW}ywt ${GREEN}$CONTEXT${NC} (${ARGS[*]}${NC}) ${CYAN}${#ARGS[@]} length${NC}"
        __log info "Available functions: " #| logger info # (${YELLOW}${FUNC_LIST}${NC})" | logger info
        for FUNC in $FUNC_LIST; do
            [[ "$FUNC" == bats_* ]] && continue
            [[ "$FUNC" == batslib_* ]] && continue
            [[ "$FUNC" == assert_* ]] && continue
            [[ "$FUNC" == "$CONTEXT" ]] && continue
            [[ "$FUNC" == "ywt" ]] && continue
            [[ "$FUNC" == *"sdk"* ]] && continue
            FUNC=${FUNC%,}
            __log info "${YELLOW}ywt ${GREEN}${CONTEXT} ${BLUE}$FUNC${NC}"
        done
        return 1
    }
    [ -z "$YWT_PATHS" ] && __paths >/dev/null
    [ -z "$YWT_FLAGS" ] && __argv "$@" >/dev/null
    [ -z "$YWT_PARAMS" ] && __params "$@" >/dev/null
    __flags "$@" && set -- "${YWT_POSITIONAL[@]}" && __bootstrap && logger debug "${YELLOW}yw-sh${NC} ${GREEN}$*${NC}"
    [ "${1}" == "usage" ] && usage "0" "" "$@" && return 0
    __nnf "$@" && return 0
    local STATUS=$? && usage "$STATUS" "" "$@" && return 1
}
ywt() {
    [ "$#" -eq 0 ] && return 0
    local FUNC=${1} && [ -z "$FUNC" ] && return 1
    FUNC=${FUNC#_} && FUNC=${FUNC#__}
    local ARGS=("${@:2}")
    sdk "$FUNC" "${ARGS[@]}"
    return 0
}
(
    export -f ywt
)

if [ "$#" -gt 0 ]; then
    SDK_FILE="$(realpath -- "${YWT_SDK_FILE}")" && export SDK_FILE
    if ! LC_ALL=C grep -a '[^[:print:][:space:]]' "$SDK_FILE" >/dev/null; then
        ywt "$@"
        # __teardown
        exit $?
    else
        # binary injection
        # echo "Binary file ($#) $*" 1>&2
        ywt "$@"
        # __teardown
        exit $?
    fi
fi
