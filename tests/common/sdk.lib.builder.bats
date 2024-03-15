#!/usr/bin/env bats
# bats file_tags=sdk:builder

# bats test_tags=sdk:builder:build
@test "ywt builder sdk build" {
    run ywt builder _build_sdk
    test_report
    test_log "status=$status"
    local JSON=$(test_extract_json "$output")
    [ -n "$JSON" ]    # TODO
    [ "$status" -eq 0 ]
    [ "$output" != "" ]
    [ "$BATS_RUN_COMMAND" = "ywt builder _build_sdk" ]
    [ ! "$(jq . <<<"$JSON")" = "null" ]
}
# bats test_tags=sdk:builder:inspect
@test "ywt builder inspect" {
    run ywt builder inspect
    test_report
    test_log "status=$status"
    local JSON=$(test_extract_json "$output")
    [ "$status" -eq 0 ]
    [ "$output" != "" ]
    [ "$BATS_RUN_COMMAND" = "ywt builder inspect" ]
    [ ! "$(jq . <<<"$JSON")" = "null" ]
}


setup() {
    load "helpers/setup.sh" && test_setup
    FEATURE_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
    PATH="$FEATURE_DIR:$PATH" # add feature to PATH
}