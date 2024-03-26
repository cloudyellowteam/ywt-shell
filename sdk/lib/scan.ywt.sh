#!/usr/bin/env bash
# shellcheck disable=SC2317,SC2120,SC2155,SC2044
scan() {
    local ASSETS="$1" && shift
    [ ! -f "${ASSETS}" ] && echo "File not found: ${ASSETS}" | logger error && return 1
    if ! jq -e . "${ASSETS}" >/dev/null 2>&1; then
        echo "Invalid JSON: ${ASSETS}" | logger error
        return 1
    fi
    __scan:repository() {
        local ASSET="$1"
        local ASSET_TYPE=$(jq -r '.type' <<<"${ASSET}")
        # echo "Repository: ${ASSET}" | logger info
        # echo "$ASSET"
        echo "{\"target\":\"${ASSET_TYPE}\"}"
    }
    __scan:docker:image() {
        local ASSET="$1"
        # echo "Docker image: ${ASSET}" | logger info
        echo "{\"target\":\"docker:image\"}"
    }
    ASSET="$(cat "${ASSETS}")"
    jq -c '.[]' <<<"$ASSET" | {
        echo -n "["
        while read -r ASSET; do
            local ASSET_TYPE=$(jq -r '.type' <<<"${ASSET}")
            # echo "Asset: (${ASSET_TYPE})" | logger info
            case "${ASSET_TYPE}" in
            repository)
                local RESULT=$(__scan:repository "${ASSET}")
                # echo "${RESULT}"
                ;;
            docker:image)
                local RESULT=$(__scan:docker:image "${ASSET}")

                ;;
            *)
                local RESULT="{\"error\":\"Unknown asset type: ${ASSET_TYPE}\"}"
                ;;
            esac
            jq -n -c --argjson asset "${ASSET}" --argjson result "${RESULT}" '
                {
                    asset: $asset,
                    result: $result
                }
            '
            # jq -n --argjson asset "${ASSET}" --argjson result "${RESULT}" '$asset + $result'
            echo -n ","
        done | sed 's/,$//'
        echo -n "]"
    } | jq .

    return 0
    # __nnf "$@" || usage "tests" "$?" "$@" && return 1
}
(
    export -f scan
)
