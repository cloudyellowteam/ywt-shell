#!/usr/bin/env bats
# bats file_tags=errors

# LIB_NAME=errors
# FILE_REALPATH=/workspace/rapd-shell/sdk/lib/errors.ywt.sh
# FILE_DIR=/workspace/rapd-shell/sdk/lib
# FILE_NAME=errors.ywt
# TEST_FILE=/workspace/rapd-shell/sdk/lib/errors.bats
# TEST_NAME=errors
# CMD_NAME=errors
# bats test_tags=errors, usage
@test "ywt errors should be called" {
  run ywt errors
  test_report
  assert_success "errors should be called"
  assert_output --partial "Available functions"
  assert_output --partial "YWT Usage"
}
