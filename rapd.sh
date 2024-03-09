#!/bin/bash
# shellcheck disable=SC2044,SC2155,SC2317
RAPD_PATH_SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
echo "RAPD_PATH_SRC = $RAPD_PATH_SRC"
echo "PWD = $PWD"
# shellcheck disable=SC1091
source "${RAPD_PATH_SRC}/src/sdk.sh"
exit 1
RAPD_CMD_FILE=$0
RAPD_PROJECT_NAMESPACE=${BASH_SOURCE[0]%.sh} && RAPD_PROJECT_NAMESPACE=${RAPD_PROJECT_NAMESPACE##*/} && RAPD_PROJECT_NAMESPACE=${RAPD_PROJECT_NAMESPACE^^}
RAPD_PATH_SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export NC=$'\033[0m'
export RAPD_COLORS=(
    black bright-black red bright-red green bright-green yellow bright-yellow blue bright-blue magenta bright-magenta cyan bright-cyan white bright-white
) && readonly RAPD_COLORS
RAPD_PIDS=()
RAPD_OPTIONS=()
sdk() {
    set -e -o pipefail
    handle_error() {
        local ERROR_CODE=$?
        local ERROR_MESSAGE=${1:-"An error occurred"}
        [[ $(type -t logger) != "function" ]] && echo "($ERROR_CODE) $ERROR_MESSAGE" && exit $ERROR_CODE
        logger error "($ERROR_CODE) $ERROR_MESSAGE"
        exit $ERROR_CODE
    }
    trap 'handle_error' ERR
    is_binary() {
        local FILE="$1"
        # local FILE_INFO=$(file "$FILE")
        # [[ "$FILE_INFO" =~ "binary" ]] && echo 1 || echo 0
        # local FILE_INFO=$(file -b --mine-encoding "$FILE")
        # [[ "$FILE_INFO" =~ "binary" ]] && echo 1 || echo 0
        LC_ALL=C grep -q -m 1 "^" "$FILE" && echo 0 || echo 1
    }
    hasOption() {
        local OPTION=${1:-} && [[ -z "$OPTION" ]] && return 1
        local OPTIONS=("${@:2}")
        for OPT in "${OPTIONS[@]}"; do
            [[ "$OPT" == "$OPTION" ]] && return 0
        done
        return 1
    }
    bootstrap() {
        export RAPD_METADATA=$(config "$@")
        local PACKAGE="$(jq -Cc .package <<<"$RAPD_METADATA" 2>/dev/null)"
        logger info "$(hyperlink "$PACKAGE" "https://rapd.run")"
        logger debug "rapd.sh $*"
        # jq -Cc .package <<<"$RAPD_METADATA" | logger info
        sdk prototype
    }
    prototype() {
        if ! command -v envsubst >/dev/null 2>&1; then
            envsubst() {
                local CONTENT=${1:-""}
                while IFS= read -r LINE || [ -n "$LINE" ]; do
                    CONTENT="$CONTENT$LINE"
                done
                echo "$CONTENT"
                # local TMP_DOTENV=$(mktemp)
                # local VAR
                # local VARS=()
                # local VALUES=()
                # while IFS= read -r LINE || [ -n "$LINE" ]; do
                #     IFS='=' read -r VAR VALUE <<<"$LINE"
                #     [[ -z "$LINE" || -z "$VAR" || "$VAR" =~ ^#.*$ ]] && continue
                #     VARS+=("$VAR")
                #     VALUES+=("$VALUE")
                #     local INTEPOLATED=$(eval "echo $VAR=\"$VALUE\"")
                #     echo "$INTEPOLATED" | grep -v '^$'
                # done <"$1" >"$TMP_DOTENV"
                # cat "$TMP_DOTENV"
                # rm -f "$TMP_DOTENV"
                # while IFS= read -r LINE || [ -n "$LINE" ]; do
                #     IFS='=' read -r VAR VALUE <<<"$LINE"
                #     [[ -z "$LINE" || -z "$VAR" || "$VAR" =~ ^#.*$ ]] && continue
                #     # interpolate like envsubst
                #     # echo "VAR = $VAR, VALUE = $VALUE"
                #     # eval "echo $VAR=\"$VALUE\""
                #     # eval "echo \"$LINE\""
                # done
            }
        fi
    }
    rainbow() {
        local TEXT=${1:-$RAPD_CMD_FILE} && shift
        local COLORS=("${@}") && [ ${#COLORS[@]} -eq 0 ] && COLORS=("${RAPD_COLORS[@]}")
        local COLOR_COUNT=${#COLORS[@]}
        local LENGTH=${#TEXT}
        local INDEX=0
        for ((i = 0; i < LENGTH; i++)); do
            local CHAR=${TEXT:$i:1}
            local COLOR=${COLORS[$INDEX]}
            local COLOR_CODE=$(colorize "$COLOR" "$CHAR")
            echo -n "$COLOR_CODE"
            INDEX=$((INDEX + 1))
            [[ $INDEX -ge $COLOR_COUNT ]] && INDEX=0
        done
        echo
    }
    style() {
        local STYLE=${1:-bold} && STYLE=${STYLE,,}
        local TEXT=${2}
        local KIND=${3:-normal} && KIND=${KIND,,}
        [[ ! $KIND =~ ^(normal|italic|underline|blink|inverse|hidden)$ ]] && KIND=normal
        case $STYLE in
        bold) STYLE=1 ;;
        dim) STYLE=2 ;;
        italic) STYLE=3 ;;
        underline) STYLE=4 ;;
        blink) STYLE=5 ;;
        inverse) STYLE=7 ;;
        hidden) STYLE=8 ;;
        esac
        echo -e "\e[${STYLE}m${TEXT}\e[0m"

    }
    colorize() {
        local COLOR=${1:-white} && COLOR=${COLOR,,}
        local TEXT=${2}
        local KIND=${3:-foreground} && KIND=${KIND,,}
        [[ ! $KIND =~ ^(foreground|background|fg|bg)$ ]] && KIND=foreground
        case $COLOR in
        black) COLOR=30 ;;
        bright-black) COLOR=90 ;;
        red) COLOR=31 ;;
        bright-red) COLOR=91 ;;
        green) COLOR=32 ;;
        bright-green) COLOR=92 ;;
        yellow) COLOR=33 ;;
        bright-yellow) COLOR=93 ;;
        blue) COLOR=34 ;;
        bright-blue) COLOR=94 ;;
        magenta) COLOR=35 ;;
        bright-magenta) COLOR=95 ;;
        cyan) COLOR=36 ;;
        bright-cyan) COLOR=96 ;;
        white) COLOR=37 ;;
        bright-white) COLOR=97 ;;
        gray) COLOR=90 ;;
        bright-gray) COLOR=37 ;;
        purple) COLOR=35 ;;
        bright-purple) COLOR=95 ;;
        esac
        [[ $KIND == "background" || $KIND == "bg" ]] && COLOR=$((COLOR + 10))
        echo -e "\e[${COLOR}m${TEXT}\e[0m"
    }
    hyperlink() {
        local TEXT=${1}
        local URL=${2}
        echo -e "\e]8;;${URL}\e\\${TEXT}\e]8;;\e\\"
    }
    etime() {
        ps -o etime= "$$" | sed -e 's/^[[:space:]]*//' | sed -e 's/\://'
    }
    _log_level(){
        local LEVEL=${1:-info} && [[ ! $LEVEL =~ ^(debug|info|warn|error)$ ]] && LEVEL=info        
        local COLOR=white
        case $LEVEL in
        debug) COLOR=cyan ;;
        info) COLOR=green ;;
        warn) COLOR=yellow ;;
        error) COLOR=red ;;
        esac
        LEVEL=$(printf "%-5s" "$LEVEL")
        echo -n "$(colorize "yellow" "[$RAPD_PROJECT_NAMESPACE]") "
        echo -n "$(colorize "bright-black" "[$$]" "fg") "
        # echo -n "$(style "underline" "[$(etime)]" "fg") "
        echo -n "$(colorize "blue" "[$(date +"%Y-%m-%d %H:%M:%S")]" "fg") "
        echo -n "$(colorize "$COLOR" "$(style bold "[${LEVEL^^}]")" "fg") "        
        echo -n " "
    }
    _log_message(){
        local MESSAGE=${1:-}
        local LINES=()
        [[ -n "$MESSAGE" ]] && LINES+=("$MESSAGE")
        [[ -p /dev/stdin ]] && while read -r LINE; do LINES+=("$LINE"); done <&0
        MESSAGE="${LINES[*]//$'\n'/$'\n' }"
        echo -n "$MESSAGE"
    }
    logger() {
        local IS_JSON=${3:-false}
        _log_level "$1"
        [[ $IS_JSON == false ]] && _log_message "$2"
        [[ $IS_JSON == true ]] && jq -cC . <<<"$(_log_message "$2")"
        # elapsed time
        echo " $(colorize "bright-black" "[$(style "underline" "$(etime)")]" "fg")"        
    }
    verbose() {
        # local VERBOSE=$(hasOption "verbose" "${RAPD_OPTIONS[@]}") && [[ $VERBOSE == true ]] && logger debug "$@" && return 0
        # local QUIET=$(hasOption "quiet" "${RAPD_OPTIONS[@]}") && [[ $QUIET == true ]] && return 0
        # local DEBUG=$(hasOption "debug" "${RAPD_OPTIONS[@]}") && [[ $DEBUG == true ]] && logger debug "$@" && return 0
        logger debug "$@"
    }
    dotenv() {
        local FILE=${1}
        [ ! -f "$FILE" ] && logger error "File $FILE not found" && return 1
        # check if envsubst is available
        local CONTENT=$(cat "$FILE")
        # if ! command -v envsubst >/dev/null 2>&1; then
        #     logger warn "envsubst not found, using cat"
        #     local CONTENT=$(cat "$FILE")
        # else
        #     local CONTENT=$(envsubst "$@" <"$FILE") && [ -z "$CONTENT" ] && CONTENT=$(cat "$FILE")
        # fi
        [ -z "$CONTENT" ] && logger info "File $FILE is empty" && return 0
        local NS=${RAPD_PROJECT_NAMESPACE:-RAPD} && [ -n "$2" ] && NS="${NS}_${2^^}"
        local INJECT=${3:-false}
        local QUIET=${4:-true}
        local JSON="{"
        # logger info "Reading env file $file"
        # trap 'handle_error' ERR
        while IFS= read -r LINE || [ -n "$LINE" ]; do
            IFS='=' read -r KEY VALUE <<<"$LINE"
            [[ -z "$LINE" || -z "$KEY" || "$KEY" =~ ^#.*$ || "$VAR" =~ ^#.*$ ]] && continue
            [[ $INJECT == true ]] && export "${NS^^}_${KEY}"="$VALUE" # || echo "${NS^^}_${KEY}=$VALUE" >>"$RAPD_PATH_TMP/.env" # eval "export ${NS^^}_${VAR}"
            JSON="$JSON\"${NS^^}_${KEY}\":\"${VALUE}\","
            [[ $QUIET == false ]] && logger debug "Setting ${NS^^}_${KEY}=$VALUE"
        done <<<"$CONTENT"
        JSON="${JSON%,}"
        JSON="$JSON}"
        echo "$JSON"
    }
    paths() {
        local RAPD_PATH_ROOT=$(dirname -- "$RAPD_PATH_SRC")
        local RADP_PROJECT_ROOT=$(dirname -- "$RAPD_PATH_ROOT")
        local RAPD_PATH_TMP="${RAPD_CONFIG_PATH_TMP:-"$(dirname -- "$(mktemp -d -u)")"}/rapd"
        echo "{
            \"root\": \"$RADP_PROJECT_ROOT\",
            \"parent\": \"$RAPD_PATH_ROOT\",
            \"src\": \"$RAPD_PATH_SRC\",
            \"tmp\": \"$RAPD_PATH_TMP\",
            \"packages\": \"$RAPD_PATH_SRC/packages\",
            \"tools\": \"$RAPD_PATH_SRC/tools\",
            \"tests\": \"$RAPD_PATH_SRC/tests\",
            \"scripts\": \"$RAPD_PATH_SRC/scripts\",
            \"cwd\": \"$PWD\"
        }"
    }
    package() {
        local RAPD_PACKAGE=$(jq -c <"$RAPD_PATH_SRC/package.json" 2>/dev/null)
        echo "$RAPD_PACKAGE"
    }
    packages() {
        local PACKAGES=$(find "$RAPD_PATH_SRC/packages" -mindepth 1 -maxdepth 1 -type d -printf '%P\n' | jq -R -s -c 'split("\n") | map(select(length > 0))')
        echo "$PACKAGES"
    }
    tools() {
        local TOOLS=$(find "$RAPD_PATH_SRC/tools" -mindepth 1 -maxdepth 1 -type f -printf '%P\n' | jq -R -s -c 'split("\n") | map(select(length > 0))')
        echo "$TOOLS"
    }
    program() {
        local PROGRAM=$(basename "${BASH_SOURCE[0]}")
        # local ARGS="${BASH_SOURCE[*]}" && ARGS=${ARGS#* }
        local BASH_VERSION="$BASH_VERSION"
        local SHELL="$SHELL"
        local ARGS="$*"
        local ARGS_LEN="$#"
        echo "{
            \"source\": \"$PROGRAM\",        
            \"args\": \"$ARGS\",
            \"bash\": \"$BASH_VERSION\",
            \"shell\": \"$SHELL\",
            \"args\": \"$ARGS\",
            \"args_len\": \"$ARGS_LEN\"
        }"
    }
    process() {
        local PID="$$"
        local FILE="$RAPD_CMD_FILE"
        echo "{
            \"pid\": \"$PID\",
            \"file\": \"$FILE\",        
            \"args\": \"$*\",
            \"args_len\": \"$#\"
        }"
    }
    hostinfo() {
        local HOSTNAME=$(hostname)
        local OS=$(uname -s)
        local KERNEL=$(uname -r)
        local ARCH=$(uname -m)
        local CPU=$(lscpu | grep "Model name" | cut -d: -f2 | xargs)
        local MEM=$(free -h | awk '/^Mem:/ {print $2}')
        local DISK=$(df -h / | awk '/\// {print $2}')
        echo "{
            \"hostname\": \"$HOSTNAME\",
            \"os\": \"$OS\",
            \"kernel\": \"$KERNEL\",
            \"arch\": \"$ARCH\",
            \"cpu\": \"$CPU\",
            \"mem\": \"$MEM\",
            \"disk\": \"$DISK\"
        }"

    }
    networkinfo() {
        local IP=$(hostname -I | awk '{print $1}')
        local MAC=""
        local GATEWAY=""
        if command -v ip >/dev/null 2>&1; then
            GATEWAY=$(ip route | awk '/default/ {print $3}')
            MAC=$(ip link show | awk '/link\/ether/ {print $2}')
        fi
        local DNS=$(awk '/nameserver/ {print $2}' </etc/resolv.conf)
        local PUBLIC_IP=$(curl -s ifconfig.me)
        echo "{
            \"ip\": \"$IP\",
            \"mac\": \"$MAC\",
            \"gateway\": \"$GATEWAY\",
            \"dns\": \"$DNS\",
            \"public_ip\": \"$PUBLIC_IP\"
        }"
    }
    userinfo() {
        local USER=$(whoami)
        local GROUP=$(id -gn)
        local USERID=$(id -u)
        local GROUPID=$(id -g)
        local HOME=~
        local SHELL="$SHELL"
        local SUDO=$(sudo -nv 2>&1 | grep "may run sudo" || true) && SUDO=${SUDO:-false}
        echo "{
            \"user\": \"$USER\",
            \"group\": \"$GROUP\",
            \"uid\": \"$USERID\",
            \"gid\": \"$GROUPID\",
            \"home\": \"$HOME\",
            \"shell\": \"$SHELL\",
            \"sudo\": \"$SUDO\"
        }"

    }
    flags() {
        local ARGS=()
        while [[ $# -gt 0 ]]; do
            case $1 in
            -v | --verbose)
                local RAPD_VERBOSE=true
                RAPD_OPTIONS+=("verbose")
                shift
                ;;
            -q | --quiet)
                local RAPD_QUIET=true
                RAPD_OPTIONS+=("quiet")
                shift
                ;;
            -d | --debug)
                local RAPD_DEBUG=true
                RAPD_OPTIONS+=("debug")
                shift
                ;;
            -h | --help)
                local RAPD_HELP=true
                shift
                ;;
            -V | --version)
                local RAPD_VERSION=true
                shift
                ;;
            *)
                ARGS+=("$1")
                shift
                ;;
            esac
        done
        set -- "${ARGS[@]}"
        echo "{
            \"verbose\": \"$RAPD_VERBOSE\",
            \"quiet\": \"$RAPD_QUIET\",
            \"debug\": \"$RAPD_DEBUG\",
            \"help\": \"$RAPD_HELP\",
            \"version\": \"$RAPD_VERSION\"
        }"
    }
    params() {
        local JSON="{"
        while [[ $# -gt 0 ]]; do
            local ARG="$1"
            case $ARG in
            param. | -param.* | --param.*)
                local KEYPAIR="${ARG##--param.}" && KEYPAIR="${KEYPAIR#-param.}" && KEYPAIR="${KEYPAIR#param.}"
                local PREFIX="PARAM_"
                ;;
            rapd.* | -rapd.* | --rapd.*)
                local KEYPAIR="${ARG##--rapd.}" && KEYPAIR="${KEYPAIR#-rapd.}" && KEYPAIR="${KEYPAIR#rapd.}"
                local PREFIX="PARAM_"
                ;;
            named. | -named.* | --named.*)
                local KEYPAIR="${ARG##--named.}" && KEYPAIR="${KEYPAIR#-named.}" && KEYPAIR="${KEYPAIR#named.}"
                local PREFIX="PARAM_"
                ;;
            flag. | -flag.* | --flag.*)
                local KEYPAIR="${ARG##--flag.}" && KEYPAIR="${KEYPAIR#-flag.}" && KEYPAIR="${KEYPAIR#flag.}"
                local PREFIX="FLAG_"
                ;;
            *) shift ;;
            esac
            if [ -n "$KEYPAIR" ]; then
                IFS="==:=" read -r KEY VALUE <<<"$KEYPAIR"
                [[ "$PREFIX" == "FLAG_" ]] && [[ -z "$value" ]] && VALUE=true
                VALUE="${VALUE##*=}"
                KEY="${KEY//./_}" && KEY="${KEY//-/_}"
                echo "${BLUE}($KEYPAIR)${NC}${YELLOW}{${KEY}}${NC}=${GREEN}[${VALUE}]${NC}"
                # declare -xg "_${PREFIX}${key^^}=${value}"
                # PARAMS+=("\"${PREFIX}${KEY^^}\":\"${VALUE}\"")
                JSON="$JSON\"${PREFIX}${KEY^^}\":\"${VALUE}\","
            fi
        done
        JSON="${JSON%,}"
        JSON="$JSON}"
        echo "$JSON"
        # echo "${PARAMS[*]}" | tr ' ' '\n'
        # # convert to json
        # echo "[${PARAMS[*]}]" #| jq -s .

    }
    runAsRoot() {
        local CMD="$*"
        if [ "$EUID" -ne 0 ] && [ "$RAPD_USE_SUDO" = "true" ]; then
            CMD="sudo $CMD"
        fi
        $CMD
    }
    spwan() {
        local CMD="$*"
        $CMD &
        RAPD_PIDS+=($!)
        echo $!
        return 0
    }
    spinner() {
        local CMD="$*"
        local SPIN='-\|/'
        local PID=$(spwan "$CMD")
        logger info "Spinning PID: $PID"
        local i=1
        while true; do
            printf "\b%s" "${SPIN:i++%${#SPIN}:1}"
            sleep .1
        done
        # while kill -0 "$PID" 2>/dev/null; do
        #     i=$(((i + 1) % 4))
        #     printf "\r%s" "${SPIN:$i:1}"
        #     sleep .1
        # done
        # printf "\r"
        # spin() {
        #     local PID=$(spwan "$CMD")
        #     logger info "Spinning PID: $PID"
        #     local i=1
        #     while true; do
        #         printf "\b%s" "${SPIN:i++%${#SPIN}:1}"
        #         sleep .1
        #     done
        #     # while kill -0 "$PID" 2>/dev/null; do
        #     #     i=$(((i + 1) % 4))
        #     #     printf "\r%s" "${SPIN:$i:1}"
        #     #     sleep .1
        #     # done
        #     # printf "\r"
        # }
        # spin & local SPIN_PID=$!
        # wait "$SPIN_PID"
        # kill "$SPIN_PID"

        # local PID_INDEX=$(echo "${RAPD_PIDS[@]}" | grep -n "$PID" | cut -d: -f1)
        # [ -n "$PID_INDEX" ] && unset "RAPD_PIDS[$PID_INDEX]"
    }
    config() {
        local RAPD_PATH_ROOT=$(dirname -- "$RAPD_PATH_SRC")
        local RADP_PROJECT_ROOT=$(dirname -- "$RAPD_PATH_ROOT")
        local RAPD_PATH_TMP="${RAPD_CONFIG_PATH_TMP:-"$(dirname -- "$(mktemp -d -u)")"}/rapd"
        local RAPD_PACKAGE=$(jq -c <"$RAPD_PATH_SRC/package.json" 2>/dev/null)
        local PACKAGES=$(find "$RAPD_PATH_SRC/packages" -mindepth 1 -maxdepth 1 -type d -printf '%P\n' | jq -R -s -c 'split("\n") | map(select(length > 0))')
        echo "{
            \"package\": $RAPD_PACKAGE,
            \"env\": $(dotenv "$RAPD_PATH_SRC/.env"),
            \"path\": $(paths),
            \"tools\": $(tools),
            \"packages\": $PACKAGES,
            \"program\": $(program "$@"),
            \"process\": $(process "$@"),
            \"hostinfo\": $(hostinfo),
            \"networkinfo\": $(networkinfo),
            \"userinfo\": $(userinfo),
            \"flags\": $(flags "$@"),
            \"params\": $(params "$@")
        }" | jq .
        return 0
    }
    nnf() {
        local FUNC=${1:-config} && shift
        local ARGS=("${@}") # local ARGS=("${@:2}")
        if [ -n "$(type -t "$FUNC")" ] && [ "$(type -t "$FUNC")" = function ]; then
            verbose "Running $FUNC with args: ${ARGS[*]}" 1>&2
            exec 3>&1
            local STATUS
            # STATUS=$(eval "$FUNC" "${ARGS[*]}" 2>&1 1>&3)
            local OUTPUT=$(
                $FUNC "${ARGS[@]}"
            )
            # $FUNC "${ARGS[@]}" 2>&1 1>&3
            STATUS=$?
            exec 3>&-
            verbose "Function $FUNC status: $STATUS" 1>&2
            echo "$OUTPUT" # && echo "$OUTPUT" 1>&2
            # $FUNC "${ARGS[@]}"
            # local STATUS=$?
            # echo "Function $FUNC status: $STATUS" | logger info
            # return $STATUS
            # local FUNC=$(declare -f "$FUNC") && eval "$FUNC"
            # shift
            # $FUNC "$@"
        else
            echo "Function $FUNC not found" | logger error
            return 1
        fi
    }
    nnf "$@"
}
# alias
logger() {
    sdk logger "$@"
}

