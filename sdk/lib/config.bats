#!/usr/bin/env bats
# bats file_tags=config

# LIB_NAME=config
# FILE_REALPATH=/workspace/rapd-shell/sdk/lib/config.ywt.sh
# FILE_DIR=/workspace/rapd-shell/sdk/lib
# FILE_NAME=config.ywt
# TEST_FILE=/workspace/rapd-shell/sdk/lib/config.bats
# TEST_NAME=config
# CMD_NAME=config
# bats test_tags=config, usage
@test "ywt config should be called" {
  run ywt config
  test_report
  assert_success "config should be called"
  assert_output --partial "Available functions"
  assert_output --partial "YWT Usage"
}
