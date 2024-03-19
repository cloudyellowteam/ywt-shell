#!/usr/bin/env bats
# bats file_tags=sdk, logger
# bats test_tags=sdk, logger, usage
@test "ywt logger should be called" {
  run ywt logger
  test_report
  assert_success "logger should be called"
  assert_output --partial "Available functions"
  assert_output --partial "YWT Usage"
}
# bats test_tags=sdk, logger, success
@test "logger success hello" {
    run ywt logger success "hello"
    test_report
    test_log "status=$status"
    [ "$status" -eq 0 ]
    [ "$output" != "" ]
    # [ "$BATS_RUN_COMMAND" *= "logger success" ]
    assert_output --partial "[YWT]"
    assert_output --partial "hello"
    assert_output --partial "[SUCCESS]"
}
# bats test_tags=sdk, logger, error
@test "logger error hello" {
    run ywt logger error "hello"
    test_report
    test_log "status=$status"
    [ "$status" -eq 0 ]
    [ "$output" != "" ]
    # [ "$BATS_RUN_COMMAND" *= "logger error" ]
    assert_output --partial "[YWT]"
    assert_output --partial "hello"
    assert_output --partial "[ERROR]"
}
# bats test_tags=sdk, logger, warn
@test "logger warn hello" {
    run ywt logger warn "hello"
    test_report
    test_log "status=$status"
    [ "$status" -eq 0 ]
    [ "$output" != "" ]
    # [ "$BATS_RUN_COMMAND" *= "logger warn" ]
    assert_output --partial "[YWT]"
    assert_output --partial "hello"
    assert_output --partial "[WARN ]"
}
# bats test_tags=sdk, logger, debug
@test "logger debug hello" {
    run ywt logger debug "hello"
    test_report
    test_log "status=$status"
    assert_success "status should be 0"
    [ "$output" != "" ]
    # [ "$BATS_RUN_COMMAND" *= "logger debug" ]
    # assert_output --partial "[YWT]"
    # assert_output --partial "hello"
    # assert_output --partial "[DEBUG]"
}
# bats test_tags=sdk, logger, info
@test "logger info hello" {
    run ywt logger info "hello"
    test_report
    test_log "status=$status"
    [ "$status" -eq 0 ]
    [ "$output" != "" ]
    # [ "$BATS_RUN_COMMAND" *= "logger info" ]
    assert_output --partial "[YWT]"
    assert_output --partial "hello"
    assert_output --partial "[INFO ]"
}