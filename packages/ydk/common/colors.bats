#!/usr/bin/env bats
# bats file_tags=colors

# LIB_NAME=colors
# FILE_REALPATH=/workspace/rapd-shell/sdk/lib/colors.ywt.sh
# FILE_DIR=/workspace/rapd-shell/sdk/lib
# FILE_NAME=colors.ywt
# TEST_FILE=/workspace/rapd-shell/sdk/lib/colors.bats
# TEST_NAME=colors
# CMD_NAME=colors
# bats test_tags=colors, usage
@test "ywt colors should be called" {
  run ywt colors
  test_report
  assert_success "colors should be called"
  assert_output --partial "Available functions"
  assert_output --partial "YWT Usage"
}
