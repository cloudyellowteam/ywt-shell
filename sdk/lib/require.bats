#!/usr/bin/env bats
# bats file_tags=sdk, require

# bats test_tags=sdk, require, usage
@test "ywt process should be called" {
  run ywt require
  test_report
  assert_success "process should be called"
  assert_output --partial "Available functions"
  assert_output --partial "YWT Usage"
}

# bats test_tags=sdk, require, dependencies
@test "ywt require deps" {
    run ywt require deps jq sudo
    test_report
    test_log "status=$status"    
    local JSON=$(test_extract_json "$output")
    [ "$status" -eq 0 ]
    [ "$output" != "" ]
    [ "$BATS_RUN_COMMAND" = "ywt require deps jq sudo" ]
    assert_output --partial "Missing dependencies: sudo"
}
