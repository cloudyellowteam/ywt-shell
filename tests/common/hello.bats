#!/usr/bin/env bats
# bats test_tags=commom, template
@test "ywt inspect" {
    run ywt inspect
    test_report
    local JSON=$(echo "$output" | sed -n '/{/,$p' | jq -sR 'fromjson? | select(.)')
    test_log "status=$status"
    test_log "$(jq .yellowteam -c <<< "$JSON")"
    [ "$status" -eq 0 ]
    [ "$JSON" != "null" ]    
    # [ "$output" = *"@yw-team/yw-sh"* ]
    [ "$BATS_RUN_COMMAND" = "ywt inspect" ]
    assert_output --partial "@yw-team/yw-sh"
}

# bats test_tags=commom, template
@test "addition using bc" {
  result="$(echo 4)"
  [ "$result" -eq 4 ]
}

# bats test_tags=commom, template
@test "addition using dc" {
  result="$(echo 2)"
  [ "$result" -eq 2 ]
}

setup() {
    load "helpers/setup.sh" && test_setup
    FEATURE_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" >/dev/null 2>&1 && pwd)"
    PATH="$FEATURE_DIR:$PATH" # add feature to PATH
}




# @test "assert_output" {
#     run ywt inspect
#     # test_report
#     # test_log "$output" "status=$status"
#     [ "$status" -eq 0 ]
#     [ "$output" = "foo: no such file 'nonexistent_filename'" ]
#     [ "$BATS_RUN_COMMAND" = "foo nonexistent_filename" ]
#     # assert_output "have"
#     # # test_log "output: ${output}"

#     # test_report 1

#     # On failure, an error message is displayed.
#     # -- no output --
#     # expected non-empty output, but output was empty
#     # --
# }
