#!/usr/bin/env bash

sdk() {
    set -e -o pipefail
    local RAPD_FIFO="/tmp/ywt.$$.fifo" && [ ! -p "$RAPD_FIFO" ] && mkfifo "$RAPD_FIFO"
    trap 'rm -f $RAPD_FIFO' EXIT
    # local RAPD_CMD_NAME && RAPD_CMD_NAME=$(basename -- "$0") && RAPD_CMD_NAME="${RAPD_CMD_NAME%.*}" && readonly RAPD_CMD_NAME
    local RAPD_CMD_NAME=ywt
    local RAPD_INITIALIZED=false
    local RAPD_DEBUG=${RAPD_CONFIG_DEBUG:-false}
    debug() {
        [ -z "$RAPD_DEBUG" ] || [ "$RAPD_DEBUG" == false ] && return 0
        [ -z "$*" ] && return 1
        (echo "DEBUG: $*" 1>&2 >$RAPD_FIFO) &
        # # if logger is function
        # [ -z "$RAPD_DEBUG" ] && return 0
        # [ -z "$*" ] && return 1
        # [ -z "$RAPD_DEBUB" ] && declare -a RAPD_DEBUB=()
    }
    etime() {
        ps -o etime= "$$" | sed -e 's/^[[:space:]]*//' | sed -e 's/\://'
    }
    paths() {
        local CMD && CMD=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd) && readonly CMD
        local SDK="${CMD}"
        local PROJECT && PROJECT=$(dirname -- "$SDK") && PROJECT=$(realpath -- "$PROJECT") && readonly PROJECT
        local WORKSPACE && WORKSPACE=$(dirname -- "$PROJECT") && WORKSPACE=$(realpath -- "$WORKSPACE") && readonly WORKSPACE
        local TMP="${RAPD_CONFIG_PATH_TMP:-"$(dirname -- "$(mktemp -d -u)")"}/${RAPD_CMD_NAME}"
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
        echo -n "\"logs\":\"${RAPD_CONFIG_PATH_LOGS:-"/var/log/$RAPD_CMD_NAME"}\"",
        echo -n "\"cache\":\"${RAPD_CONFIG_PATH_CACHE:-"/var/cache/${RAPD_CMD_NAME}"}\"",
        echo -n "\"data\":\"${RAPD_CONFIG_PATH_DATA:-"/var/lib/$RAPD_CMD_NAME"}\"",
        echo -n "\"etc\":\"${RAPD_CONFIG_PATH_ETC:-"/etc/$RAPD_CMD_NAME"}\"",
        echo -n "\"pwd\":\"${RAPD_CONFIG_PATH_CWD:-"${PWD}"}\""
        echo -n "}"
        echo ""
    }
    resources() {
        local TYPE=${1:-} && [ -z "$TYPE" ] && echo "Resource type not defined" && return 1
        local RESOURCE_PATH && RESOURCE_PATH=$(jq -r ".$TYPE" <<<"$RAPD_PATHS")
        [ ! -d "$RESOURCE_PATH" ] && echo "Resource $TYPE not found" && return 1
        find "$RESOURCE_PATH" -mindepth 1 -maxdepth 1 -type d -printf '%P\n' | jq -R -s -c 'split("\n") | map(select(length > 0))'
    }
    appinfo() {
        local RAPD_PACKAGE && RAPD_PACKAGE=$(jq -c <"./package.json" 2>/dev/null)
        echo "$RAPD_PACKAGE"
    }
    banner() {
        echo "banner"
    }
    is_function() {
        local FUNC=${1:-} && [ -n "$(type -t "$FUNC")" ] && [ "$(type -t "$FUNC")" = function ]
    }
    [ -z "$RAPD_PATHS" ] && local RAPD_PATHS && RAPD_PATHS=$(paths) && readonly RAPD_PATHS
    [ -z "$RAPD_APPINFO" ] && local RAPD_APPINFO && RAPD_APPINFO=$(appinfo) && readonly RAPD_APPINFO
    # [ -z "$RAPD_PROCESS" ] && local RAPD_PROCESS && RAPD_PROCESS=$(process) && readonly RAPD_PROCESS
    bootstrap() {
        [ "$RAPD_INITIALIZED" == true ] && return 0
        RAPD_INITIALIZED=true
        # --argjson process "$RAPD_PROCESS" \
        export RAPD && RAPD=$(
            jq -n \
                --argjson package "$RAPD_APPINFO" \
                --argjson path "$RAPD_PATHS" \
                '{yellowteam: $package, path: $path}'
        ) && readonly RAPD
        debug "$(jq . <<<"$RAPD")"
        # return array of resources
        # resources packages
        # resources tools
        # resources scripts
        # resources extensions
        inject
        logger info "$(colors colorize "yellow" "$(jq -r '.yellowteam' <<<"$RAPD") https://yellowteam.cloud")"
        export RAPD_PATHS && readonly RAPD_PATHS
        debug "YW initialized"
        echo
    }
    inject() {
        local LIB && LIB=$(jq -r '.lib' <<<"$RAPD_PATHS") && readonly LIB
        debug "Injecting libraries from $LIB"
        while read -r FILE; do
            local FILE_NAME && FILE_NAME=$(basename -- "$FILE") && FILE_NAME="${FILE_NAME%.*}" && FILE_NAME=$(echo "$FILE_NAME" | tr '[:upper:]' '[:lower:]')
            is_function "$FILE_NAME" && continue
            # shellcheck source=/dev/null # echo "source $FILE" 1>&2 &&
            [ -f "$FILE" ] && source "$FILE"
        done < <(find "$LIB" -type f -name "*.ywt.sh" | sort)
    }
    verbose() {
        echo "$1" 1>&2
    }
    nnf() {
        local FUNC=${1} #&& shift
        [ -z "$FUNC" ] && return 1
        local ARGS=("${@:2}") # local ARGS=("${@}")
        if [ -n "$(type -t "$FUNC")" ] && [ "$(type -t "$FUNC")" = function ]; then
            # echo "Running $FUNC with args: ${ARGS[*]}" 1>&2
            exec 3>&1
            local STATUS
            # $FUNC "${ARGS[@]}"
            local OUTPUT && OUTPUT=$($FUNC "${ARGS[@]}" 2>&1 1>&3)
            STATUS=$?
            [ $STATUS -eq 0 ] && STATUS=success || STATUS=error
            #debug "Function $FUNC status: $STATUS" # 1>&2
            exec 3>&-
            echo "$OUTPUT" # && echo "$OUTPUT" 1>&2
        else
            # echo "Function $FUNC not found" | logger error
            return 1
        fi
    }
    _usage() {
        local ERROR_CODE=${1:-0}
        local CONTEXT=${2:-}
        local FUNC_LIST && FUNC_LIST=$(declare -F | awk '{print $3}') && FUNC_LIST=${FUNC_LIST[*]} && FUNC_LIST=$(echo "$FUNC_LIST" | sed -e 's/ /\n/g' | grep -v '^_')
        echo "usage: builder [$CONTEXT] [args] $*" | logger info
        echo "Available functions: (${YELLOW}${FUNC_LIST}${NC})" | logger info
        # for FUNC in $FUNC_LIST; do
        #     [[ "$FUNC" == _* ]] && continue
        #     echo "  $FUNC" | logger info
        # done
        return "$ERROR_CODE"
    }
    (
        while IFS= read -r LINE || [ -n "$LINE" ]; do
            [ -z "$RAPD_DEBUG" ] || [ "$RAPD_DEBUG" == false ] && continue
            if [ -n "$(type -t "logger")" ] && [ "$(type -t "$FUNC")" = function ]; then
                logger debug "$LINE" #1>&2
            else
                echo "fdafdas - $LINE" #1>&2
            fi
        done <"$RAPD_FIFO"
    ) &
    bootstrap
    # bootstrap
    logger debug "${YELLOW}yw-sh${NC} ${GREEN}$*${NC}"
    if nnf "$@"; then return 0; fi
    usage "$?" "$@" && return 1
    # logger log info "SDK paths: $PATHS"
}
(
    export -f sdk
)
if [ "$#" -gt 0 ]; then sdk "$@"; fi
