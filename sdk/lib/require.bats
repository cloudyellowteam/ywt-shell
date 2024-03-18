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
