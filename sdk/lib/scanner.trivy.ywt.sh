#!/usr/bin/env bash
# shellcheck disable=SC2317,SC2120,SC2155,SC2044
# aws         [EXPERIMENTAL] Scan AWS account
# config      Scan config files for misconfigurations
# filesystem  Scan local filesystem
# image       Scan a container image
# kubernetes  [EXPERIMENTAL] Scan kubernetes cluster
# repository  Scan a repository
# rootfs      Scan rootfs
# sbom        Scan SBOM for vulnerabilities and licenses
# vm          [EXPERIMENTAL] Scan a virtual machine image
__scanner:trivy() {
    # local RESULT_FILE="$(mktemp -u -t XXXXXX --suffix=.trivy -p /tmp)"
    local SCANNER="$({
        echo -n "{"
        echo -n "\"scanner\":\"trivy\","
        echo -n "\"type\":\"code\","
        echo -n "\"format\":\"json\","
        echo -n "\"output\":\"$RESULT_FILE\","
        echo -n "\"start\":\"$(date +%s)\","
        echo -n "\"engines\":["
        echo -n "\"host\","
        echo -n "\"docker\""
        echo -n "]"
    })"
    local DEFAULT_ARGS=(
        "-f" "sarif"
        "--quiet"
    )
    if __is command trivy; then
        local VERSION=$(trivy --version)
        SCANNER+="$({
            echo -n ",\"engine\":\"host\""
            echo -n ",\"version\":\"$VERSION\""
        })"
        trivy "${DEFAULT_ARGS[@]}" "$@" >"$RESULT_FILE"
    elif __is command docker; then
        local VERSION=$(docker run "${DOCKER_ARGS[@]}" trivy --version)
        SCANNER+="$({
            echo -n ",\"engine\":\"docker\""
            echo -n ",\"container\":\"${CONTAINER_NAME}\""
            echo -n ",\"version\":\"trivy@$VERSION\""
        })"
        docker run "${DOCKER_ARGS[@]}" trivy "${DEFAULT_ARGS[@]}" "$@" >"$RESULT_FILE"
    else
        SCANNER+=",\"error\":\"trivy not found\""
    fi
    if jq . "$RESULT_FILE" >/dev/null 2>&1; then
        SCANNER+=",\"result\":$(jq . "$RESULT_FILE")"
        local IS_JSON=true
    else
        local CONTENT=$(cat "$RESULT_FILE")
        local IS_JSON=false
        CONTENT=$(
            {
                echo "$CONTENT"
            } | sed 's/"/\\"/g' |
                awk '{ printf "%s\\n", $0 }' |
                awk '{ gsub("\t", "\\t", $0); print $0 }' |
                sed 's/^/  /'
        )
        SCANNER+=",\"text\":\"string\""
    fi
    echo "${SCANNER}, \"end\":\"$(date +%s)\"}" | jq -c .
    [ "$IS_JSON" = false ] && cat "$RESULT_FILE"
    return 0

}
