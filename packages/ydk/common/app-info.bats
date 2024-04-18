#!/usr/bin/env bats
# bats file_tags=app-info

# LIB_NAME=app:info
# FILE_REALPATH=/workspace/rapd-shell/sdk/lib/app-info.ywt.sh
# FILE_DIR=/workspace/rapd-shell/sdk/lib
# FILE_NAME=app-info.ywt
# TEST_FILE=/workspace/rapd-shell/sdk/lib/app-info.bats
# TEST_NAME=app-info
# CMD_NAME=app-info
# bats test_tags=app-info, usage
@test "ywt app-info should be called" {
  run ywt app-info
  test_report
  assert_success "app:info should be called"
  assert_output --partial "Available functions"
  assert_output --partial "YWT Usage"
}
