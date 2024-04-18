#!/usr/bin/env bats
# bats file_tags=host

# LIB_NAME=host
# FILE_REALPATH=/workspace/rapd-shell/sdk/lib/host.ywt.sh
# FILE_DIR=/workspace/rapd-shell/sdk/lib
# FILE_NAME=host.ywt
# TEST_FILE=/workspace/rapd-shell/sdk/lib/host.bats
# TEST_NAME=host
# CMD_NAME=host
# bats test_tags=host, usage
@test "ywt host should be called" {
  run ywt host
  test_report
  assert_success "host should be called"
  assert_output --partial "Available functions"
  assert_output --partial "YWT Usage"
}