[ "$#" -eq 0 ] && logger error "No arguments found" && exit 1
sdk bootstrap "$@"

# echo "$RAPD_METADATA" | jq .package | logjson info

# PROGRAM=$1
# if [ -z "$PROGRAM" ]; then
#     logger error "Program not found"
#     exit 1
# fi
# shift
# logger info "Program: $PROGRAM, args: $*"
# rapd config "$@" | jq -r '.tools[]' | while read -r TOOL; do
#     TOOL="$(rapd config "$@" | jq -r '.path.tools')/$TOOL"
#     NAME=$(basename "$TOOL")
#     # check if name is not equal to program
#     logger info "Checking $PROGRAM"
#     # [ "$TOOL" != "$PROGRAM" ] && continue
#     if [ -f "$TOOL" ]; then
#         logger info "Running $TOOL"
#         $TOOL "$@" | logger info
#         logger info "$NAME status: $?"
#     else
#         logger info "Tool $TOOL not found"
#     fi

#     # [[ -f "$TOOL" ]] && echo "Running $TOOL" && $TOOL "$@" || logger info "$NAME status: $?"
# done
# tasks=$(config "$@" | jq -r '.tools.task')
# [[ -f "$tasks" ]] && echo "$tasks" && $tasks "$@" || echo "Task status: $?"
