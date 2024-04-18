#!/usr/bin/env bats
# bats file_tags=store

# LIB_NAME=store
# FILE_REALPATH=/workspace/rapd-shell/sdk/lib/store.ywt.sh
# FILE_DIR=/workspace/rapd-shell/sdk/lib
# FILE_NAME=store.ywt
# TEST_FILE=/workspace/rapd-shell/sdk/lib/store.bats
# TEST_NAME=store
# CMD_NAME=store
# bats test_tags=store, usage
@test "ywt store should be called" {
  run ywt store
  test_report
  assert_success "store should be called"
  assert_output --partial "Available functions"
  assert_output --partial "YWT Usage"
}
