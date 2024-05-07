#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317

ydk:docs() {
    local TEST_ENTRYPOINT="$(realpath "${YDK_CLI_ENTRYPOINT}")"
    references() {
        ydk:require --throw gawk 4>/dev/null 2>&1
        local GWAK_FILE='/workspace/rapd-shell/packages/ydk/lib/docs.awk.sh'
        local PACKAGE_FILE="${1}"
        local PACKAGE_FILE_NAME=$(basename "${PACKAGE_FILE}" | sed 's/^[0-9]*\.//')
        local PACKAGE_NAME_SANTEZIED=${PACKAGE_FILE_NAME//.ydk.sh/}
        gawk -f "${GWAK_FILE}" \
            -v file_title="YDK ${PACKAGE_NAME_SANTEZIED} Package" \
            "${@}" >&4
    }
    generate:functions() {
        local YDK_FUNCTIONS=$(ydk:functions 4>&1 | jq -r '.functions[]')
        for FUNC_NAME in ${YDK_FUNCTIONS}; do
            {
                echo "## $FUNC_NAME"
                echo \$'```bash'
                declare -f "${FUNC_NAME}" | grep -v "declare"
                echo \$'```'
            } 1>&2
        done
    }
    generate() {
        local YDK_PACKAGES=$(
            find "$(dirname "${TEST_ENTRYPOINT}")" \
                -type f -name "*.ydk.sh" \
                -not -name "$(basename "${TEST_ENTRYPOINT}")" | sort
        )
        readarray -t YDK_PACKAGES <<<"${YDK_PACKAGES}"
        for PACKAGE in "${YDK_PACKAGES[@]}"; do
            echo "## $PACKAGE" 1>&2
            local PACKAGE_FILE_NAME=$(basename "${PACKAGE}" | sed 's/^[0-9]*\.//')
            local PACKAGE_NAME_SANTEZIED=${PACKAGE_FILE_NAME//.ydk.sh/}
            bash -c "{
                echo \"### Package ${PACKAGE_NAME_SANTEZIED} at ${PACKAGE}\"
                source \"$PACKAGE\" activate
                FUNC_LIST=\$(
                    declare -F |
                        awk '{print \$3}' |
                        tr ' ' '\n' |
                        sort |
                        uniq |
                        tr '\n' ' ' |
                        sed -e 's/ $//'
                )
                for FUNC_NAME in \${FUNC_LIST}; do
                    [[ \"\$FUNC_NAME\" == _* ]] && continue
                    [[ \"\$FUNC_NAME\" == bats_* ]] && continue
                    [[ \"\$FUNC_NAME\" == batslib_* ]] && continue
                    [[ \"\$FUNC_NAME\" == assert_* ]] && continue
                    [[ ! \"\$FUNC_NAME\" == ydk* ]] && continue
                    [[ \"\$FUNC_NAME\" == ydk ]] && continue
                    [[ \"\$FUNC_NAME\" == *:*:* ]] && continue
                    {
                        echo \"#### \$FUNC_NAME\"
                        echo \$'\`\`\`bash'
                        echo \"\$(declare -f \"\$FUNC_NAME\" | grep -v \"declare\")\"
                        echo \$'\`\`\`'
                    } 1>&2
                    # echo \"#### \$FUNC_NAME\" 1>&2
                    # echo \"\`\`\`\" 1>&2
                    # # echo \"\$(declare -f \"\$FUNC_NAME\" | grep -v \"declare\")\" 1>&2
                    # #echo \"\`\`\`\" 1>&2
                done
            }" 1>&2
            references "${PACKAGE}" 4>&1 #1>&2
            break
        done
    }
    ydk:try "$@" 4>&1
    return $?
}
