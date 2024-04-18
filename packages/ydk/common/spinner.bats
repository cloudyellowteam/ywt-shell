#!/usr/bin/env bats
# bats file_tags=spinner

# LIB_NAME=spinner
# FILE_REALPATH=/workspace/rapd-shell/sdk/lib/spinner.ywt.sh
# FILE_DIR=/workspace/rapd-shell/sdk/lib
# FILE_NAME=spinner.ywt
# TEST_FILE=/workspace/rapd-shell/sdk/lib/spinner.bats
# TEST_NAME=spinner
# CMD_NAME=spinner
# bats test_tags=spinner, usage
@test "ywt spinner should be called" {
  run ywt spinner
  test_report
  assert_success "spinner should be called"
  assert_output --partial "Available functions"
  assert_output --partial "YWT Usage"
}
