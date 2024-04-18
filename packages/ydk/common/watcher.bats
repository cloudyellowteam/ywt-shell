#!/usr/bin/env bats
# bats file_tags=watcher

# LIB_NAME=watcher
# FILE_REALPATH=/workspace/rapd-shell/sdk/lib/watcher.ywt.sh
# FILE_DIR=/workspace/rapd-shell/sdk/lib
# FILE_NAME=watcher.ywt
# TEST_FILE=/workspace/rapd-shell/sdk/lib/watcher.bats
# TEST_NAME=watcher
# CMD_NAME=watcher
# bats test_tags=watcher, usage
@test "ywt watcher should be called" {
  run ywt watcher
  test_report
  assert_success "watcher should be called"
  assert_output --partial "Available functions"
  assert_output --partial "YWT Usage"
}
