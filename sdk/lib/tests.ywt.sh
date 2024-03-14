#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
tests() {
    YWT_LOG_CONTEXT="TESTS"
    local TESTS_DIR="$(jq -r '.tests' <<<"$YWT_PATHS")"
    local TMP_DIR="$(jq -r '.tmp' <<<"$YWT_PATHS")"
    local TEST_HELPER_DIR="${TESTS_DIR}/helpers" && mkdir -p "${TEST_HELPER_DIR}"
    cleanup() {
        logger info "Cleaning up tests"
        rm -f -r "${TEST_HELPER_DIR}/bats"
        rm -f -r "${TEST_HELPER_DIR}/bats-assert"
        rm -f -r "${TEST_HELPER_DIR}/bats-support"
        rm -f -r "${TEST_HELPER_DIR}/bats-file"
        rm -f "/usr/local/bin/bats"
    }
    setup() {
        [ "${1}" == true ] && cleanup
        [ ! -d "${TEST_HELPER_DIR}/bats" ] && logger info "getting bats" && git clone https://github.com/bats-core/bats-core.git "${TEST_HELPER_DIR}/bats" &>/dev/null
        [ ! -d "${TEST_HELPER_DIR}/bats-assert" ] && logger info "getting bats-assert" && git clone https://github.com/bats-core/bats-assert.git "${TEST_HELPER_DIR}/bats-assert" &>/dev/null
        [ ! -d "${TEST_HELPER_DIR}/bats-support" ] && logger info "getting bats-support" && git clone https://github.com/bats-core/bats-support.git "${TEST_HELPER_DIR}/bats-support" &>/dev/null
        [ ! -d "${TEST_HELPER_DIR}/bats-file" ] && logger info "getting bats-file" && git clone https://github.com/bats-core/bats-file.git "${TEST_HELPER_DIR}/bats-file" &>/dev/null
        if ! command -v bats >/dev/null 2>&1; then
            logger info "installing bats"
            chmod -R +x "${TEST_HELPER_DIR}"
            "${TEST_HELPER_DIR}"/bats/install.sh /usr/local | tee /dev/null | logger debug
            bats --version | logger debug
        fi
    }
    _bats() {
        local BATS_VERSION=$(bats --version)
        logger info "Bats version: ${BATS_VERSION} ${TESTS_DIR}"
        # --filter <regex>      Only run tests that match the regular expression
        # filter-tags           <comma-separated-tag-list> Only run tests that match all the tags in the list (&&). You can negate a tag via prepending '!'. Specifying this flag multiple times allows for logical or (||): `--filter-tags A,B --filter-tags A,!C` matches tags (A && B) || (A && !C)
        # --trace              Print test commands as they are executed (like `set -x`)
        # --verbose-run        Make `run` print `$output` by default
        local TEST_RESULT=$(
            # bats "${ARGS[@]}" "${TESTS_DIR}"/*.bats 2>&1
            bats --recursive \
                --no-tempdir-cleanup \
                --output "${TMP_DIR:-"/tmp"}" \
                --show-output-of-passing-tests \
                --print-output-on-failure \
                --jobs 1 \
                --timing \
                --tap \
                --formatter pretty \
                "${@}" \
                "${TESTS_DIR}"/*.bats 2>&1
        )
        local TEST_EXIT_CODE=$?
        logger info "Test exit code: ${TEST_EXIT_CODE}"
        logger info "Test result: ${TEST_RESULT}"
    }
    #  --filter-tags "!tcp"
    unit() {
        local VERBOSE=false
        local TRACE=false
        while [[ $# -gt 0 ]]; do
            case $1 in
            -v | --verbose)
                VERBOSE=true
                shift
                ;;
            -t | --trace)
                TRACE=true
                shift
                ;;
            *) break ;;
            esac
        done
        [ "${VERBOSE}" == true ] && logger info "Running tests in verbose mode"
        [ "${TRACE}" == true ] && logger info "Running tests in trace mode"
        local ARGS=()
        [ "${VERBOSE}" == true ] && ARGS+=("--verbose-run")
        [ "${TRACE}" == true ] && ARGS+=("--trace")
        local LOG_MESSAGE="Running all tests"
        if [ $# -gt 0 ]; then
            local IFS=,
            local TAGS="${*}"
            ARGS+=("--filter-tags")
            ARGS+=("${TAGS}")
            LOG_MESSAGE="Running tests tags: ${TAGS}"
        fi
        logger info "${LOG_MESSAGE}"
        local START_TIME=$(date +%s)
        local RESULT && RESULT="$(_bats "${ARGS[@]}")"
        local EXIT_CODE=$?
        local END_TIME=$(date +%s)
        local ELAPSED_TIME=$((END_TIME - START_TIME))
        logger info "Test exit code: ${EXIT_CODE}"
        logger info "Test result: ${RESULT}"
        local FAILURES=$(grep -Eo "0 failures" <<<"${RESULT}")
        if [ "${EXIT_CODE}" -eq 0 ] && [ -n "${FAILURES}" ]; then
            logger success "All tests passed, great job! (${ELAPSED_TIME} seconds)"
            return 0
        else
            logger error "Some tests failed, check the logs for more details (${ELAPSED_TIME} seconds)"
            return 1
        fi
    }
    case "$1" in
    cleanup) cleanup ;;
    setup) setup ;;
    unit) shift && setup false && unit "$@" ;;
    *) setup && unit "$@" ;;
    esac

    # __nnf "$@" || usage "$?" "tests" "$@" && return 1
    # return 0
}
