#!/usr/bin/env bats
# bats file_tags=cache

# LIB_NAME=cache
# FILE_REALPATH=/workspace/rapd-shell/sdk/lib/cache.ywt.sh
# FILE_DIR=/workspace/rapd-shell/sdk/lib
# FILE_NAME=cache.ywt
# TEST_FILE=/workspace/rapd-shell/sdk/lib/cache.bats
# TEST_NAME=cache
# CMD_NAME=cache
# bats test_tags=cache, usage
@test "ywt cache should be called" {
  run ywt cache
  test_report
  assert_success "cache should be called"
  assert_output --partial "Available functions"
  assert_output --partial "YWT Usage"
}
