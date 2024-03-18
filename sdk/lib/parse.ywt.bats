#!/usr/bin/env bats
# bats file_tags=sdk, lib, parser

# bats test_tags=sdk, lib, parser, querystring
@test "parse querystring ?status=success&message=hello" {
    run ywt parse querystring "?status=success&message=hello"
    [ "$BATS_RUN_COMMAND" == "ywt parse querystring ?status=success&message=hello" ]    
    test_report
    assert_success
    assert_output --partial "\"message\":\"hello\""
    assert_output --partial "\"status\":\"success\""
    local JSON=$(test_extract_json "$output" | jq -c .)
    test_log "result=$JSON"
    [ "$JSON" == '{"status":"success","message":"hello"}' ]
    [ "$(jq -r .status <<< "$JSON")" == "success" ]
    [ "$(jq -r .message <<< "$JSON")" == "hello" ]
}

# bats test_tags=sdk, lib, parser, url
@test "parse full uri" {
    local URI="https://user:pass@www.example.com:8080/path?status=success&message=hello#anchor"
    run ywt parse url "$URI"
    [ "$BATS_RUN_COMMAND" == "ywt parse url $URI" ]    
    test_report
    assert_success
    assert_output --partial "\"host\":\"www.example.com\""
    # assert_output --partial "\"path\":\"/path\""
    assert_output --partial "\"port\":\"8080\""
    assert_output --partial "\"protocol\":\"https\""
    # assert_output --partial "\"query\":\"status=success&message=hello\""
    local JSON=$(test_extract_json "$output" | jq -c .)
    test_log "result=$JSON"
    # [ "$JSON" == '{"host":"www.example.com","path":"/path","port":"8080","protocol":"https","query":"status=success&message=hello"}' ]
    [ "$(jq -r .host <<< "$JSON")" == "www.example.com" ]
    # [ "$(jq -r .path <<< "$JSON")" == "/path" ]
    [ "$(jq -r .port <<< "$JSON")" == "8080" ]
    [ "$(jq -r .protocol <<< "$JSON")" == "https" ]
    # [ "$(jq -r .query <<< "$JSON")" == "status=success&message=hello" ]    
}

# bats test_tags=sdk, lib, parser, url
@test "parse partial uri" {
    local URI="https://www.example.com:8080/path?status=success&message=hello#anchor"
    run ywt parse url "$URI" --host
    [ "$BATS_RUN_COMMAND" == "ywt parse url $URI --host" ]    
    test_report
    assert_success
    assert_output --partial "\"host\":\"www.example.com\""
    local JSON=$(test_extract_json "$output" | jq -c .)
    test_log "result=$JSON"
    # [ "$JSON" == '{"host":"www.example.com"}' ]
    [ "$(jq -r .host <<< "$JSON")" == "www.example.com" ]
}