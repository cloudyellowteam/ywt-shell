#!/usr/bin/env bats
# bats file_tags=sdk, dates

# bats test_tags=sdk, dates, usage
@test "ywt dates should be called" {
    run ywt dates
    test_report
    assert_success "dates should be called"
    assert_output --partial "Available functions"
    assert_output --partial "YWT Usage"
}

# bats test_tags=sdk, dates, formats
@test "ywt dates formats should be called" {
    run ywt dates formats -d "2024-03-20T01:00:00+00:00"
    test_report
    assert_success "dates formats should be called"
    assert_output --partial "timestamp"
    assert_output --partial "iso"
    assert_output --partial "rfc3339"
}

# bats test_tags=sdk, dates, parse
@test "ywt dates parse should be called" {
    run ywt dates parse -d "2024-03-20T01:00:00+00:00"
    test_report
    assert_success "dates parse should be called"
    assert_output --partial "2024-03-20T01:00:00+00:00"
}


# bats test_tags=sdk, dates, add:year
@test "ywt dates add year should be called" {
    run ywt dates add -d "2024-03-20T01:00:00+00:00" -y 1
    test_report
    assert_success "dates add should be called"
    assert_output --partial "2025-03-20T01:00:0" #2+00:00"
}

# bats test_tags=sdk, dates, add:month
@test "ywt dates add month should be called" {
    run ywt dates add -d "2024-03-20T01:00:00+00:00" -m 1
    test_report
    assert_success "dates add should be called"
    assert_output --partial "2024-04-20T01:00:0" #2+00:00"
}

# bats test_tags=sdk, dates, add:day
@test "ywt dates add day should be called" {
    run ywt dates add -d "2024-03-20T01:00:00+00:00" -D 1
    test_report
    assert_success "dates add should be called"
    assert_output --partial "2024-03-21T01:00:02+00:0" #0"
}

# bats test_tags=sdk, dates, add:hour
@test "ywt dates add hour should be called" {
    run ywt dates add -d "2024-03-20T01:00:00+00:00" -h 1
    test_report
    assert_success "dates add should be called"
    assert_output --partial "2024-03-20T02:00:02+00:0" #0"
}

# bats test_tags=sdk, dates, add:minute
@test "ywt dates add minute should be called" {
    run ywt dates add -d "2024-03-20T01:00:00+00:00" -M 1
    test_report
    assert_success "dates add should be called"
    assert_output --partial "2024-03-20T01:01:02+00:0" #0"
}

# bats test_tags=sdk, dates, add:second
@test "ywt dates add second should be called" {
    run ywt dates add -d "2024-03-20T01:00:00+00:00" -s 1
    test_report
    assert_success "dates add should be called"
    assert_output --partial "2024-03-20T01:00:01+00:0" #0"
}

