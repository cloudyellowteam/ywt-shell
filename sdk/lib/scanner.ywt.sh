#!/usr/bin/env bash
# shellcheck disable=SC2317,SC2120,SC2155,SC2044
scanner() {
    local SCANNER_NAME="$1" && shift && SCANNER_NAME="${SCANNER_NAME,,}" && SCANNER_NAME="${SCANNER_NAME// /-}" && SCANNER_NAME="${SCANNER_NAME//./-}" && SCANNER_NAME="${SCANNER_NAME//:/-}" && SCANNER_NAME="${SCANNER_NAME//\//-}"
    local SCANNER_UID="$(mktemp -u -t XXXXXXXXXXXXXX -p /tmp)" && SCANNER_UID="$(basename "$SCANNER_UID")" && SCANNER_UID="${SCANNER_UID//./-}"
    local SCANNER_OUTPUT="/tmp/scanner-${SCANNER_UID}.ywt"
    __scanner:result() {
        {
            echo -n "{"
            if [ ! -f "$SCANNER_OUTPUT" ]; then
                echo -n "\"format\":\"text\","
                echo -n "\"text\":\"No output\","
            elif jq . "$SCANNER_OUTPUT" >/dev/null 2>&1; then
                echo -n "\"format\":\"json\","
                echo -n "\"json\":$(jq . "$SCANNER_OUTPUT"),"
            else
                echo -n "\"format\":\"text\","
                local SCANNER_CONTENT="$(
                    {
                        cat "$SCANNER_OUTPUT"
                    } | sed 's/"/\\"/g' |
                        awk '{ printf "%s\\n", $0 }' |
                        awk '{ gsub("\t", "\\t", $0); print $0 }' |
                        sed 's/^/  /'
                )"
                echo -n "\"text\":\"$SCANNER_CONTENT\","
            fi
            echo -n "\"end\":$(date +%s)"
            echo -n "}"
        } | jq -c .
    }
    run() {
        local SCANNER_START_AT="$(date +%s)"
        local DOCKER_ARGS=(
            "--rm"
            "--name" "ywt-scanners-${SCANNER_UID}"
            "-v" "$(pwd):/ywt-workdir"
            "-v" "/var/run/docker.sock:/var/run/docker.sock"
            "-v" "/tmp:/tmp"
            "ywt-sca:latest"
        )
        local SCANNER="$({
            echo -n "{"
            echo -n "\"scanner\":\"$(echo -n "$SCANNER_NAME" | base64)${SCANNER_UID}\","
            echo -n "\"output\":\"${SCANNER_OUTPUT}\","
            echo -n "\"start\":${SCANNER_START_AT},"
            echo -n "\"docker-args\":\"${DOCKER_ARGS[*]}\""
            echo -n "}"
        } | jq -c .)"
        case "$SCANNER_NAME" in
        cloc)
            local SCANNER_METADATA=$(__scanner:cloc metadata)
            local SCANNER_RESULT=$(__scanner:cloc scan "$@")
            ;;
        esac
        jq -n \
            --argjson scanner "$SCANNER" \
            --argjson metadata "$SCANNER_METADATA" \
            --argjson result "$SCANNER_RESULT" '
            {
                scanner: {
                    id: $scanner.scanner,
                    metadata: $metadata,
                },
                report: {
                    output: $scanner.output,
                    start: $scanner.start,
                    end: $result.data.end,
                    elapsed: ($result.data.end - $scanner.start),
                    error: $result.error,
                    $result
                }
            }
        '
    }
    run "$SCANNER_NAME" "$@"

}
scanner:v1() {
    local SCANNER_NAME="$1" && shift && SCANNER_NAME="${SCANNER_NAME,,}" && SCANNER_NAME="${SCANNER_NAME// /-}" && SCANNER_NAME="${SCANNER_NAME//./-}" && SCANNER_NAME="${SCANNER_NAME//:/-}" && SCANNER_NAME="${SCANNER_NAME//\//-}"
    local RESULT_FILE="$(mktemp -u -t ywt-XXXXXX --suffix=".$SCANNER_NAME" -p /tmp)"
    local SCANNER_UID="$(basename "$RESULT_FILE")" && SCANNER_UID="${SCANNER_UID//./-}"
    local DOCKER_ARGS=(
        "--rm"
        "--name" "${SCANNER_UID}"
        "-v" "$(pwd):/ywt-workdir"
        "-v" "/var/run/docker.sock:/var/run/docker.sock"
        "ywt-sca:latest"
    )
    case "$SCANNER_NAME" in
    network-hsts)
        __scanner:network:hsts "$@"
        ;;
    cloc)
        __scanner:cloc "$@"
        ;;
    trivy)
        __scanner:trivy "$@"
        ;;
    trufflehog)
        __scanner:trufflehog "$@"
        ;;
    *)
        __nnf "$@" || usage "tests" "$?" "$@" && return 1
        ;;
    esac
}
(
    export -f scanner
)
