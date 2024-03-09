#!/bin/bash
# shellcheck disable=SC2044,SC2155,SC2317
RAPD_CMD_FILE=$0
RAPD_PROJECT_NAMESPACE=${BASH_SOURCE[0]%.sh} && RAPD_PROJECT_NAMESPACE=${RAPD_PROJECT_NAMESPACE##*/} && RAPD_PROJECT_NAMESPACE=${RAPD_PROJECT_NAMESPACE^^}
RAPD_PATH_SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export NC=$'\033[0m'
export RAPD_COLORS=(
    black bright-black red bright-red green bright-green yellow bright-yellow blue bright-blue magenta bright-magenta cyan bright-cyan white bright-white
) && readonly RAPD_COLORS
RAPD_PIDS=()
rapd() {
    set -e -o pipefail
    handle_error() {
        local ERROR_CODE=$?
        local ERROR_MESSAGE=${1:-"An error occurred"}
        [[ $(type -t logger) != "function" ]] && echo "($ERROR_CODE) $ERROR_MESSAGE" && exit $ERROR_CODE
        logger error "($ERROR_CODE) $ERROR_MESSAGE"
        exit $ERROR_CODE
    }
    trap 'handle_error' ERR
    prototype() {
        if ! command -v envsubst >/dev/null 2>&1; then
            envsubst() {
                echo
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
    logger() {
        local LEVEL=${1:-info} && [[ ! $LEVEL =~ ^(debug|info|warn|error)$ ]] && LEVEL=info
        local COLOR=white
        case $LEVEL in
        debug) COLOR=cyan ;;
        info) COLOR=green ;;
        warn) COLOR=yellow ;;
        error) COLOR=red ;;
        esac
        LEVEL=$(colorize "$COLOR" "${LEVEL^^}" "bg")
        local MESSAGE=${2:-} && [[ -z "$MESSAGE" ]] && read -r MESSAGE
        MESSAGE=$(style inverse "$MESSAGE")
        local TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S") && TIMESTAMP=$(colorize "blue" "$TIMESTAMP" "fg")
        local BRAND=$(rainbow "$RAPD_PROJECT_NAMESPACE")
        echo -e "[$BRAND][$TIMESTAMP] ${LEVEL} $MESSAGE"
    }
    dotenv() {
        local FILE=${1}
        [ ! -f "$FILE" ] && logger error "File $FILE not found" && return 1
        local CONTENT=$(envsubst <"$FILE") && [ -z "$CONTENT" ] && CONTENT=$(cat "$FILE")
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
        while [[ $# -gt 0 ]]; do
            case $1 in
            -v | --verbose)
                local RAPD_VERBOSE=true
                shift
                ;;
            -q | --quiet)
                local RAPD_QUIET=true
                shift
                ;;
            -d | --debug)
                local RAPD_DEBUG=true
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
                shift
                ;;
            esac
        done
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
    local FUNC=${1:-config} && shift
    local ARGS=("${@}") # local ARGS=("${@:2}")
    if [ -n "$(type -t "$FUNC")" ] && [ "$(type -t "$FUNC")" = function ]; then
        $FUNC "${ARGS[@]}"
        # local FUNC=$(declare -f "$FUNC") && eval "$FUNC"
        # shift
        # $FUNC "$@"
    else
        echo "Function $FUNC not found" | logger error
        return 1
    fi
    # local FUNC=$(declare -f "$1") && eval "$FUNC"
    # shift
    # $FUNC "$@"
}
boostrap() {
    rapd logger info "Boostraping $*"
    rapd prototype
    
}
boostrap "$@"
# prototype
# rapd "$@"
# CMD="sleep 5"
# # CHILD_PID=$(spwan "$CMD")
# spinner "$CMD"
logger() {
    rapd logger "$@"
}

# exit if no args
[ "$#" -eq 0 ] && logger error "No arguments found" && exit 1

PROGRAM=$1
if [ -z "$PROGRAM" ]; then
    logger error "Program not found"
    exit 1
fi
shift
logger info "Program: $PROGRAM, args: $*"
rapd config "$@" | jq -r '.tools[]' | while read -r TOOL; do
    TOOL="$(rapd config "$@" | jq -r '.path.tools')/$TOOL"
    NAME=$(basename "$TOOL")
    # check if name is not equal to program
    logger info "Checking $PROGRAM"
    # [ "$TOOL" != "$PROGRAM" ] && continue
    if [ -f "$TOOL" ]; then
        logger info "Running $TOOL"
        $TOOL "$@" | logger info
        logger info "$NAME status: $?"
    else
        logger info "Tool $TOOL not found"
    fi
    
    # [[ -f "$TOOL" ]] && echo "Running $TOOL" && $TOOL "$@" || logger info "$NAME status: $?"
done
# tasks=$(config "$@" | jq -r '.tools.task')
# [[ -f "$tasks" ]] && echo "$tasks" && $tasks "$@" || echo "Task status: $?"
