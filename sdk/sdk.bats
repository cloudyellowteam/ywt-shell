#!/usr/bin/env bats
# bats file_tags=sdk, cli

# bats test_tags=sdk:error-handler
@test "ywt handle error with usage" {
    run ywt invalid command
    test_report
    test_log "status=$status"
    [ "$status" -eq 0 ]
    [ "$output" != "" ]
    [ "$BATS_RUN_COMMAND" = "ywt invalid command" ]
    assert_output --partial "usage error (1): ywt"
    assert_output --partial "Available functions"
}

# bats test_tags=sdk:copyright
@test "ywt copyright" {
    run ywt copyright
    test_report
    test_log "status=$status"
    [ "$status" -eq 0 ]
    [ "$output" != "" ]
    [ "$BATS_RUN_COMMAND" = "ywt copyright" ]
    assert_output --partial "YELLOW TEAM BUNDLE"
}
# bats test_tags=sdk:appinfo
@test "ywt appinfo" {
    run ywt appinfo
    test_report
    test_log "status=$status"
    local JSON=$(test_extract_json "$output")
    [ "$status" -eq 0 ]
    [ "$output" != "" ]
    [ "$BATS_RUN_COMMAND" = "ywt appinfo" ]
    [ "$(jq .name -c <<< "$JSON")" != "null" ]
    [ "$(jq .version -c <<< "$JSON")" != "null" ]
    [ "$(jq .description -c <<< "$JSON")" != "null" ]
    [ "$(jq .author -c <<< "$JSON")" != "null" ]
    [ "$(jq .author.name -c <<< "$JSON")" != "Raphael Rego" ]
    [ "$(jq .author.email -c <<< "$JSON")" != "raphael@yellowteam.cloud" ]
    [ "$(jq .author.url -c <<< "$JSON")" != "https://raphaelcarlosr.dev" ]
    [ "$(jq .license -c <<< "$JSON")" != "MIT" ]
    [ "$(jq .homepage -c <<< "$JSON")" != "https://yellowteam.cloud" ]
    [ "$(jq .repository -c <<< "$JSON")" != "null" ]
    [ "$(jq .bugs -c <<< "$JSON")" != "null" ]

}
# bats test_tags=sdk:paths
@test "ywt paths" {
    run ywt paths
    test_report
    test_log "status=$status"
    local JSON=$(test_extract_json "$output")
    # test_log "$(jq . -c <<< "$JSON")"
    [ "$status" -eq 0 ]
    [ "$output" != "" ]
    [ "$(jq . -c <<< "$JSON")" != "null" ]
    [ "$(jq .cmd -c <<< "$JSON")" != "null" ]
    [ "$(jq .workspace -c <<< "$JSON")" != "null" ]
    [ "$(jq .project -c <<< "$JSON")" != "null" ]
    [ "$(jq .sdk -c <<< "$JSON")" != "null" ]
    [ "$(jq .lib -c <<< "$JSON")" != "null" ]
    [ "$(jq .src -c <<< "$JSON")" != "null" ]
    [ "$(jq .extensions -c <<< "$JSON")" != "null" ]
    [ "$(jq .packages -c <<< "$JSON")" != "null" ]
    [ "$(jq .scripts -c <<< "$JSON")" != "null" ]
    [ "$(jq .tools -c <<< "$JSON")" != "null" ]
    [ "$(jq .cli -c <<< "$JSON")" != "null" ]
    [ "$(jq .apps -c <<< "$JSON")" != "null" ]
    [ "$(jq .bin -c <<< "$JSON")" != "null" ]
    [ "$(jq .dist -c <<< "$JSON")" != "null" ]
    [ "$(jq .tmp -c <<< "$JSON")" != "null" ]
    [ "$(jq .logs -c <<< "$JSON")" != "null" ]
    [ "$(jq .cache -c <<< "$JSON")" != "null" ]
    [ "$(jq .data -c <<< "$JSON")" != "null" ]
    [ "$(jq .etc -c <<< "$JSON")" != "null" ]
    [ "$(jq .pwd -c <<< "$JSON")" != "null" ]
    
    [ "$BATS_RUN_COMMAND" = "ywt paths" ]
}
# bats test_tags=sdk:etime
@test "ywt etime" {
    run ywt etime
    test_report
    test_log "status=$status"
    [ "$status" -eq 0 ]
    [ "$output" != "" ]
    [ "$BATS_RUN_COMMAND" = "ywt etime" ]
}
# bats test_tags=sdk:inspect
@test "ywt inspect" {
    run ywt inspect
    test_report
    local JSON=$(test_extract_json "$output")
    test_log "status=$status"
    jq .yellowteam -c <<< "$JSON" | test_log
    # test_log "$(jq .yellowteam -c <<< "$JSON")"
    [ "$status" -eq 0 ]
    [ "$JSON" != "null" ]    
    # [ "$output" = *"@yw-team/yw-sh"* ]
    [ "$BATS_RUN_COMMAND" = "ywt inspect" ]
    assert_output --partial "@yw-team/yw-sh"
}