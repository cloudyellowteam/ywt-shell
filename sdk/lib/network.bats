#!/usr/bin/env bats
# bats file_tags=network

# LIB_NAME=network
# FILE_REALPATH=/workspace/rapd-shell/sdk/lib/network.ywt.sh
# FILE_DIR=/workspace/rapd-shell/sdk/lib
# FILE_NAME=network.ywt
# TEST_FILE=/workspace/rapd-shell/sdk/lib/network.bats
# TEST_NAME=network
# CMD_NAME=network
# bats test_tags=network, usage
@test "ywt network should be called" {
  run ywt network
  test_report
  assert_success "network should be called"
  assert_output --partial "Available functions"
  assert_output --partial "YWT Usage"
}
