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
    #  --filter-tags "!tcp"
    unit() {
        local ARGS=("${@}")
        local BATS_VERSION=$(bats --version)
        logger info "Bats version: ${BATS_VERSION} ${TESTS_DIR}"
        # --filter <regex>      Only run tests that match the regular expression
        # filter-tags           <comma-separated-tag-list> Only run tests that match all the tags in the list (&&). You can negate a tag via prepending '!'. Specifying this flag multiple times allows for logical or (||): `--filter-tags A,B --filter-tags A,!C` matches tags (A && B) || (A && !C)
        # --trace              Print test commands as they are executed (like `set -x`)
        # --verbose-run        Make `run` print `$output` by default
        # bats --no-tempdir-cleanup \
        #     --recursive \
        #     --verbose-run \
        #     "${TESTS_DIR}"/*.bats 2>&1
        local TEST_RESULT=$(
            bats --recursive \
                --no-tempdir-cleanup \
                --output "${TMP_DIR:-"/tmp"}" \
                --show-output-of-passing-tests \
                --print-output-on-failure \
                --jobs 1 \
                --tap \
                --formatter pretty \
                "${ARGS[@]}" \
                "${TESTS_DIR}"/*.bats 2>&1
        )
        local TEST_EXIT_CODE=$?
        logger info "Test exit code: ${TEST_EXIT_CODE}"
        logger info "Test result: ${TEST_RESULT}"
    }
    case "$1" in
    cleanup) cleanup ;;
    setup) setup ;;
    unit) shift && setup false && unit "$@" ;;
    *) setup && unit "$@" ;;
    esac

    # _nnf "$@" || usage "$?" "tests" "$@" && return 1
    # return 0
}
