#!/usr/bin/env bash
# shellcheck disable=SC2120
test_log() {
    IFS=$'\n'
    for value in "$@"; do
        # value=$(echo "$value" | sed 's/[{[][^}\]]*[}\]]//g')
        while read -r line; do
            printf " ${YELLOW}-> %s${NC}\n" "$line" >&3
        done <<< "$value"
    done
    # echo "${YELLOW} -> ${1}${NC}" >&3

}
test_report() {
    local values=("${GREEN}${BATS_RUN_COMMAND}${NC}")
    # values+=("BATS_TEST_FILENAME: ${BATS_TEST_FILENAME}")
    # values+=("BATS_TEST_DIRNAME: ${BATS_TEST_DIRNAME}")
    # values+=("BATS_TEST_NAMES: ${BATS_TEST_NAMES}")
    # values+=("BATS_TEST_NAME: ${BATS_TEST_NAME}")
    # values+=("BATS_TEST_NAME_PREFIX: ${BATS_TEST_NAME_PREFIX}")
    # values+=("BATS_TEST_DESCRIPTION: ${BATS_TEST_DESCRIPTION}")
    # values+=("BATS_TEST_RETRIES: ${BATS_TEST_RETRIES}")
    # values+=("BATS_TEST_TIMEOUT: ${BATS_TEST_TIMEOUT}")
    # values+=("BATS_TEST_NUMBER: ${BATS_TEST_NUMBER}")
    # values+=("BATS_SUITE_TEST_NUMBER: ${BATS_SUITE_TEST_NUMBER}")
    # values+=("BATS_TMPDIR: ${BATS_TMPDIR}")
    # values+=("BATS_RUN_TMPDIR: ${BATS_RUN_TMPDIR}")
    # values+=("BATS_FILE_EXTENSION: ${BATS_FILE_EXTENSION}")
    # values+=("BATS_SUITE_TMPDIR: ${BATS_SUITE_TMPDIR}")
    # values+=("BATS_FILE_TMPDIR: ${BATS_FILE_TMPDIR}")
    # values+=("BATS_TEST_TMPDIR: ${BATS_TEST_TMPDIR}")
    # values+=("BATS_VERSION: ${BATS_VERSION}")
    test_log "${values[@]}"
    echo
    # local output=${1:-${OUTPUT}}
    # echo "${output}" >&3
}
test_extrat_json() {
    echo "$1" | awk '/^ *{/{p=1}p' # | grep -o '{.*}'
}
test_setup() {
    # echo "test setup" >&3
    load "helpers/bats-support/load.bash"
    load "helpers/bats-assert/load.bash"
    load "helpers/bats-file/load.bash"
    # shellcheck source=/dev/null
    source "${TEST_PROJECT_DIR}/.env"
    is_function() {
        declare -F "${1}" >/dev/null && echo 1 || echo 0
    }
    if [ "$(is_function rapd)" -eq 0 ]; then
        export RAPD_CMD_PATH=$TEST_PROJECT_DIR
        # shellcheck source=/dev/null
        source "${RAPD_CMD_PATH}/src/main.sh"
    fi

}
test_teardown() {
    echo "finishing" >&3
}
test_cache() {
    local action="$1"
    local key="$2"
    local value="$3"
    local file="$TEST_CACHE_FILE"
    # value="$(echo "$value" | sed 's/\x1B\[[0-9;]*[JKmsu]//g')"
    # Check if file exists
    if [[ ! -f "$file" ]]; then
        echo "File not found: $file"
        return 1
    fi
    function create() {
        echo "$key=$value" >>"$file"
    }
    function update() {
        sed -i "s/^$key=.*/$key=$value/" "$file"
    }
    [ "$action" == "create" ] && action=upsert
    [ "$action" == "update" ] && action=upsert
    # Determine which operation to perform
    case "$action" in
    get) grep "^$key=" "$file" | cut -d '=' -f 2 | sed 's/\x1B\[[0-9;]*[JKmsu]//g';;
    delete) sed -i "/^$key=/d" "$file" ;;
    put)
        if grep -q "^$key=" "$file"; then
            update
        else
            create
        fi
        ;;
    *)
        echo "Invalid action: $action"
        return 1
        ;;
    esac
}