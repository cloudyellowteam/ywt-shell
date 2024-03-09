#!/bin/bash

sdk() {
    set -e -o pipefail
    local RAPD_CMD_PROCESS=$$ && readonly RAPD_CMD_PROCESS
    local RAPD_CMD_FILE=$0 && readonly RAPD_CMD_FILE
    local RAPD_CMD_ARGS=$* && readonly RAPD_CMD_ARGS
    local RAPD_CMD_ARGS_LEN=$# && readonly RAPD_CMD_ARGS_LEN
    local RAPD_CMD_NAME && RAPD_CMD_NAME=$(basename -- "$0") && RAPD_CMD_NAME="${RAPD_CMD_NAME%.*}" && readonly RAPD_CMD_NAME
    local RAPD_INITIALIZED=false
    echo "RAPD_CMD_PROCESS = $RAPD_CMD_PROCESS"
    echo "RAPD_CMD_FILE = $RAPD_CMD_FILE"
    echo "RAPD_CMD_ARGS = $RAPD_CMD_ARGS"
    echo "RAPD_CMD_ARGS_LEN = $RAPD_CMD_ARGS_LEN"
    echo "RAPD_CMD_NAME = $RAPD_CMD_NAME"
    echo "PWD = $PWD"
    paths() {
        local CMD && CMD=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd) && readonly CMD
        local SRC="${CMD}"
        local PROJECT && PROJECT=$(dirname -- "$SRC") && PROJECT=$(realpath -- "$PROJECT") && readonly PROJECT
        local WORKSPACE && WORKSPACE=$(dirname -- "$PROJECT") && WORKSPACE=$(realpath -- "$WORKSPACE") && readonly WORKSPACE
        local TMP="${RAPD_CONFIG_PATH_TMP:-"$(dirname -- "$(mktemp -d -u)")"}/${RAPD_CMD_NAME}"
        echo -n "{"
        echo -n "\"cmd\":\"$CMD\","
        echo -n "\"workspace\":\"$WORKSPACE\","
        echo -n "\"project\":\"$PROJECT\","
        echo -n "\"src\":\"$SRC\"",
        echo -n "\"lib\":\"$SRC/lib\"",
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
        echo -n "\"logs\":\"${RAPD_CONFIG_PATH_LOGS:-"${TMP}/logs"}\"",
        echo -n "\"cache\":\"${RAPD_CONFIG_PATH_CACHE:-"${TMP}/cache"}\"",
        echo -n "\"data\":\"${RAPD_CONFIG_PATH_DATA:-"${TMP}/data"}\"",
        echo -n "\"etc\":\"${RAPD_CONFIG_PATH_ETC:-"${TMP}/etc"}\"",
        echo -n "\"pwd\":\"${RAPD_CONFIG_PATH_CWD:-"${PWD}"}\""
        echo -n "}"
        echo ""
    }
    local RAPD_PATHS && RAPD_PATHS=$(paths) && readonly RAPD_PATHS
    resources() {
        local TYPE=${1:-} && [ -z "$TYPE" ] && echo "Resource type not defined" && return 1
        local RESOURCE_PATH && RESOURCE_PATH=$(jq -r ".$TYPE" <<<"$RAPD_PATHS")
        [ ! -d "$RESOURCE_PATH" ] && echo "Resource $TYPE not found" && return 1
        find "$RESOURCE_PATH" -mindepth 1 -maxdepth 1 -type d -printf '%P\n' | jq -R -s -c 'split("\n") | map(select(length > 0))'
    }
    package() {
        local RAPD_PACKAGE && RAPD_PACKAGE=$(jq -c <"./package.json" 2>/dev/null)
        echo "$RAPD_PACKAGE"
    }
    is_function() {
        local FUNC=${1:-} && [ -n "$(type -t "$FUNC")" ] && [ "$(type -t "$FUNC")" = function ]
    }
    is_binary() {
        local FILE="$1"
        # local FILE_INFO=$(file "$FILE")
        # [[ "$FILE_INFO" =~ "binary" ]] && echo 1 || echo 0
        # local FILE_INFO=$(file -b --mine-encoding "$FILE")
        # [[ "$FILE_INFO" =~ "binary" ]] && echo 1 || echo 0
        LC_ALL=C grep -q -m 1 "^" "$FILE" && echo 0 || echo 1
    }
    etime() {
        ps -o etime= "$$" | sed -e 's/^[[:space:]]*//' | sed -e 's/\://'
    }
    bootstrap() {
        [ "$RAPD_INITIALIZED" == true ] && return 0
        RAPD_INITIALIZED=true
        jq . <<<"$RAPD_PATHS"
        package | jq .
        # return array of resources
        # resources packages
        # resources tools
        # resources scripts
        # resources extensions        
        inject
        export RAPD_PATHS
    }
    inject() {
        local LIB && LIB=$(jq -r '.lib' <<<"$RAPD_PATHS") && readonly LIB
        while read -r FILE; do
            local FILE_NAME && FILE_NAME=$(basename -- "$FILE") && FILE_NAME="${FILE_NAME%.*}" && FILE_NAME=$(echo "$FILE_NAME" | tr '[:upper:]' '[:lower:]')
            is_function "$FILE_NAME" && continue
            # shellcheck source=/dev/null # echo "source $FILE" 1>&2 &&
            [ -f "$FILE" ] && echo "source ${INVERSE}$FILE${NC} !" 1>&2 && source "$FILE"             
        done < <(find "$LIB" -type f -name "*.sh" | sort)
    }
    verbose() {
        echo "$1" 1>&2
    }
    # call next near function with args
    nnf() {
        local FUNC=${1:-config} && shift
        local ARGS=("${@}") # local ARGS=("${@:2}")
        if [ -n "$(type -t "$FUNC")" ] && [ "$(type -t "$FUNC")" = function ]; then
            verbose "Running $FUNC with args: ${ARGS[*]}" 1>&2
            exec 3>&1
            local STATUS
            local OUTPUT && OUTPUT=$($FUNC "${ARGS[@]}" 2>&1 1>&3)
            STATUS=$?
            [ $STATUS -eq 0 ] && STATUS=success || STATUS=error
            verbose "Function $FUNC status: $STATUS" 1>&2
            exec 3>&-
            echo "$OUTPUT" # && echo "$OUTPUT" 1>&2
        else
            echo "Function $FUNC not found" | logger error
            return 1
        fi
    }
    bootstrap "$@"
    # logger log info "SDK paths: $PATHS"
}
(
    export -f sdk
)
sdk "$@"

