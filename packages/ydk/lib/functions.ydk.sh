#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:functions() {
    echo -n "{"
    echo -n "\"functions\": ["
    local FUNC_LIST=$(
        declare -F |
            awk '{print $3}' |
            tr ' ' '\n' |
            sort |
            uniq |
            tr '\n' ' ' |
            sed -e 's/ $//'
    )
    for FUNC_NAME in ${FUNC_LIST}; do
        [[ "$FUNC_NAME" == _* ]] && continue
        [[ "$FUNC_NAME" == bats_* ]] && continue
        [[ "$FUNC_NAME" == batslib_* ]] && continue
        [[ "$FUNC_NAME" == assert_* ]] && continue
        # local FUNC_ENTRYPOINT=${FUNC_NAME#ydk:}
        [[ ! "$FUNC_NAME" == ydk* ]] && continue
        [[  "$FUNC_NAME" == ydk ]] && continue
        [[ "$FUNC_NAME" == *:*:* ]] && continue 
        # local FUNC_BODY=$(declare -f "${FUNC_NAME}" | grep -v "declare -f")        
        echo -n "\"${FUNC_NAME}\","
    done | sed -e 's/,$//'
    echo -n "]"
    echo -n "}"
    echo
    return 0
}
