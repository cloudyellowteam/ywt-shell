#!/usr/bin/env bats
# bats file_tags=sdk, worker

# bats test_tags=sdk, worker, usage
@test "ywt worker should be called" {
    run ywt worker
    test_report
    assert_success "worker should be called"
    assert_output --partial "Available functions"
    assert_output --partial "YWT Usage"
}