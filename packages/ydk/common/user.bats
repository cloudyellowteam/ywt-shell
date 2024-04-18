#!/usr/bin/env bats
# bats file_tags=user

# LIB_NAME=user
# FILE_REALPATH=/workspace/rapd-shell/sdk/lib/user.ywt.sh
# FILE_DIR=/workspace/rapd-shell/sdk/lib
# FILE_NAME=user.ywt
# TEST_FILE=/workspace/rapd-shell/sdk/lib/user.bats
# TEST_NAME=user
# CMD_NAME=user
# bats test_tags=user, usage
@test "ywt user should be called" {
  run ywt user
  test_report
  assert_success "user should be called"
  assert_output --partial "Available functions"
  assert_output --partial "YWT Usage"
}
