#!/usr/bin/env bats
# bats file_tags=sdk, builder

# bats test_tags=sdk, builder, usage
@test "ywt builder should be called" {
  run ywt builder
  test_report
  assert_success "app:info should be called"
  assert_output --partial "Available functions"
  assert_output --partial "YWT Usage"
}

# bats test_tags=sdk, builder, build
@test "ywt builder sdk build" {
  skip "TODO"
  run ywt builder _build_sdk
  test_report
  test_log "status=$status"
  local JSON=$(test_extract_json "$output")
  [ -n "$JSON" ] # TODO
  [ "$status" -eq 0 ]
  [ "$output" != "" ]
  [ "$BATS_RUN_COMMAND" = "ywt builder _build_sdk" ]
  [ ! "$(jq . <<<"$JSON")" = "null" ]
}
# bats test_tags=sdk, builder, inspect
@test "ywt builder inspect" {
  run ywt builder inspect
  test_report
  test_log "status=$status"
  local JSON=$(test_extract_json "$output")
  [ "$status" -eq 0 ]
  [ "$output" != "" ]
  [ "$BATS_RUN_COMMAND" = "ywt builder inspect" ]
  [ ! "$(jq . <<<"$JSON")" = "null" ]
}
