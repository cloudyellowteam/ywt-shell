#!/usr/bin/env bats
# bats file_tags=dotenv

# LIB_NAME=dotenv
# FILE_REALPATH=/workspace/rapd-shell/sdk/lib/dotenv.ywt.sh
# FILE_DIR=/workspace/rapd-shell/sdk/lib
# FILE_NAME=dotenv.ywt
# TEST_FILE=/workspace/rapd-shell/sdk/lib/dotenv.bats
# TEST_NAME=dotenv
# CMD_NAME=dotenv
# bats test_tags=dotenv, usage
@test "ywt dotenv should be called" {
  run ywt dotenv
  test_report
  assert_success "dotenv should be called"
  assert_output --partial "Available functions"
  assert_output --partial "YWT Usage"
}
