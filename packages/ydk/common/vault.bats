#!/usr/bin/env bats
# bats file_tags=vault

# LIB_NAME=vault
# FILE_REALPATH=/workspace/rapd-shell/sdk/lib/vault.ywt.sh
# FILE_DIR=/workspace/rapd-shell/sdk/lib
# FILE_NAME=vault.ywt
# TEST_FILE=/workspace/rapd-shell/sdk/lib/vault.bats
# TEST_NAME=vault
# CMD_NAME=vault
# bats test_tags=vault, usage
@test "ywt vault should be called" {
  run ywt vault
  test_report
  assert_success "vault should be called"
  assert_output --partial "Available functions"
  assert_output --partial "YWT Usage"
}
