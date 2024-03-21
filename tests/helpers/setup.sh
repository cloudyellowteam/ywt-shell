#!/usr/bin/env bash
# shellcheck disable=SC2120,SC2317
test_log() {
    IFS=$'\n'
    for value in "$@"; do
        # value=$(echo "$value" | sed 's/[{[][^}\]]*[}\]]//g')
        while read -r line; do
            printf " ${YELLOW}-> %s${NC}\n" "$line" >&3
        done <<<"$value"
    done
    # echo "${YELLOW} -> ${1}${NC}" >&3

}
test_report() {
    local values=("${GREEN}${BATS_RUN_COMMAND}${NC}")
    values+=("BATS_TEST_FILENAME: ${BATS_TEST_FILENAME}")
    values+=("BATS_TEST_NAME: ${BATS_TEST_NAME}")
    values+=("BATS_TEST_DESCRIPTION: ${BATS_TEST_DESCRIPTION}")
    values+=("BATS_TEST_NUMBER: ${BATS_TEST_NUMBER}")
    values+=("STATUS: ${status}")
    
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
    export JSON_OUTPUT && JSON_OUTPUT=$(echo "$output" | sed -n '/{/,$p')
    #JSON=$(test_extract_json "$output")
    if jq -e . <<< "$JSON_OUTPUT" >/dev/null 2>&1; then
        test_log "Parsed JSON"        
        export JSON_OUTPUT &&  echo "$JSON_OUTPUT" | jq -Ccr '.'
    else
        test_log "Raw Output"
        # test_log "$output"
         #| jq .
        export JSON_OUTPUT="{}" && echo "$output"
        # echo "$output" | sed -n '/{/,$p' #| jq -sR 'fromjson? | select(.)'
    fi     
    echo
    printf '%*s\n' 80 '' | tr ' ' -
    echo
}
test_extract_json() {
    local TEXT="$1"
    [ -z "$TEXT" ] && TEXT="" && while read -r LINE; do TEXT+="$LINE"; done
    local RAW && RAW=$(echo "$TEXT" | sed -n '/{/,$p') #&& RAW="${RAW//\\x1B\\[[0-9;]*[JKmsu]}"
    # echo "$RAW" && return 0
    if jq -e . <<< "$RAW" >/dev/null 2>&1; then 
        echo "${RAW}" | jq -Cr '.'
        return 0 
    fi
    echo "$RAW" | jq -sR 'fromjson? | select(.)'
}
test_setup() {
    local HELPER_DIR="${BASH_SOURCE[0]}" && HELPER_DIR=$(dirname "$HELPER_DIR") && HELPER_DIR=$(realpath "$HELPER_DIR")
    local TESTS_DIR && TESTS_DIR=$(dirname "$HELPER_DIR") && TESTS_DIR=$(realpath "$TESTS_DIR")
    local TEST_PROJECT_DIR && TEST_PROJECT_DIR=$(dirname "$TESTS_DIR") && TEST_PROJECT_DIR=$(realpath "$TEST_PROJECT_DIR")
    # echo "test setup" >&3
    load "helpers/bats-support/load.bash"
    load "helpers/bats-assert/load.bash"
    load "helpers/bats-file/load.bash"
    # # shellcheck source=/dev/null
    # source "${TEST_PROJECT_DIR}/.env"
    if ! type -t ywt >/dev/null; then
        local YWT_SDK="${TEST_PROJECT_DIR}/sdk"
        export RAPD_CMD_PATH=$TEST_PROJECT_DIR
        # echo "HELPER_DIR: $HELPER_DIR" >&3
        # echo "TESTS_DIR: $TESTS_DIR" >&3
        # echo "TEST_PROJECT_DIR: $TEST_PROJECT_DIR" >&3
        # echo "YWT_SDK: $YWT_SDK" >&3

        # shellcheck source=/dev/null
        source "${YWT_SDK}/sdk.sh" >&3
        # echo "Source with $?" >&3
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
    get) grep "^$key=" "$file" | cut -d '=' -f 2 | sed 's/\x1B\[[0-9;]*[JKmsu]//g' ;;
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

