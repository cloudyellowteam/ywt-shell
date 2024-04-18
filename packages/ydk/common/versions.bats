#!/usr/bin/env bats
# bats file_tags=version

# LIB_NAME=version
# FILE_REALPATH=/workspace/rapd-shell/sdk/lib/version.ywt.sh
# FILE_DIR=/workspace/rapd-shell/sdk/lib
# FILE_NAME=version.ywt
# TEST_FILE=/workspace/rapd-shell/sdk/lib/version.bats
# TEST_NAME=version
# CMD_NAME=version
# bats test_tags=version, usage
@test "ywt versions should be called" {
  run ywt versions
  test_report
  assert_success "version should be called"
  assert_output --partial "Available functions"
  assert_output --partial "YWT Usage"
}
