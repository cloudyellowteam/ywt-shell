#!/usr/bin/env bats
# bats file_tags=upm

# LIB_NAME=upm
# FILE_REALPATH=/workspace/rapd-shell/sdk/lib/upm.ywt.sh
# FILE_DIR=/workspace/rapd-shell/sdk/lib
# FILE_NAME=upm.ywt
# TEST_FILE=/workspace/rapd-shell/sdk/lib/upm.bats
# TEST_NAME=upm
# CMD_NAME=upm
# bats test_tags=upm, usage
@test "ywt upm should be called" {
  run ywt upm
  test_report
  assert_success "upm should be called"
  assert_output --partial "Available functions"
  assert_output --partial "YWT Usage"
}
