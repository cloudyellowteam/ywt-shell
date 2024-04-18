#!/usr/bin/env bats
# bats file_tags=sdk, lib, extract

# bats test_tags=sdk, lib, extract, json
@test "extract json" {
    skip "not implemented"
    run ywt extract json '{"status":"success","message":"hello"}'
    [ "$BATS_RUN_COMMAND" == "extract json '{\"status\":\"success\",\"message\":\"hello\"}'" ]
    test_report
    assert_success
    assert_output --partial "\"message\":\"hello\""
    assert_output --partial "\"status\":\"success\""
    [ "$output" == '{"status":"success","message":"hello"}' ]
    local JSON=$(test_extract_json "$output" | jq -c .)
    test_log "result=$JSON"
    [ "$JSON" == '{"status":"success","message":"hello"}' ]
    [ "$(jq -r .status <<<"$JSON")" == "success" ]
    [ "$(jq -r .message <<<"$JSON")" == "hello" ]
}
