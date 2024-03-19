#!/usr/bin/env bats
# bats file_tags=scap

# LIB_NAME=scap
# FILE_REALPATH=/workspace/rapd-shell/sdk/lib/scap.ywt.sh
# FILE_DIR=/workspace/rapd-shell/sdk/lib
# FILE_NAME=scap.ywt
# TEST_FILE=/workspace/rapd-shell/sdk/lib/scap.bats
# TEST_NAME=scap
# CMD_NAME=scap
# bats test_tags=scap, usage
@test "ywt scap should be called" {
  run ywt scap
  test_report
  assert_success "scap should be called"
  assert_output --partial "Available functions"
  assert_output --partial "YWT Usage"
}
