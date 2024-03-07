#!/bin/bash
# shellcheck disable=SC2044,SC2155,SC2317
RAPD_CMD_FILE=$0
config() {
    local RAPD_PATH_SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    local RAPD_PATH_ROOT=$(dirname -- "$RAPD_PATH_SRC")
    local RADP_PROJECT_ROOT=$(dirname -- "$RAPD_PATH_ROOT")
    local RAPD_PATH_TMP="${RAPD_CONFIG_PATH_TMP:-"$(dirname -- "$(mktemp -d -u)")"}/rapd"
    local RAPD_PACKAGE=$(jq -c < "$RAPD_PATH_SRC/package.json" 2>/dev/null)
    echo '{
        "package": '"$RAPD_PACKAGE"',
        "path": {
            "root": "'"$RADP_PROJECT_ROOT"'",
            "parent": "'"$RAPD_PATH_ROOT"'",
            "rapd": "'"$RAPD_PATH_SRC"'",            
            "packages": "'"$RAPD_PATH_SRC"/packages'",
            "tools": "'"$RAPD_PATH_SRC"/tools'",
            "tests": "'"$RAPD_PATH_SRC"/tests'",
            "scripts": "'"$RAPD_PATH_SRC"/scripts'",            
            "tmp": "'"$RAPD_PATH_TMP"'"            
        },
        "process": {
            "pid": "'$$'",
            "file": "'"$RAPD_CMD_FILE"'",
            "args": "'"$*"'",
            "args_len": "'"$#"'"
        }
    }'
}
config "$@"
tasks=$(config "$@" | jq -r '.path.tools')/task
[[ -f "$tasks" ]] && echo "$tasks" && $tasks "$@" || echo "Task status: $?"
# export RAPD_CMD_PROCESS=$$
# export RAPD_CMD_FILE=$0
# export RAPD_CMD_ARGS=$*
# export RAPD_CMD_ARGS_LEN=$#
# export RAPD_CMD_POSITIONAL_ARGS=()
# export RAPD_PROJECT_NAME=rapd
# export RAPD_PROJECT_NAMESPACE=RAPD
# export RAPD_VERSION="0.0.0-alpha.1"

# export RAPD_PATH_SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# export RAPD_PATH_ROOT=$(dirname -- "$RAPD_PATH_SRC")
# export RADP_PROJECT_ROOT=$(dirname -- "$RAPD_PATH_ROOT")
# export RAPD_PATH_TMP="${RAPD_CONFIG_PATH_TMP:-"$(dirname -- "$(mktemp -d -u)")"}/${RAPD_PROJECT_NAME}"
# [[ ! -d "$RAPD_PATH_TMP" ]] && mkdir -p "$RAPD_PATH_TMP"
# export RAPD_PATH_BIN="${RAPD_PATH_SRC}"

