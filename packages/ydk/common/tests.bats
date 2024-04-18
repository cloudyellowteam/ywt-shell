#!/usr/bin/env bats
# bats file_tags=tests

# LIB_NAME=tests
# FILE_REALPATH=/workspace/rapd-shell/sdk/lib/tests.ywt.sh
# FILE_DIR=/workspace/rapd-shell/sdk/lib
# FILE_NAME=tests.ywt
# TEST_FILE=/workspace/rapd-shell/sdk/lib/tests.bats
# TEST_NAME=tests
# CMD_NAME=tests
# bats test_tags=tests, usage
@test "ywt tests should be called" {
  run ywt tests
  test_report
  assert_success "tests should be called"
  assert_output --partial "Available functions"
  assert_output --partial "YWT Usage"
}
