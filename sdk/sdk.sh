#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
export YWT_SDK_FILE="${BASH_SOURCE[0]:-$0}" && readonly YWT_SDK_FILE
sdk() {
    set -e -o pipefail
    local YWT_FIFO="/tmp/ywt-debug" && [ ! -p "$YWT_FIFO" ] && mkfifo "$YWT_FIFO"
    export YWT_LOG_CONTEXT="ywt"
    export YWT_LOG_DEFAULT_CONTEXT="ywt" && readonly YWT_LOG_DEFAULT_CONTEXT
    trap '_fail $? "An error occurred"' EXIT ERR INT TERM
    _fail() {
        local RESULT=${1:$?} && shift
        [[ "$RESULT" -eq 0 ]] && return 0
        local MESSAGE=${1:-"An error occurred"} && shift
        cat <"$YWT_FIFO" >/dev/null

        # rm -f "$YWT_FIFO"
        local ERROR && ERROR=$(jq -n --arg result "$RESULT" --arg message "$MESSAGE" --arg caller "${FUNCNAME[*]}" --arg args "$* ($!)" '{result: $result, message: $message, caller: $caller, args: $args}')
        # logger error "$ERROR"
        kill -s EXIT $$ 2>/dev/null
        # echo "$MESSAGE" 1>&2
    }
    # local YWT_CMD_NAME && YWT_CMD_NAME=$(basename -- "$0") && YWT_CMD_NAME="${YWT_CMD_NAME%.*}" && readonly YWT_CMD_NAME
    local YWT_CMD_NAME=ywt
    local YWT_INITIALIZED=false
    local YWT_DEBUG=${YWT_CONFIG_DEBUG:-true}
    __debug() {
        [ -z "$YWT_DEBUG" ] || [ "$YWT_DEBUG" == false ] && return 0
        [ -z "$*" ] && return 0
        __is "function" "debug" && debug "${*}" && return 0
        local MESSAGE=(
            "${YELLOW}[${YWT_CMD_NAME^^}]"
            "${DARK_GRAY}[$$]"
            "${BLUE}[$(date +"%Y-%m-%d %H:%M:%S")]"
            "${CYAN}[DEBUG]"
            "${PURPLE}[${YWT_LOG_CONTEXT^^}]🐞"
            "${WHITE}${*}"
            "${DARK_GRAY}[$(etime)]"
            "${NC}"
        )
        # echo "${MESSAGE[*]}" 1>&2
        (echo "${MESSAGE[*]}" >"$YWT_FIFO") &
        true
    }
    __is() {
        case "$1" in
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
        local FUNC_LIST && FUNC_LIST=$(declare -F | awk '{print $3}')
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
        __nnf() {
            local FUNC=${1} && [ -z "$FUNC" ] && return 1
            FUNC=${FUNC#_} && FUNC=${FUNC#__} && FUNC="${FUNC//_/-5f}" && FUNC="${FUNC//-/-2d}" && FUNC="${FUNC// /_}"
            local ARGS=("${@:2}") # local ARGS=("${@}")
            if __is function "$FUNC"; then
                __debug "Running $FUNC with args: ${ARGS[*]}" 1>&2
                exec 3>&1
                trap 'exec 3>&-' EXIT
                local STATUS
                # local OUTPUT && OUTPUT=$($FUNC "${ARGS[@]}" 1>&3) # 2>&1
                $FUNC "${ARGS[@]}" 1>&3
                STATUS=$?
                [ "$STATUS" -eq 0 ] && STATUS=success || STATUS=error
                __debug "Function $FUNC status: $STATUS" # 1>&2
                exec 3>&-
                return 0
            else
                __debug "Function $FUNC not found" | logger error
                return 1
            fi
        }
        # __nnf "$@"
        # __debug "__nnf status: $?" && return 0
        # usage "$?" "ioc" "$@" && return 1
        # if __nnf "$@"; then return 0; fi
        # usage "$?" "ioc" "$@" && return 1
        case "$1" in
        resolve) __resolve "${@:2}" && return 0 ;;
        inject) __inject "${@:2}" && return 0 ;;
        nff) __nnf "${@:2}" && return $? ;;
        *) usage "$?" "ioc" "$@" && return 1 ;;
        esac
    }
    __bootstrap() {
        [ "$YWT_INITIALIZED" == true ] && return 0
        YWT_INITIALIZED=true
        __ioc inject "$(jq -r '.lib' <<<"$YWT_PATHS")"
        logger info "Initializing yellowteam sdk"
        logger debug "SDK file: $YWT_SDK_FILE"
        # ywt:info package | jq .
        ywt:info welcome
        exit 0

        # _inject_lib "$(jq -r '.lib' <<<"$YWT_PATHS")"
        # export YWT_CONFIG && YWT_CONFIG=$(
        #     jq -n \
        #         --argjson package "$YWT_APPINFO" \
        #         --argjson path "$YWT_PATHS" \
        #         --argjson process "$(process info)" \
        #         '{yellowteam: $package, path: $path, process: $process}'
        # ) && readonly YWT_CONFIG
        # _debug "$(jq . <<<"$YWT_CONFIG")"
        # # logger info "$(colors apply "yellow" "$(jq -r '.yellowteam' <<<"$YWT") https://yellowteam.cloud")"
        # export YWT_PATHS && readonly YWT_PATHS
        # welcome
    }
    etime() {
        ps -o etime= "$$" | sed -e 's/^[[:space:]]*//' | sed -e 's/\://'
    }
    paths() {
        local CMD && CMD=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd) && readonly CMD
        local SDK="${CMD}"
        local PROJECT && PROJECT=$(dirname -- "$SDK") && PROJECT=$(realpath -- "$PROJECT") && readonly PROJECT
        local WORKSPACE && WORKSPACE=$(dirname -- "$PROJECT") && WORKSPACE=$(realpath -- "$WORKSPACE") && readonly WORKSPACE
        local TMP="${YWT_CONFIG_PATH_TMP:-"$(dirname -- "$(mktemp -d -u)")"}/${YWT_CMD_NAME}"
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
    resources() {
        local TYPE=${1:-} && [ -z "$TYPE" ] && echo "Resource type not defined" && return 1
        local RESOURCE_PATH && RESOURCE_PATH=$(jq -r ".$TYPE" <<<"$YWT_PATHS")
        [ ! -d "$RESOURCE_PATH" ] && echo "Resource $TYPE not found" && return 1
        find "$RESOURCE_PATH" -mindepth 1 -maxdepth 1 -type d -printf '%P\n' | jq -R -s -c 'split("\n") | map(select(length > 0))'
    }
    # appinfo() {
    #     local YWT_PACKAGE && YWT_PACKAGE=$(jq -c <"./package.json" 2>/dev/null)
    #     echo "$YWT_PACKAGE"
    # }
    copyright() {
        echo "# YELLOW TEAM BUNDLE"
        echo "# $(jq -c .yellowteam <<<"$YWT_CONFIG")"
        echo "# This file is generated by yellowteam sdk builder. Do not edit this file"
        echo "# Build date: $(date -Iseconds)"
        echo "# Build ID: $(git rev-parse HEAD 2>/dev/null || echo "Unknown")"
        echo "# Build branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "Unknown")"
        echo "# Build tag: $(git describe --tags 2>/dev/null || echo "Unknown")"
        echo "# Build commit: $(git rev-parse --short HEAD 2>/dev/null || echo "Unknown")"
        echo "# Build author: $(git log -1 --pretty=format:'%an <%ae>' 2>/dev/null || echo "Unknown")"
        echo "# Build message: $(git log -1 --pretty=format:'%s' 2>/dev/null || echo "Unknown")"
    }
    welcome() {
        # $(jq -r '.yellowteam' <<<"$YWT")
        local NAME && NAME=$(jq -r '.name' <<<"$YWT_APPINFO") && readonly NAME
        local VERSION && VERSION=$(jq -r '.version' <<<"$YWT_APPINFO") && readonly VERSION
        colors hyperlink "https://yellowteam.cloud" "$(colors apply "yellow" "${NAME}@${VERSION} | Cloud Yellow Team | https://yellowteam.cloud")" | logger info

        # "Yellow Team"
        # ?utm_source=yellowteam&utm_medium=cli&utm_campaign=yellowteam
    }

    [ -z "$YWT_PATHS" ] && local YWT_PATHS && YWT_PATHS=$(paths) && readonly YWT_PATHS
    # [ -z "$YWT_APPINFO" ] && local YWT_APPINFO && YWT_APPINFO=$(appinfo) && readonly YWT_APPINFO
    # [ -z "$YWT_PROCESS" ] && local YWT_PROCESS && YWT_PROCESS=$(process) && readonly YWT_PROCESS

    # _nnf() {
    #     local FUNC=${1} && [ -z "$FUNC" ] && return 1
    #     FUNC=${FUNC#_} && FUNC=${FUNC#__} && FUNC="${FUNC//_/-5f}" && FUNC="${FUNC//-/-2d}" && FUNC="${FUNC// /_}"
    #     local ARGS=("${@:2}") # local ARGS=("${@}")
    #     if [ -n "$(type -t "$FUNC")" ] && [ "$(type -t "$FUNC")" = function ]; then
    #         # [[ "$FUNC" == "builder" ]] && echo "Running $FUNC with args: ${ARGS[*]}" 1>&2
    #         exec 3>&1
    #         trap 'exec 3>&-' EXIT
    #         local STATUS
    #         # $FUNC "${ARGS[@]}"
    #         local OUTPUT && OUTPUT=$($FUNC "${ARGS[@]}" 1>&3) # 2>&1
    #         STATUS=$?
    #         [ $STATUS -eq 0 ] && STATUS=success || STATUS=error
    #         #debug "Function $FUNC status: $STATUS" # 1>&2
    #         exec 3>&-
    #         echo "$OUTPUT" # && echo "$OUTPUT" 1>&2
    #         # (echo "$OUTPUT" >$YWT_FIFO) & true
    #     else
    #         # echo "Function $FUNC not found" | logger error
    #         return 1
    #     fi
    # }
    # _inject_lib() {
    #     local LIB="${1:-}" && [ ! -d "$LIB" ] && return 1
    #     [ ! -d "$LIB" ] && return 1
    #     # local LIB && LIB=$(jq -r '.lib' <<<"$YWT_PATHS") && readonly LIB && [ ! -d "$LIB" ] && return 0
    #     _debug "Injecting libraries from $LIB"
    #     while read -r FILE; do
    #         local FILE_NAME && FILE_NAME=$(basename -- "$FILE") && FILE_NAME="${FILE_NAME%.*}" && FILE_NAME=$(echo "$FILE_NAME" | tr '[:upper:]' '[:lower:]')
    #         _is_function "$FILE_NAME" && continue
    #         # shellcheck source=/dev/null # echo "source $FILE" 1>&2 &&
    #         [ -f "$FILE" ] && source "$FILE"
    #     done < <(find "$LIB" -type f -name "*.ywt.sh" | sort)
    # }
    # _resolve() {
    #     local FILE="${1:-}" && [ ! -f "$FILE" ] && return 1
    #     local FILE_NAME && FILE_NAME=$(basename -- "$FILE") && FILE_NAME="${FILE_NAME%.*}" && FILE_NAME=$(echo "$FILE_NAME" | tr '[:upper:]' '[:lower:]')
    #     _is_function "$FILE_NAME" && return 0
    #     __debug "Sourcing ${FILE_NAME} $FILE"
    #     # shellcheck source=/dev/null # echo "source $FILE" 1>&2 &&
    #     source "$FILE" && return 0
    # }
    # inject() {
    #     local LIB="${1:-}" && [ ! -d "$LIB" ] && return 1
    #     __debug "Injecting $LIB"
    #     while read -r FILE; do
    #         [[ "$FILE" = *"ioc.ywt.sh" ]] && continue
    #         _resolve "$FILE"
    #     done < <(find "$LIB" -type f -name "*.ywt.sh" | sort)
    #     return 0
    # }

    inspect() {
        jq -r '.' <<<"$YWT_CONFIG"
    }
    usage() {
        local ERROR_CODE=${1:-0} && shift
        local CONTEXT=${1:-} && [ -z "$CONTEXT" ] && CONTEXT="sdk"
        local FUNC_LIST && FUNC_LIST=$(__functions)

        [ -z "$*" ] && return 0
        # local FUNC_LIST && FUNC_LIST=$(declare -F | awk '{print $3}') && FUNC_LIST=${FUNC_LIST[*]} && FUNC_LIST=$(echo "$FUNC_LIST" | sed -e 's/ /\n/g' | grep -v '^_' | sort | tr '\n' ' ' | sed -e 's/ $//')
        # [ -z "$CONTEXT" ] && CONTEXT="sdk"
        # [ -z "$*" ] && return 0
        echo "usage error ($ERROR_CODE): ywt [$CONTEXT]($#)[$*]" | logger info
        echo "Available functions: " | logger info # (${YELLOW}${FUNC_LIST}${NC})" | logger info
        for FUNC in $FUNC_LIST; do
            [[ "$FUNC" == bats_* ]] && continue
            [[ "$FUNC" == batslib_* ]] && continue
            [[ "$FUNC" == assert_* ]] && continue
            echo "  $FUNC" # | logger info
        done
        return "$ERROR_CODE"
    }
    __bootstrap && logger debug "${YELLOW}yw-sh${NC} ${GREEN}$*${NC}"
    ioc nnf "$@" && return 0
    local STATUS=$? && usage "$STATUS" "sdk" "$@" && return 1
    # if _nnf "$@"; then
    #     return 0
    # else
    #     local STATUS=$? && usage "$STATUS" "sdk" "$@" && return 1
    # fi
    # _nnf "$@" || local STATUS=$? && usage "$STATUS" "sdk" "$@" && return 1
    # return 0
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
        exit $?
    else
        # binary injection
        # echo "Binary file ($#) $*" 1>&2
        ywt "$@"
        exit $?
    fi
fi
