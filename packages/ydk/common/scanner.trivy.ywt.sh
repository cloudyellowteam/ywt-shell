#!/usr/bin/env bash
# shellcheck disable=SC2317,SC2120,SC2155,SC2044
__scanner:trivy() {
    local DEFAULT_ARGS=(
        "--quiet"
        "--format" "sarif"
    )
    trivy:install() {
        {
            curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
        } >/dev/null 2>&1

    }
    trivy:uninstall() {
        rm -f /usr/local/bin/trivy >/dev/null 2>&1
    }
    trivy:cli() {
        __scanner:cli "trivy" "${DEFAULT_ARGS[@]}" "$@"
    }
    trivy:version() {
        trivy:cli --version
        return 0
    }
    trivy:metadata() {
        {
            echo -n "{"
            echo -n "\"uuid\":\"cbb46398-a79e-4afe-9672-badabf6075e7\","
            echo -n "\"capabilities\":[\"filesystem\"],"
            echo -n "\"features\":[\"code\", \"vulnerabilities\"],"
            echo -n "\"engines\":[\"host\",\"docker\"],"
            echo -n "\"formats\":[\"json\",\"sarif\"],"
            echo -n "\"priority\":1,"
            echo -n "\"tool\":{"
            echo -n "\"driver\":{"
            echo -n "\"name\":\"trivy\","
            echo -n "\"informationUri\":\"https://github.com/aquasecurity/trivy\","
            echo -n "\"version\":\"0.50.0\""
            echo -n "} }"
            echo -n "}"
        } | jq -c .
        return 0
    }
    trivy:activate() {
        echo "{}"
        return 0
    }
    trivy:result() {
        jq -c '.' "$1"
    }
    trivy:summary() {
        jq -c '
          .runs[].tool.driver.rules[] as $rules |
          .runs[].results[] |
          {
            RuleID: .ruleId,
            Severity: ($rules | select(.id == .ruleId) | .defaultConfiguration.level),
            Package: (.message.text | split("\n")[0]),
            InstalledVersion: (.message.text | split("\n")[1]),
            FixedVersion: (.message.text | split("\n")[4]),
            Link: (.message.text | split("\n")[5])
          }
        ' "$1"
    }
    trivy:asset() {
        local ASSET="${1//\\\"/\"}" && shift
        if ! __is json "$ASSET"; then
            echo "{\"error\":\"Invalid asset\"}"
            return 1
        fi
        case "$(jq -r '.type' <<<"$ASSET")" in
        docker:image)
            local DOCKER_IMAGE="$(jq -r '.target' <<<"$ASSET")"
            if [ -z "$DOCKER_IMAGE" ]; then
                echo "{\"error\":\"Invalid image\"}"
                return 1
            fi
            trivy:cli image "$DOCKER_IMAGE"
            return 0
            ;;
        repository)
            local REPOSITORY="$(jq -r '.target' <<<"$ASSET")"
            if [ ! -d "$REPOSITORY" ]; then
                echo "{\"error\":\"Invalid repository path\"}"
                return 1
            fi
            trivy:cli repository "/ywt-workdir$REPOSITORY"
            return 0
            ;;
        filesystem)
            local ASSET_PATH="$(jq -r '.target' <<<"$ASSET")"
            if [ ! -d "$ASSET_PATH" ]; then
                echo "{\"error\":\"Invalid asset path\"}"
                return 1
            fi
            trivy:cli fs "/ywt-workdir$ASSET_PATH"
            return 0
            ;;
        *)
            echo "{\"error\":\"Invalid asset type\"}"
            return 1
            ;;
        esac
    }
    local ACTION="$1" && shift
    __nnf "trivy:$ACTION" "$@"
    return $?
}
