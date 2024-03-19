#!/usr/bin/env bats
# bats file_tags=strings

# LIB_NAME=strings
# FILE_REALPATH=/workspace/rapd-shell/sdk/lib/strings.ywt.sh
# FILE_DIR=/workspace/rapd-shell/sdk/lib
# FILE_NAME=strings.ywt
# TEST_FILE=/workspace/rapd-shell/sdk/lib/strings.bats
# TEST_NAME=strings
# CMD_NAME=strings
# bats test_tags=strings, usage
@test "ywt strings should be called" {
  run ywt strings
  test_report
  assert_success "strings should be called"
  assert_output --partial "Available functions"
  assert_output --partial "YWT Usage"
}
