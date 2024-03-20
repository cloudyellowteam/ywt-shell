#!/usr/bin/env bats
# bats file_tags=sdk, domains
# bats test_tags=sdk, domains, usage
@test "ywt domains should be called" {
    run ywt domains
    test_report
    assert_success "domains should be called"
    assert_output --partial "Available functions"
    assert_output --partial "YWT Usage"
}