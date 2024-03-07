#!/usr/bin/env bats
function setup() {
    echo "setup"
    # load '../../.bin/test_helper/bats-support/load'
    # load '../../.bin/test_helper/bats-assert/load'
    FEATURE_DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    PATH="$FEATURE_DIR:$PATH" # add feature to PATH
}
@test 'assert_output() check for existence' {
    run echo 'have'
    assert_output

    # On failure, an error message is displayed.
    # -- no output --
    # expected non-empty output, but output was empty
    # --
}


