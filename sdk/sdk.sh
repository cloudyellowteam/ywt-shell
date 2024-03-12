#!/usr/bin/env bash

sdk() {
    set -e -o pipefail
    local YWT_FIFO="/tmp/ywt.$$.fifo" && [ ! -p "$YWT_FIFO" ] && mkfifo "$YWT_FIFO"
    trap 'rm -f $YWT_FIFO' EXIT

    # local YWT_CMD_NAME && YWT_CMD_NAME=$(basename -- "$0") && YWT_CMD_NAME="${YWT_CMD_NAME%.*}" && readonly YWT_CMD_NAME
    local YWT_CMD_NAME=ywt
    local YWT_INITIALIZED=false
    local YWT_DEBUG=${YWT_CONFIG_DEBUG:-false}
    debug() {
        [ -z "$YWT_DEBUG" ] || [ "$YWT_DEBUG" == false ] && return 0
        [ -z "$*" ] && return 1
        (echo "DEBUG: $*" >$YWT_FIFO) & true        
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
    appinfo() {
        local YWT_PACKAGE && YWT_PACKAGE=$(jq -c <"./package.json" 2>/dev/null)
        echo "$YWT_PACKAGE"
    }
    banner() {
        echo "banner"
    }
    is_function() {
        local FUNC=${1:-} && [ -n "$(type -t "$FUNC")" ] && [ "$(type -t "$FUNC")" = function ]
    }
    [ -z "$YWT_PATHS" ] && local YWT_PATHS && YWT_PATHS=$(paths) && readonly YWT_PATHS
    [ -z "$YWT_APPINFO" ] && local YWT_APPINFO && YWT_APPINFO=$(appinfo) && readonly YWT_APPINFO
    # [ -z "$YWT_PROCESS" ] && local YWT_PROCESS && YWT_PROCESS=$(process) && readonly YWT_PROCESS
    bootstrap() {
        [ "$YWT_INITIALIZED" == true ] && return 0
        YWT_INITIALIZED=true
        # --argjson process "$YWT_PROCESS" \
        export YWT && YWT=$(
            jq -n \
                --argjson package "$YWT_APPINFO" \
                --argjson path "$YWT_PATHS" \
                '{yellowteam: $package, path: $path}'
        ) && readonly YWT
        debug "$(jq . <<<"$YWT")"
        # return array of resources
        # resources packages
        # resources tools
        # resources scripts
        # resources extensions
        inject
        logger info "$(colors colorize "yellow" "$(jq -r '.yellowteam' <<<"$YWT") https://yellowteam.cloud")"
        export YWT_PATHS && readonly YWT_PATHS
        debug "YW initialized"
        echo
    }
    inject() {
        local LIB && LIB=$(jq -r '.lib' <<<"$YWT_PATHS") && readonly LIB
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
            trap 'exec 3>&-' EXIT
            local STATUS
            # $FUNC "${ARGS[@]}"
            local OUTPUT && OUTPUT=$($FUNC "${ARGS[@]}" 1>&3) # 2>&1
            STATUS=$?
            [ $STATUS -eq 0 ] && STATUS=success || STATUS=error
            #debug "Function $FUNC status: $STATUS" # 1>&2
            exec 3>&-
            echo "$OUTPUT" # && echo "$OUTPUT" 1>&2
            # (echo "$OUTPUT" >$YWT_FIFO) & true
        else
            # echo "Function $FUNC not found" | logger error
            return 1
        fi
    }
    usage() {
        local ERROR_CODE=${1:-0} && shift
        local CONTEXT=${1:-}
        local FUNC_LIST && FUNC_LIST=$(declare -F | awk '{print $3}') && FUNC_LIST=${FUNC_LIST[*]} && FUNC_LIST=$(echo "$FUNC_LIST" | sed -e 's/ /\n/g' | grep -v '^_' | sort | tr '\n' ' ' | sed -e 's/ $//')
        [ -z "$CONTEXT" ] && CONTEXT="sdk"
        [ -z "$*" ] && return 0
        echo "usage: ywt [$CONTEXT] [args] $*" | logger info
        echo "Available functions: (${YELLOW}${FUNC_LIST}${NC})" | logger info
        # for FUNC in $FUNC_LIST; do
        #     [[ "$FUNC" == _* ]] && continue
        #     echo "  $FUNC" | logger info
        # done
        return "$ERROR_CODE"
    }
    [ "$YWT_DEBUG" == true ] && (
        tail -f "$YWT_FIFO" | while IFS= read -r LINE || [ -n "$LINE" ]; do
            [ -z "$YWT_DEBUG" ] || [ "$YWT_DEBUG" == false ] && continue
            if [ -n "$(type -t "logger")" ] && [ "$(type -t "$FUNC")" = function ]; then
                #logger debug "$LINE" #1>&2
                echo "logger - $LINE" #1>&2
            else
                echo "echo - $LINE" #1>&2
            fi
        done
    ) &
    true
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
