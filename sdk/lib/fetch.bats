#!/usr/bin/env bats
# bats file_tags=sdk, fetch
# bats test_tags=sdk, fetch, usage
@test "ywt fetch should be called" {
    run ywt fetch
    test_report
    assert_success "fetch should be called"
    assert_output --partial "Available functions"
    assert_output --partial "YWT Usage"
}