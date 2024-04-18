#!/usr/bin/env bats
# bats file_tags=sdk, tcp
# bats test_tags=sdk, tcp, usage
@test "ywt tcp should be called" {
    run ywt tcp
    test_report
    assert_success "tcp should be called"
    assert_output --partial "Available functions"
    assert_output --partial "YWT Usage"
}