#!/usr/bin/env bats
# bats file_tags=spwan

# LIB_NAME=spwan
# FILE_REALPATH=/workspace/rapd-shell/sdk/lib/spwan.ywt.sh
# FILE_DIR=/workspace/rapd-shell/sdk/lib
# FILE_NAME=spwan.ywt
# TEST_FILE=/workspace/rapd-shell/sdk/lib/spwan.bats
# TEST_NAME=spwan
# CMD_NAME=spwan
# bats test_tags=spwan, usage
@test "ywt spwan should be called" {
  run ywt spwan
  test_report
  assert_success "spwan should be called"
  assert_output --partial "Available functions"
  assert_output --partial "YWT Usage"
}
