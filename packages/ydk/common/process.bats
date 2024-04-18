#!/usr/bin/env bats
# bats file_tags=process

# LIB_NAME=process
# FILE_REALPATH=/workspace/rapd-shell/sdk/lib/process.ywt.sh
# FILE_DIR=/workspace/rapd-shell/sdk/lib
# FILE_NAME=process.ywt
# TEST_FILE=/workspace/rapd-shell/sdk/lib/process.bats
# TEST_NAME=process
# CMD_NAME=process
# bats test_tags=process, usage
@test "ywt process should be called" {
  run ywt process
  test_report
  assert_success "process should be called"
  assert_output --partial "Available functions"
  assert_output --partial "YWT Usage"
}
