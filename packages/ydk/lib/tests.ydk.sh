#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317

ydk:tests() {
    YWT_LOG_CONTEXT="TESTS"
    local TESTS_DIR="${YDK_PATHS[tests]}" && TESTS_DIR="${TESTS_DIR#!}"
    local TMP_DIR="${YDK_PATHS[tmp]}" && TMP_DIR="${TMP_DIR#!}"
    local TEST_HELPER_DIR="${TESTS_DIR}/helpers" && [ ! -d "TEST_HELPER_DIR" ] && mkdir -p "${TEST_HELPER_DIR}"
    local TEST_ENTRYPOINT="$(realpath "${YDK_CLI_ENTRYPOINT}")"
    ydk:log info "Tests are into $TESTS_DIR"
    ydk:log info "Tests into $TMP_DIR"
    ydk:log info "Tests into $TEST_ENTRYPOINT"
    __tests:generate:setup() {
        local TEST_HELPER_SETUP_FILE="${TEST_HELPER_DIR}/setup.sh"
        rm -f "${TEST_HELPER_SETUP_FILE}"
        local TABS=16
        local TABS_SPACES=$(printf "%${TABS}s")
        {
            echo -e "#!/usr/bin/env bash
                # 🩳 ydk-shell@0.0.0-dev-0 sdk
                
                ydk:test:log() {
                \tIFS=\$'\\\n'
                \tfor VALUE in \"\${@}\"; do
                \t    while read -r LINE; do
                \t        printf \" \${YELLOW}-> %s\${NC}\\\n\" \"\$LINE\" >&3
                \t    done <<<\"\${VALUE}\"
                \tdone
                }
                ydk:test:report(){
                \tdeclare -A YDK_TEST_RESULTS=(
                \t\t[command]=\"\${YELLOW}\${BATS_RUN_COMMAND}\${NC}\"
                \t\t[status]=\"\${BATS_RUN_STATUS:-\${status}}\"
                \t\t[name]=\"\${BATS_TEST_NAME}\"
                \t\t# [description]=\"\${BATS_TEST_DESCRIPTION}\"
                \t\t# [number]=\"\${BATS_TEST_NUMBER}\"
                \t\t# [dir]=\"\${BATS_TEST_DIRNAME}\"
                \t\t# [names]=\"\${BATS_TEST_NAMES}\"
                \t\t# [prefix]=\"\${BATS_TEST_NAME_PREFIX}\"
                \t\t# [retries]=\"\${BATS_TEST_RETRIES}\"
                \t\t# [timeout]=\"\${BATS_TEST_TIMEOUT}\"
                \t\t# [suite_number]=\"\${BATS_SUITE_TEST_NUMBER}\"
                \t\t# [tmpdir]=\"\${BATS_TMPDIR}\"
                \t\t# [run_tmpdir]=\"\${BATS_RUN_TMPDIR}\"
                \t\t# [file_extension]=\"\${BATS_FILE_EXTENSION}\"
                \t\t# [suite_tmpdir]=\"\${BATS_SUITE_TMPDIR}\"
                \t\t# [file_tmpdir]=\"\${BATS_FILE_TMPDIR}\"
                \t\t# [test_tmpdir]=\"\${BATS_TEST_TMPDIR}\"
                \t\t# [version]=\"\${BATS_VERSION}\"
                \t)
                \tfor KEY in \"\${!YDK_TEST_RESULTS[@]}\"; do
                \t    echo -e \"\${YELLOW}\${KEY^^}\${NC}: \${YDK_TEST_RESULTS[\${KEY}]}\" >&3
                \tdone
                }
                ydk:test:setup() {
                \tlocal HELPER_DIR=\"\${BASH_SOURCE[0]}\" && HELPER_DIR=\$(dirname \"\$HELPER_DIR\") && HELPER_DIR=\$(realpath \"\$HELPER_DIR\")
                \tlocal TESTS_DIR && TESTS_DIR=\$(dirname \"\$HELPER_DIR\") && TESTS_DIR=\$(realpath \"\$TESTS_DIR\")
                \tlocal TEST_PROJECT_DIR && TEST_PROJECT_DIR=\$(dirname \"\$TESTS_DIR\") && TEST_PROJECT_DIR=\$(realpath \"\$TEST_PROJECT_DIR\")
                \tload \"helpers/bats-support/load.bash\"
                \tload \"helpers/bats-assert/load.bash\"
                \tload \"helpers/bats-file/load.bash\"
                \tif ! type -t ydk >/dev/null; then
                \t    # local YDK_SHELL_SDK=\"${TEST_ENTRYPOINT}\"
                \t    local YDK_SHELL_SDK=\"/workspace/rapd-shell/packages/ydk/ydk.sh\"
                \t    source \"\${YDK_SHELL_SDK}\" >&3
                \tfi
                }
                ydk:test:teardown(){
                \tlocal HELPER_DIR=\"\${BASH_SOURCE[0]}\" && HELPER_DIR=\$(dirname \"\$HELPER_DIR\") && HELPER_DIR=\$(realpath \"\$HELPER_DIR\")
                \tlocal TESTS_DIR && TESTS_DIR=\$(dirname \"\$HELPER_DIR\") && TESTS_DIR=\$(realpath \"\$TESTS_DIR\")
                \tlocal TEST_PROJECT_DIR && TEST_PROJECT_DIR=\$(dirname \"\$TESTS_DIR\") && TEST_PROJECT_DIR=\$(realpath \"\$TEST_PROJECT_DIR\")
                \t#local TESTS=\$(find \"\${TESTS_DIR}\" -type f -name \"*.bats\" -not -path \"\${TESTS_DIR}/*\")
                \t##rm -f \"\${TESTS[@]}\"
                \t#for TEST in \"\${TESTS[@]}\"; do
                \t#    # rm -f \"\${TEST}\"
                \t#    echo \"Removing \${TEST}\"
                \t#done
                }
            "
            #-e 's/^[[:space:]]*//g' -e 's/[[:space:]]*$//'
        } | sed -e "s/^${TABS_SPACES}*//g" -e 's/[[:space:]]*$//' >"${TEST_HELPER_SETUP_FILE}"
        chmod +x "${TEST_HELPER_SETUP_FILE}"
        echo "$TEST_HELPER_SETUP_FILE" >&4
        return 0
    }
    __tests:bats() {
        ydk:require bats 4>/dev/null 2>&1
        local BATS_VERSION=$(bats --version)
        ydk:log info "Bats version: ${BATS_VERSION} ${TESTS_DIR}"
        # --filter <regex>      Only run tests that match the regular expression
        # filter-tags           <comma-separated-tag-list> Only run tests that match all the tags in the list (&&). You can negate a tag via prepending '!'. Specifying this flag multiple times allows for logical or (||): `--filter-tags A,B --filter-tags A,!C` matches tags (A && B) || (A && !C)
        # --trace              Print test commands as they are executed (like `set -x`)
        # --verbose-run        Make `run` print `$output` by default
        local BATS_ARGS=(
            --recursive
            --no-tempdir-cleanup
            --output "${TMP_DIR:-"/tmp"}"
            --show-output-of-passing-tests
            --print-output-on-failure
            --jobs 100
            --timing
            --tap
            --formatter pretty
        )
        # echo "Bats args: bats ${BATS_ARGS[*]} ${*} ${TESTS_DIR}/*.$$.*.bats" 1>&2
        #
        local YDK_TESTS_RESULT_FILE=$(ydk:temp "ydk-tests-result" ".log" 4>&1)
        {
            sh -c "
                {
                    bats ${BATS_ARGS[*]} ${*} ${TESTS_DIR}/*.$$.*.bats 2>/dev/null # >\"${YDK_TESTS_RESULT_FILE}\" # 1>&2
                    echo \$?
                } 2>&1
            " 2>/dev/null |
                grep -v '^perl' |
                grep -Pv '^\t' |
                sed '/are supported and installed on your system/d' >"${YDK_TESTS_RESULT_FILE}"
        } &
        local YDK_TESTS_PID=$!
        ydk:await spin "${YDK_TESTS_PID}" "Running tests" 1>&2
        unset YDK_TESTS_PID
        local TEST_EXIT_CODE=$(tail -n 1 "${YDK_TESTS_RESULT_FILE}")
        local TEST_RESULT=$(
            awk 'NR > 1 { print prev } { prev = $0 }' "${YDK_TESTS_RESULT_FILE}"
            # head -n -1 "${YDK_TESTS_RESULT_FILE}"
        )
        ydk:log "$([[ ${TEST_EXIT_CODE} -eq 0 ]] && echo "success" || echo "error")" \
            "Test exit code: ${TEST_EXIT_CODE}"
        # ydk:log output "Test result: ${TEST_RESULT}"
        rm -f "${YDK_TESTS_RESULT_FILE}"
        echo "${TEST_RESULT}" >&4
        return "${TEST_EXIT_CODE}"

        # local TEST_RESULT=$(sh -c "bats ${BATS_ARGS[*]} ${*} ${TESTS_DIR}/*.bats" 2>&1)
        # local TEST_EXIT_CODE=$?
        # ydk:log "$([[ ${TEST_EXIT_CODE} -eq 0 ]] && echo "success" || echo "error")" \
        #     "Test exit code: ${TEST_EXIT_CODE}"
        # ydk:log output "Test result: ${TEST_RESULT}"
        # echo "${TEST_RESULT}" >&4
        # return "${TEST_EXIT_CODE}"
    }
    generate() {
        local YDK_TESTS_SETUP_FILE="$(__tests:generate:setup 4>&1)"
        ydk:log info "Tests setup file: $YDK_TESTS_SETUP_FILE"
        # cat "$YDK_TESTS_SETUP_FILE"
        local TESTS=()
        local TABS=20
        local TABS_SPACES=$(printf "%${TABS}s")
        local PACKAGE_TESTS=$(
            find "$(dirname "${TEST_ENTRYPOINT}")" \
                -type f -name "*.ydk.sh" \
                -not -name "$(basename "${TEST_ENTRYPOINT}")" \
                -not -path "${TESTS_DIR}/*" | sort
        )
        readarray -t PACKAGE_TESTS <<<"${PACKAGE_TESTS}"
        local TESTS_GENERATED=0
        ydk:log info "Generating tests for ${#PACKAGE_TESTS[@]} packages"
        for TEST in "${PACKAGE_TESTS[@]}"; do
            local TEST_FILE_NAME=$(basename "${TEST}")
            local TEST_NAME_SANTEZIED=$(sed 's/^[0-9]*\.//' <<<"${TEST_FILE_NAME}")
            TEST_NAME_SANTEZIED=${TEST_NAME_SANTEZIED//.ydk.sh/}
            local TEST_PATH=$(dirname "${TEST}")
            local YDK_FIST_TEST="${TEST_PATH}/${TEST_FILE_NAME//.ydk.sh/}.ydk.bats"
            [[ ! -f "${YDK_FIST_TEST}" ]] && {                
                # echo "Generating fist ${TESTS_GENERATED} test for ${YDK_FIST_TEST}" 1>&2
                {
                    echo -e "
                    #!/usr/bin/env bats
                    # 🩳 ydk-shell@0.0.0-dev-0 sdk
                    # Source File: ${TEST}
                    # https://bats-core.readthedocs.io/en/stable/writing-tests.html#tagging-tests
                    # bats file_tags=ydk, ${TEST_NAME_SANTEZIED,,}
                    # First test generated at $(date)
                    # bats test_tags=ydk, ${TEST_NAME_SANTEZIED,,}, initial
                    @test \"${TEST_NAME_SANTEZIED,,} should be called\" {
                    \trun ydk ${TEST_NAME_SANTEZIED,,}
                    \tydk:test:report
                    \t# assert_success \"${TEST_NAME_SANTEZIED,,} should be called\"
                    \t[[ \"\$status\" -eq 1 ]]
                    \tassert_output --partial \"ydk-shell@\"
                    \tassert_output --partial \"Usage: ydk\"                    
                    }
                " | sed -e "s/^${TABS_SPACES}*//g" -e 's/[[:space:]]*$//'
                } >"${YDK_FIST_TEST}"
            }
            local UNIT_TEST_TEMP_FILE=$(ydk:temp "${TEST_NAME_SANTEZIED,,}.bats" 4>&1)
            local UNIT_TEST_TEMP_FILE_NAME=$(basename "${UNIT_TEST_TEMP_FILE}")
            UNIT_TEST_TEMP_FILE="${TESTS_DIR}/${UNIT_TEST_TEMP_FILE_NAME}"
            {
                cat "${YDK_FIST_TEST}"
                echo -e "
                    # 🩳 ydk-shell@0.0.0-dev-0 sdk
                    # Source File: ${TEST}
                    # Generated at: $(date)
                    setup() {
                    \tload \"helpers/setup.sh\" && ydk:test:setup
                    \tFEATURE_DIR=\"\$(cd \"\$(dirname \"\$BATS_TEST_FILENAME\")\" \t>/dev/null 2>&1 && pwd)\"
                    \tPATH=\"\${FEATURE_DIR}:\${PATH}\"
                    \tFEATURE_DIR=\"$(realpath "${YDK_CLI_ENTRYPOINT}")\"
                    \tPATH=\"\${FEATURE_DIR}:\${PATH}\"
                    }
                    teardown() {
                    \tload \"helpers/setup.sh\" && ydk:test:teardown
                    }
                " | sed -e "s/^${TABS_SPACES}*//g" -e 's/[[:space:]]*$//'
                
            } >"${UNIT_TEST_TEMP_FILE}"
            TESTS_GENERATED=$((TESTS_GENERATED + 1))
            # echo "Generated test ${UNIT_TEST_TEMP_FILE}" 1>&2
        done
        ydk:log info "${TESTS_GENERATED} Tests generated"
        return 0
    }
    cleanup() {
        ydk:log info "Cleaning up tests"
        rm -f -r "${TEST_HELPER_DIR}"
        rm -f "${TESTS_DIR}/*.bats"
        rm -f "/usr/local/bin/bats"
        return 0
    }
    setup() {
        ydk:require --throw git tee 4>/dev/null 2>&1
        [ "${1:-true}" == true ] && cleanup
        {
            [ ! -d "${TEST_HELPER_DIR}/bats" ] && ydk:log info "Getting bats" && git clone https://github.com/bats-core/bats-core.git "${TEST_HELPER_DIR}/bats" &>/dev/null
            [ ! -d "${TEST_HELPER_DIR}/bats-assert" ] && ydk:log info "Getting bats-assert" && git clone https://github.com/bats-core/bats-assert.git "${TEST_HELPER_DIR}/bats-assert" &>/dev/null
            [ ! -d "${TEST_HELPER_DIR}/bats-support" ] && ydk:log info "Getting bats-support" && git clone https://github.com/bats-core/bats-support.git "${TEST_HELPER_DIR}/bats-support" &>/dev/null
            [ ! -d "${TEST_HELPER_DIR}/bats-file" ] && ydk:log info "Getting bats-file" && git clone https://github.com/bats-core/bats-file.git "${TEST_HELPER_DIR}/bats-file" &>/dev/null
        } &
        local YDK_TEST_SETUP_PID=$!
        ydk:await spin "${YDK_TEST_SETUP_PID}" "Setting up tests"
        unset YDK_TEST_SETUP_PID
        rm -fr "${TEST_HELPER_DIR}/**/.git"
        if ! command -v bats >/dev/null 2>&1; then
            ydk:log info "installing bats"
            chmod -R +x "${TEST_HELPER_DIR}"
            "${TEST_HELPER_DIR}"/bats/install.sh /usr/local | tee /dev/null | ydk:log debug
        fi
        ydk:require --throw bats 4>/dev/null 2>&1
        bats --version | ydk:log debug
    }
    unit() {
        setup false
        generate
        local VERBOSE=false
        local TRACE=false
        local TEST_ARGS=()
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
            *)
                TEST_ARGS+=("--filter-tags")
                TEST_ARGS+=("${1}")
                shift
                ;;
            esac
        done
        [ "${VERBOSE}" == true ] && TEST_ARGS+=("--verbose-run") && ydk:log info "Running tests in verbose mode"
        [ "${TRACE}" == true ] && TEST_ARGS+=("--trace") && ydk:log info "Running tests in trace mode"
        local START_TIME=$(date +%s)
        logger info "Running tests tags ${TEST_ARGS[*]/#/--filter-tags }. Start time: ${START_TIME}"
        local TEST_RESULT=$(__tests:bats "${TEST_ARGS[@]}" 4>&1)
        local TEST_EXIT_CODE=$?
        local END_TIME=$(date +%s)
        local ELAPSED_TIME=$((END_TIME - START_TIME))
        # ydk:log info "Test exit code: ${TEST_EXIT_CODE}"
        # ydk:log info "Test result:"
        rm -f "${TESTS_DIR}"/*.bats
        ydk:log output "Test result below"
        echo -e "${TEST_RESULT}" | sed ':a;N;$!ba;s/\n/\n\t/g' 1>&2
        local FAILURES=$(grep -Eo "0 failures" <<<"${TEST_RESULT}")
        if [ "${TEST_EXIT_CODE}" -eq 0 ] && [ -n "${FAILURES}" ]; then
            ydk:log success "All tests passed, great job! (${ELAPSED_TIME} seconds)"
            return 0
        else
            ydk:log error "Some tests failed, check the logs for more details (${ELAPSED_TIME} seconds)"
            return 1
        fi
    }
    ydk:try "$@" 4>&1
    return $?
}

# __tests:v0() {
#     YWT_LOG_CONTEXT="TESTS"
#     local TESTS=()
#     local TESTS_DIR="$(jq -r '.tests' <<<"$YWT_PATHS")"
#     local TMP_DIR="$(jq -r '.tmp' <<<"$YWT_PATHS")"
#     local TEST_HELPER_DIR="${TESTS_DIR}/helpers" && [ ! -d "TEST_HELPER_DIR" ] && mkdir -p "${TEST_HELPER_DIR}"
#     local SDK_DIR="$(jq -r '.sdk' <<<"$YWT_PATHS")"
#     cleanup() {
#         logger info "Cleaning up tests"
#         rm -f -r "${TEST_HELPER_DIR}/bats"
#         rm -f -r "${TEST_HELPER_DIR}/bats-assert"
#         rm -f -r "${TEST_HELPER_DIR}/bats-support"
#         rm -f -r "${TEST_HELPER_DIR}/bats-file"
#         rm -f "/usr/local/bin/bats"
#     }
#     setup() {
#         __require git tee
#         [ "${1}" == true ] && cleanup
#         [ ! -d "${TEST_HELPER_DIR}/bats" ] && logger info "getting bats" && git clone https://github.com/bats-core/bats-core.git "${TEST_HELPER_DIR}/bats" &>/dev/null && rm -fr "${TEST_HELPER_DIR}/bats/.git"
#         [ ! -d "${TEST_HELPER_DIR}/bats-assert" ] && logger info "getting bats-assert" && git clone https://github.com/bats-core/bats-assert.git "${TEST_HELPER_DIR}/bats-assert" &>/dev/null && rm -fr "${TEST_HELPER_DIR}/bats-assert/.git"
#         [ ! -d "${TEST_HELPER_DIR}/bats-support" ] && logger info "getting bats-support" && git clone https://github.com/bats-core/bats-support.git "${TEST_HELPER_DIR}/bats-support" &>/dev/null && rm -fr "${TEST_HELPER_DIR}/bats-support/.git"
#         [ ! -d "${TEST_HELPER_DIR}/bats-file" ] && logger info "getting bats-file" && git clone https://github.com/bats-core/bats-file.git "${TEST_HELPER_DIR}/bats-file" &>/dev/null &
#         rm -fr "${TEST_HELPER_DIR}/bats-file/.git"
#         if ! command -v bats >/dev/null 2>&1; then
#             logger info "installing bats"
#             chmod -R +x "${TEST_HELPER_DIR}"
#             "${TEST_HELPER_DIR}"/bats/install.sh /usr/local | tee /dev/null | logger debug
#             bats --version | logger debug
#         fi
#         __require bats
#     }
#     _bats() {
#         __require bats
#         local BATS_VERSION=$(bats --version)
#         logger info "Bats version: ${BATS_VERSION} ${TESTS_DIR}"
#         # --filter <regex>      Only run tests that match the regular expression
#         # filter-tags           <comma-separated-tag-list> Only run tests that match all the tags in the list (&&). You can negate a tag via prepending '!'. Specifying this flag multiple times allows for logical or (||): `--filter-tags A,B --filter-tags A,!C` matches tags (A && B) || (A && !C)
#         # --trace              Print test commands as they are executed (like `set -x`)
#         # --verbose-run        Make `run` print `$output` by default
#         local TEST_RESULT=$(
#             # bats "${ARGS[@]}" "${TESTS_DIR}"/*.bats 2>&1
#             bats --recursive \
#                 --no-tempdir-cleanup \
#                 --output "${TMP_DIR:-"/tmp"}" \
#                 --show-output-of-passing-tests \
#                 --print-output-on-failure \
#                 --jobs 100 \
#                 --timing \
#                 --tap \
#                 --formatter pretty \
#                 "${@}" \
#                 "${TESTS_DIR}"/*.bats 2>&1
#         )
#         local TEST_EXIT_CODE=$?
#         logger info "Test exit code: ${TEST_EXIT_CODE}"
#         logger info "Test result: ${TEST_RESULT}"
#     }
#     __copy_tests() {
#         __require find mktemp basename cp sed
#         while IFS= read -r -d '' TEST; do
#             local TEST_NAME=$(basename "${TEST}")
#             local TEST_DEST=$(mktemp -u -t XXXXXXXX --suffix=".${TEST_NAME}" --tmpdir="${TESTS_DIR}")
#             local TEST_FILE_NAME=$(basename "${TEST_DEST}") && TEST_FILE_NAME="unit.${TEST_FILE_NAME}"
#             TEST_DEST="${TESTS_DIR}/${TEST_FILE_NAME}"
#             # echo "Copying ${TEST} to ${TEST_DEST}"
#             cp -f "${TEST}" "${TEST_DEST}"
#             {
#                 echo "
#                     # auto-generated setup
#                    setup() {
#                         load \"helpers/setup.sh\" && test_setup
#                         FEATURE_DIR=\"\$(cd \"\$(dirname \"\$BATS_TEST_FILENAME\")\" >/dev/null 2>&1 && pwd)\"
#                         PATH=\"\${FEATURE_DIR}:\${PATH}\" # add feature to PATH
#                     }
#                 " | sed -e 's/^[[:space:]]*// ' -e 's/[[:space:]]*$//'
#             } >>"${TEST_DEST}"
#             TESTS+=("${TEST_DEST}")
#         done < <(find "${SDK_DIR}" -type f -name "*.bats" -not -path "${TESTS_DIR}/*" -print0)
#         return 0
#         # __require mapfile
#         # mapfile -t TESTS < <(find "${SDK_DIR}" -type f -name "*.bats" -not -path "${TESTS_DIR}/*")
#         # echo "Copying tests to ${TMP_DIR}"
#         # for TEST in "${TESTS[@]}"; do
#         #     local TEST_NAME=$(basename "${TEST}")
#         #     local TEST_DEST="${TESTS_DIR}/tmp.${TEST_NAME}"
#         #     # echo "Copying ${TEST} to ${TEST_DEST}"
#         #     cp -f "${TEST}" "${TEST_DEST}"
#         #     {
#         #         echo "
#         #             # auto-generated setup
#         #            setup() {
#         #                 load \"helpers/setup.sh\" && test_setup
#         #                 FEATURE_DIR=\"\$(cd \"\$(dirname \"\$BATS_TEST_FILENAME\")\" >/dev/null 2>&1 && pwd)\"
#         #                 PATH=\"\${FEATURE_DIR}:\${PATH}\" # add feature to PATH
#         #             }
#         #         " | sed -e 's/^[[:space:]]*// ' -e 's/[[:space:]]*$//'
#         #     } >>"${TEST_DEST}"
#         # done
#     }
#     #  --filter-tags "!tcp"
#     unit() {
#         __copy_tests
#         local VERBOSE=false
#         local TRACE=false
#         while [[ $# -gt 0 ]]; do
#             case $1 in
#             -v | --verbose)
#                 VERBOSE=true
#                 shift
#                 ;;
#             -t | --trace)
#                 TRACE=true
#                 shift
#                 ;;
#             *) break ;;
#             esac
#         done
#         [ "${VERBOSE}" == true ] && logger info "Running tests in verbose mode"
#         [ "${TRACE}" == true ] && logger info "Running tests in trace mode"
#         local ARGS=()
#         [ "${VERBOSE}" == true ] && ARGS+=("--verbose-run")
#         [ "${TRACE}" == true ] && ARGS+=("--trace")
#         local LOG_MESSAGE="Running all tests"
#         if [ $# -gt 0 ]; then
#             local IFS=,
#             local TAGS="${*}"
#             ARGS+=("--filter-tags")
#             ARGS+=("${TAGS}")
#             LOG_MESSAGE="Running tests tags: ${TAGS}"
#         fi
#         logger info "${LOG_MESSAGE}"
#         local START_TIME=$(date +%s)
#         local RESULT && RESULT="$(_bats "${ARGS[@]}")"
#         local EXIT_CODE=$?
#         local END_TIME=$(date +%s)
#         local ELAPSED_TIME=$((END_TIME - START_TIME))
#         logger info "Test exit code: ${EXIT_CODE}"
#         logger info "Test result:"
#         __verbose "${RESULT}"
#         local FAILURES=$(grep -Eo "0 failures" <<<"${RESULT}")
#         rm -f "${TESTS[@]}"
#         if [ "${EXIT_CODE}" -eq 0 ] && [ -n "${FAILURES}" ]; then
#             logger success "All tests passed, great job! (${ELAPSED_TIME} seconds)"
#             return 0
#         else
#             logger error "Some tests failed, check the logs for more details (${ELAPSED_TIME} seconds)"
#             return 1
#         fi
#     }
#     case "$1" in
#     cleanup) cleanup && return 0 ;;
#     setup) setup && return 0 ;;
#     unit) shift && setup false && unit "$@" && return 0 ;;
#     *) __nnf "$@" || usage "tests" "$?" "$@" && return 1 ;;
#     esac

#     # __nnf "$@" || usage "$?" "tests" "$@" && return 1
#     # return 0
# }
