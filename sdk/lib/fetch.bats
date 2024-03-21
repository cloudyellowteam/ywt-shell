#!/usr/bin/env bats
# bats file_tags=sdk, fetch

# bats test_tags=sdk, fetch, get, jsonplaceholder
@test "ywt fetch get jsonplaceholder" {
    local URL="https://jsonplaceholder.typicode.com/todos/1"
    run ywt fetch get "$URL"
    test_report
    assert_success "fetch get httpbin should be successful"
    assert_output --partial "$URL"
    [ "$(jq -r .ok <<<"$JSON_OUTPUT")" == "true" ]
    [ "$(jq -r .json <<<"$JSON_OUTPUT")" == "true" ]
    [ "$(jq -r .status.status_code <<<"$JSON_OUTPUT")" == "200" ]
    [[ "$(jq -r .stats.url_effective <<<"$JSON_OUTPUT")" == "$URL"* ]]
    [ "$(jq -r ".headers[\"x-ywt-version\"]" <<<"$JSON_OUTPUT")" == "0.0.0-alpha.0" ]
    [ "$(jq -r ".response.data.userId" <<<"$JSON_OUTPUT")" == "1" ]
    [ "$(jq -r ".response.data.id" <<<"$JSON_OUTPUT")" == "1" ]
    [ "$(jq -r ".response.data.title" <<<"$JSON_OUTPUT")" == "delectus aut autem" ]
    [ "$(jq -r ".response.data.completed" <<<"$JSON_OUTPUT")" == "false" ]
    [ "$(jq -r .limit.max <<<"$JSON_OUTPUT")" == "1000" ]
    
}

# bats test_tags=sdk, fetch, get, httpbin
@test "ywt fetch get httpbin" {
    local URL="https://httpbin.org"
    run ywt fetch get "$URL"
    test_report
    assert_success "fetch get httpbin should be successful"
    assert_output --partial "$URL" 
    [ "$(jq -r .ok <<<"$JSON_OUTPUT")" == "true" ]
    [ "$(jq -r .json <<<"$JSON_OUTPUT")" == "false" ]
    [ "$(jq -r .status.status_code <<<"$JSON_OUTPUT")" == "200" ]
    [ "$(jq -r ".headers[\"x-ywt-version\"]" <<<"$JSON_OUTPUT")" == "0.0.0-alpha.0" ]
    [[ "$(jq -r .response.data <<<"$JSON_OUTPUT")" = *"<title>httpbin.org</title>"* ]]
    [[ "$(jq -r .stats.url_effective <<<"$JSON_OUTPUT")" == "$URL"* ]]
    [ "$(jq -r .limit.max <<<"$JSON_OUTPUT")" == "null" ]
}
# bats test_tags=sdk, fetch, usage
@test "ywt fetch should be called" {
    run ywt fetch
    test_report
    assert_success "fetch should be called"
    assert_output --partial "Available functions"
    assert_output --partial "YWT Usage"
}