#!/usr/bin/env bats
# bats file_tags=sdk, timezones

# bats test_tags=sdk, timezones, current
@test "ywt timezones current should be called" {
    run ywt timezones current
    test_report
    assert_success "current should be called"
    assert_output --partial "UTC"
}

# bats test_tags=sdk, timezones, list
@test "ywt timezones list should be called" {
    run ywt timezones list
    test_report
    assert_success "list should be called"
    # assert_output --partial "Available timezones"
    # assert_output --partial "YWT Usage"
}

# bats test_tags=sdk, timezones, usage
@test "ywt timezones should be called" {
    run ywt timezones
    test_report
    assert_success "timezones should be called"
    assert_output --partial "Available functions"
    assert_output --partial "YWT Usage"
}