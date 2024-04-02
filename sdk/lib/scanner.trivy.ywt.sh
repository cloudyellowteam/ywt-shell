#!/usr/bin/env bash
# shellcheck disable=SC2317,SC2120,SC2155,SC2044
__scanner:trivy() {
    local DEFAULT_ARGS=(
        "--quiet"
        "--format" "sarif"
    )
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
            echo -n "\"formats\":[\"json\",\"sarif\"]"
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
    local ACTION="$1" && shift
    __nnf "trivy:$ACTION" "$@"
}
