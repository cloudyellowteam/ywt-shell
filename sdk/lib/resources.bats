#!/usr/bin/env bats
# bats file_tags=resources

# LIB_NAME=resources
# FILE_REALPATH=/workspace/rapd-shell/sdk/lib/resources.ywt.sh
# FILE_DIR=/workspace/rapd-shell/sdk/lib
# FILE_NAME=resources.ywt
# TEST_FILE=/workspace/rapd-shell/sdk/lib/resources.bats
# TEST_NAME=resources
# CMD_NAME=resources
# bats test_tags=resources, usage
@test "ywt resources should be called" {
  run ywt resources
  test_report
  assert_success "resources should be called"
  assert_output --partial "Available functions"
  assert_output --partial "YWT Usage"
}
