#!/usr/bin/env bash
# shellcheck disable=SC2317,SC2120,SC2155,SC2044

__scanner:trufflehog() {
    local DEFAULT_ARGS=(
        "--json"
    )
    trufflehog:cli() {
        __scanner:cli "trufflehog" "${DEFAULT_ARGS[@]}" "$@"
    }
    trufflehog:version() {
        trufflehog:cli --version
        return 0
    }
    trufflehog:metadata() {
        {
            echo -n "{"
            echo -n "\"uuid\":\"cbb46398-a79e-4afe-9672-badabf6075e7\","
            echo -n "\"capabilities\":[\"filesystem\",\"repository\",\"docker:image\", \"bucket\"],"
            echo -n "\"features\":[\"secrets\"],"
            echo -n "\"engines\":[\"host\",\"docker\"],"
            echo -n "\"formats\":[\"json\",\"text\"]"
            echo -n "}"
        } | jq -c .
        return 0
    }
    trufflehog:activate() {
        echo "{}"
        return 0
    }
    trufflehog:result() {
        echo -n "["
        {
            while read -r LINE; do
                echo -n "$LINE"
                echo -n ","
            done <"$1"
        } | sed 's/,$//'
        echo -n "]"
    }
    trufflehog:summary(){        
        echo -n "{}"
    }
    local ACTION="$1" && shift
    __nnf "trufflehog:$ACTION" "$@"
}
