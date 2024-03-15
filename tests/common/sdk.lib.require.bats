#!/usr/bin/env bats
# bats file_tags=sdk:require

# bats test_tags=sdk:require:dependencies
@test "ywt require dependencies" {
    run ywt require dependencies jq sudo
    test_report
    test_log "status=$status"    
    local JSON=$(test_extract_json "$output")
    [ "$status" -eq 0 ]
    [ "$output" != "" ]
    [ "$BATS_RUN_COMMAND" = "ywt require dependencies jq sudo" ]
    assert_output --partial "required sudo (command not found)"
}
setup() {
    load "helpers/setup.sh" && test_setup
    FEATURE_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
    PATH="$FEATURE_DIR:$PATH" # add feature to PATH
}
