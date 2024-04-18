#!/usr/bin/env bats
# bats file_tags=styles

# LIB_NAME=styles
# FILE_REALPATH=/workspace/rapd-shell/sdk/lib/styles.ywt.sh
# FILE_DIR=/workspace/rapd-shell/sdk/lib
# FILE_NAME=styles.ywt
# TEST_FILE=/workspace/rapd-shell/sdk/lib/styles.bats
# TEST_NAME=styles
# CMD_NAME=styles
# bats test_tags=styles, usage
@test "ywt styles should be called" {
  run ywt styles
  test_report
  assert_success "styles should be called"
  assert_output --partial "Available functions"
  assert_output --partial "YWT Usage"
}
