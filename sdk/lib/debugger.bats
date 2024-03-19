#!/usr/bin/env bats
# bats file_tags=debugger

# LIB_NAME=debugger
# FILE_REALPATH=/workspace/rapd-shell/sdk/lib/debugger.ywt.sh
# FILE_DIR=/workspace/rapd-shell/sdk/lib
# FILE_NAME=debugger.ywt
# TEST_FILE=/workspace/rapd-shell/sdk/lib/debugger.bats
# TEST_NAME=debugger
# CMD_NAME=debugger
# bats test_tags=debugger, usage
@test "ywt debugger should be called" {
  run ywt debugger
  test_report
  assert_success "debugger should be called"
  assert_output --partial "Available functions"
  assert_output --partial "YWT Usage"
}
