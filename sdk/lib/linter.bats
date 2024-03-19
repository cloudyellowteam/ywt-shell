#!/usr/bin/env bats
# bats file_tags=linter

# LIB_NAME=linter
# FILE_REALPATH=/workspace/rapd-shell/sdk/lib/linter.ywt.sh
# FILE_DIR=/workspace/rapd-shell/sdk/lib
# FILE_NAME=linter.ywt
# TEST_FILE=/workspace/rapd-shell/sdk/lib/linter.bats
# TEST_NAME=linter
# CMD_NAME=linter
# bats test_tags=linter, usage
@test "ywt linter should be called" {
  run ywt linter
  test_report
  assert_success "linter should be called"
  assert_output --partial "Available functions"
  assert_output --partial "YWT Usage"
}
