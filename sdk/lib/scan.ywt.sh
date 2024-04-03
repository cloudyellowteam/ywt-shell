#!/usr/bin/env bash
# shellcheck disable=SC2317,SC2120,SC2155,SC2044

# Scan list
# [{"name":"cloc","info":{"id":"bGlzdA==YvzUyUwcjrlduM","output":"/tmp/scanner-YvzUyUwcjrlduM.ywt"},"state":{"activated":true,"api":{"activate":true,"metadata":true,"version":true,"implemented":true}}},{"name":"trivy","info":{"id":"bGlzdA==YvzUyUwcjrlduM","output":"/tmp/scanner-YvzUyUwcjrlduM.ywt"},"state":{"activated":true,"api":{"activate":true,"metadata":true,"version":true,"implemented":true}}},{"name":"trufflehog","info":{"id":"bGlzdA==YvzUyUwcjrlduM","output":"/tmp/scanner-YvzUyUwcjrlduM.ywt"},"state":{"activated":true,"api":{"activate":true,"metadata":true,"version":true,"implemented":true}}}]

scan() {
    __scan:validate() {
        local ASSETS="$1" && shift
        [ ! -f "${ASSETS}" ] && echo "File not found: ${ASSETS}" | logger error && return 1
        if ! jq -e . "${ASSETS}" >/dev/null 2>&1; then
            echo "{\"error\":\"Invalid JSON: ${ASSETS}\"}"
            return 1
        fi
        # max of 10 assets
        local ASSETS_COUNT=$(jq -c '.' "${ASSETS}" | wc -l)
        if [ "${ASSETS_COUNT}" -gt 10 ]; then
            echo "{\"error\":\"Max of 10 assets\"}"
            return 1
        fi
    }
    __scan:assets() {
        local ASSETS="$1" && shift
        if ! __scan:validate "${ASSETS}" >/dev/null 2>&1; then
            echo "{\"error\":\"Invalid assets\"}"
        fi
        jq -c '.' "$ASSETS"
        return 0
    }
    __scan:plan() {
        jq -cn \
            --argjson assets "$(__scan:assets "$1")" \
            --argjson scanners "$(scanner list)" '
            {
                assets: $assets,
                scanners: $scanners,
                plan: (
                    $assets | map(
                        . as $asset |
                        $scanners | map(
                            . as $scanner |
                            select($asset.type | IN($scanner.metadata.capabilities[])) |
                            {
                                asset: $asset,
                                scanner: $scanner
                            }
                        )
                    ) | flatten |
                    map(
                        {
                            asset: .asset,
                            scanner: .scanner,
                            command: "scanner \(.scanner.header.name) asset \(.asset)"
                        }
                    )
                )
            }
        ' | jq '.plan'
    }
    plan() {
        __scan:plan "$@" | jq -c 'del(.[] | .command)'
    }
    summary() {
        __scan:plan "$@" | jq -c '
            {
                assets: (map(.asset) | unique) | length,
                scanners: (map(.scanner.header.name) | unique) | length,
                executions: length
            }
        '
    }
    apply() {
        {
            __scan:plan "$@" | jq -rc '.[] | .command' | while read -r COMMAND; do
                echo -n "{"
                echo -n "\"command\":\"${COMMAND//\"/\\\"}\","
                local SCAN_RESULT=$(${COMMAND})
                local SCAN_EXIT_STATUS=$?
                echo -n "\"exit\":$SCAN_EXIT_STATUS,"
                echo -n "\"result\":"                
                if [ "$SCAN_EXIT_STATUS" -ne 0 ]; then
                    echo "{\"error\":\"Failed: ${COMMAND}\"}"
                elif [ -z "${SCAN_RESULT}" ]; then
                    echo "{\"error\":\"Empty result\"}"
                elif jq -e . >/dev/null 2>&1 <<<"${SCAN_RESULT}"; then
                    echo "${SCAN_RESULT}" | jq -c '.'
                else 
                SCAN_RESULT="${SCAN_RESULT//\"/\\\"}" && SCAN_RESULT="${SCAN_RESULT//$'\n'/}" && SCAN_RESULT="${SCAN_RESULT//$'\r'/}" && SCAN_RESULT="${SCAN_RESULT//$'\t'/}" && SCAN_RESULT="${SCAN_RESULT//$'\v'/}" && SCAN_RESULT="${SCAN_RESULT//$'\f'/}"
                    echo "{\"error\":\"Invalid JSON: ${SCAN_RESULT}\"}"
                fi
                echo -n "}"
                echo 
                # [[ ! "${COMMAND,,}" =~ ^scanner ]] && continue
                # echo "Executing: ${COMMAND}" | logger info
                # ${COMMAND} | jq -c '.' | logger success
                # echo "$?" | logger warn
                # break
                # if ! "${COMMAND}" >/dev/null 2>&1; then
                #     echo "Failed: ${COMMAND}" | logger error
                #     return 1
                # else
                #     echo "Success: ${COMMAND}" | logger success
                # fi
                # eval "${COMMAND}"
            done
        } | jq -s '.'
    }
    __nnf "$@" && return "$?"
}