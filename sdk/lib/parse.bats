#!/usr/bin/env bats
# bats file_tags=parse

# LIB_NAME=parse
# FILE_REALPATH=/workspace/rapd-shell/sdk/lib/parse.ywt.sh
# FILE_DIR=/workspace/rapd-shell/sdk/lib
# FILE_NAME=parse.ywt
# TEST_FILE=/workspace/rapd-shell/sdk/lib/parse.bats
# TEST_NAME=parse
# CMD_NAME=parse
# bats test_tags=parse, usage
@test "ywt parse should be called" {
  run ywt parse
  test_report
  assert_success "parse should be called"
  assert_output --partial "Available functions"
  assert_output --partial "YWT Usage"
}
