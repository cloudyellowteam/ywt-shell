#!/usr/bin/env bats
# bats file_tags=envsubst

# LIB_NAME=envsubst
# FILE_REALPATH=/workspace/rapd-shell/sdk/lib/envsubst.ywt.sh
# FILE_DIR=/workspace/rapd-shell/sdk/lib
# FILE_NAME=envsubst.ywt
# TEST_FILE=/workspace/rapd-shell/sdk/lib/envsubst.bats
# TEST_NAME=envsubst
# CMD_NAME=envsubst
# bats test_tags=envsubst, usage
@test "ywt envsubst should be called" {
  run ywt envsubst
  test_report
  assert_success "envsubst should be called"
  # assert_output --partial "Available functions"
  # assert_output --partial "YWT Usage"
}
