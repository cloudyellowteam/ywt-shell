#!/usr/bin/env bats
# bats file_tags=sdk, param

# bats test_tags=sdk, param, kv, validate
@test "ywt param kv validate should be called" {
    local PARAMS=$({
        ywt param kv -r -n key -- \
            --required --name key2 -- \
            --default value --required --name key3 -- \
            --default value --required --name key4 -- \
            --type number --default "fd1" --required --name key5 -- \
            --message "custom message" --type number --default 1 --required --name key6 -- \
            --required --name flag-value -- \
            --required --name flag -- \
            --default '{}' --type json --required --name jsons -- \
            --default "{}" --type json --required --name jsons2
    } | tail -n +2 | jq -c .) 
    test_log "$PARAMS"
    run ywt param validate "$PARAMS"
    test_report
    assert_success "param should be called"
    assert_output --partial "4 Invalid parameters"
    assert_output --partial "(--kv=key: empty) is required"
    assert_output --partial "(--kv=key2: empty) is required"
    assert_output --partial "(--kv=key5: fd1) must be a number"
    assert_output --partial "(--kv=flag: empty) is required"
}

# bats test_tags=sdk, param, kv, multiple
@test "ywt param kv should be called with multiple params" {
    run ywt param kv -r -n key -- \
        --required --name key2 -- \
        --default value --required --name key3 -- \
        --default value --required --name key4 -- \
        --type number --default "fd1" --required --name key5 -- \
        --message "custom message" --type number --default 1 --required --name key6 -- \
        --required --name flag-value -- \
        --required --name flag -- \
        --default '{}' --type json --required --name jsons -- \
        --default "{}" --type json --required --name jsons2
    test_report
    assert_success "param should be called"    
    [ "$(jq -r .key <<<"$JSON_OUTPUT")" != "" ]
    [ "$(jq -r .key.error <<<"$JSON_OUTPUT")" == "(--kv=key: empty) is required" ]
    [ "$(jq -r .key.message <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key.valid <<<"$JSON_OUTPUT")" == "false" ]
    [ "$(jq -r .key.name <<<"$JSON_OUTPUT")" == "key" ]
    [ "$(jq -r .key.default <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key.required <<<"$JSON_OUTPUT")" == "true" ]
    [ "$(jq -r .key.type <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key.store <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key.config <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key.from <<<"$JSON_OUTPUT")" == "raw" ]
    [ "$(jq -r .key.value <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key.values.config <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key.values.param <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key.values.flag <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key.values.env <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key.values.process <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key.values.store <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key.values.raw <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key2 <<<"$JSON_OUTPUT")" != "" ]
    [ "$(jq -r .key2.error <<<"$JSON_OUTPUT")" == "(--kv=key2: empty) is required" ]
    [ "$(jq -r .key2.message <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key2.valid <<<"$JSON_OUTPUT")" == "false" ]
    [ "$(jq -r .key2.name <<<"$JSON_OUTPUT")" == "key2" ]
    [ "$(jq -r .key2.default <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key2.required <<<"$JSON_OUTPUT")" == "true" ]
    [ "$(jq -r .key2.type <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key2.store <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key2.config <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key2.from <<<"$JSON_OUTPUT")" == "raw" ]
    [ "$(jq -r .key2.value <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key2.values.config <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key2.values.param <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key2.values.flag <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key2.values.env <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key2.values.process <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key2.values.store <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key2.values.raw <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key3 <<<"$JSON_OUTPUT")" != "" ]
    [ "$(jq -r .key3.error <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key3.message <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key3.valid <<<"$JSON_OUTPUT")" == "true" ]
    [ "$(jq -r .key3.name <<<"$JSON_OUTPUT")" == "key3" ]
    [ "$(jq -r .key3.default <<<"$JSON_OUTPUT")" == "value" ]
    [ "$(jq -r .key3.required <<<"$JSON_OUTPUT")" == "true" ]
    [ "$(jq -r .key3.type <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key3.store <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key3.config <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key3.from <<<"$JSON_OUTPUT")" == "default" ]
    [ "$(jq -r .key3.value <<<"$JSON_OUTPUT")" == "value" ]
    [ "$(jq -r .key3.values.config <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key3.values.param <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key3.values.flag <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key3.values.env <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key3.values.process <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key3.values.store <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key3.values.raw <<<"$JSON_OUTPUT")" == "value" ]
    [ "$(jq -r .key4 <<<"$JSON_OUTPUT")" != "" ]
    [ "$(jq -r .key4.error <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key4.message <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key4.valid <<<"$JSON_OUTPUT")" == "true" ]
    [ "$(jq -r .key4.name <<<"$JSON_OUTPUT")" == "key4" ]
    [ "$(jq -r .key4.default <<<"$JSON_OUTPUT")" == "value" ]
    [ "$(jq -r .key4.required <<<"$JSON_OUTPUT")" == "true" ]
    [ "$(jq -r .key4.type <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key4.store <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key4.config <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key4.from <<<"$JSON_OUTPUT")" == "default" ]
    [ "$(jq -r .key4.value <<<"$JSON_OUTPUT")" == "value" ]
    [ "$(jq -r .key4.values.config <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key4.values.param <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key4.values.flag <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key4.values.env <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key4.values.process <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key4.values.store <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key4.values.raw <<<"$JSON_OUTPUT")" == "value" ]
    [ "$(jq -r .key5.error <<<"$JSON_OUTPUT")" == "(--kv=key5: fd1) must be a number" ]
    [ "$(jq -r .key5.message <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key5.valid <<<"$JSON_OUTPUT")" == "false" ]
    [ "$(jq -r .key5.name <<<"$JSON_OUTPUT")" == "key5" ]
    [ "$(jq -r .key5.default <<<"$JSON_OUTPUT")" == "fd1" ]
    [ "$(jq -r .key5.required <<<"$JSON_OUTPUT")" == "true" ]
    [ "$(jq -r .key5.type <<<"$JSON_OUTPUT")" == "number" ]
    [ "$(jq -r .key5.store <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key5.config <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key5.from <<<"$JSON_OUTPUT")" == "default" ]
    [ "$(jq -r .key5.value <<<"$JSON_OUTPUT")" == "fd1" ]
    [ "$(jq -r .key5.values.config <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key5.values.param <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key5.values.flag <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key5.values.env <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key5.values.process <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key5.values.store <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key5.values.raw <<<"$JSON_OUTPUT")" == "fd1" ]
    [ "$(jq -r .key6 <<<"$JSON_OUTPUT")" != "" ]
    [ "$(jq -r .key6.error <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key6.message <<<"$JSON_OUTPUT")" == "custom message" ]
    [ "$(jq -r .key6.valid <<<"$JSON_OUTPUT")" == "true" ]
    [ "$(jq -r .key6.name <<<"$JSON_OUTPUT")" == "key6" ]
    [ "$(jq -r .key6.default <<<"$JSON_OUTPUT")" == "1" ]
    [ "$(jq -r .key6.required <<<"$JSON_OUTPUT")" == "true" ]
    [ "$(jq -r .key6.type <<<"$JSON_OUTPUT")" == "number" ]
    [ "$(jq -r .key6.store <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key6.config <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key6.from <<<"$JSON_OUTPUT")" == "default" ]
    [ "$(jq -r .key6.value <<<"$JSON_OUTPUT")" == "1" ]
    [ "$(jq -r .key6.values.config <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key6.values.param <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key6.values.flag <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key6.values.env <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key6.values.process <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key6.values.store <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key6.values.raw <<<"$JSON_OUTPUT")" == "1" ]
    # [ "$(jq -r .['flag-value'] <<<"$JSON_OUTPUT")" != "" ]
    # [ "$(jq -r .['flag-value'].error <<<"$JSON_OUTPUT")" == "" ]
    # [ "$(jq -r .['flag-value'].message <<<"$JSON_OUTPUT")"== "custom message" ]
    # [ "$(jq -r .['flag-value'].valid <<<"$JSON_OUTPUT")" == "true" ]
    # [ "$(jq -r .['flag-value'].name <<<"$JSON_OUTPUT")" == "flag-value" ]
    # [ "$(jq -r .['flag-value'].default <<<"$JSON_OUTPUT")" == "" ]
    # [ "$(jq -r .['flag-value'].required <<<"$JSON_OUTPUT")" == "true" ]
    # [ "$(jq -r .['flag-value'].type <<<"$JSON_OUTPUT")" == "" ]
    # [ "$(jq -r .['flag-value'].store <<<"$JSON_OUTPUT")" == "" ]
    # [ "$(jq -r .['flag-value'].config <<<"$JSON_OUTPUT")" == "" ]
    # [ "$(jq -r .['flag-value'].from <<<"$JSON_OUTPUT")" == "config" ]
    # [ "$(jq -r .['flag-value'].value <<<"$JSON_OUTPUT")" == "-VALUE" ]
    # [ "$(jq -r .['flag-value'].values.config <<<"$JSON_OUTPUT")" == "-VALUE" ]
    # [ "$(jq -r .['flag-value'].values.param <<<"$JSON_OUTPUT")" == "" ]
    # [ "$(jq -r .['flag-value'].values.flag <<<"$JSON_OUTPUT")" == "" ]
    # [ "$(jq -r .['flag-value'].values.env <<<"$JSON_OUTPUT")" == "" ]
    # [ "$(jq -r .['flag-value'].values.process <<<"$JSON_OUTPUT")" == "" ]
    # [ "$(jq -r .['flag-value'].values.store <<<"$JSON_OUTPUT")" == "" ]
    # [ "$(jq -r .['flag-value'].values.raw <<<"$JSON_OUTPUT")" == "-VALUE" ]
    [ "$(jq -r .flag <<<"$JSON_OUTPUT")" != "" ]
    [ "$(jq -r .flag.error <<<"$JSON_OUTPUT")" == "(--kv=flag: empty) is required" ]
    [ "$(jq -r .flag.message <<<"$JSON_OUTPUT")" == "custom message" ]
    [ "$(jq -r .flag.valid <<<"$JSON_OUTPUT")" == "false" ]
    [ "$(jq -r .flag.name <<<"$JSON_OUTPUT")" == "flag" ]
    [ "$(jq -r .flag.default <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .flag.required <<<"$JSON_OUTPUT")" == "true" ]
    [ "$(jq -r .flag.type <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .flag.store <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .flag.config <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .flag.from <<<"$JSON_OUTPUT")" == "raw" ]
    [ "$(jq -r .flag.value <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .flag.values.config <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .flag.values.param <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .flag.values.flag <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .flag.values.env <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .flag.values.process <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .flag.values.store <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .flag.values.raw <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .jsons <<<"$JSON_OUTPUT")" != "" ]
    [ "$(jq -r .jsons.error <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .jsons.message <<<"$JSON_OUTPUT")" == "custom message" ]
    [ "$(jq -r .jsons.valid <<<"$JSON_OUTPUT")" == "true" ]
    [ "$(jq -r .jsons.name <<<"$JSON_OUTPUT")" == "jsons" ]
    [ "$(jq -r .jsons.default <<<"$JSON_OUTPUT")" == "{}" ]
    [ "$(jq -r .jsons.required <<<"$JSON_OUTPUT")" == "true" ]
    [ "$(jq -r .jsons.type <<<"$JSON_OUTPUT")" == "json" ]
    [ "$(jq -r .jsons.store <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .jsons.config <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .jsons.from <<<"$JSON_OUTPUT")" == "default" ]
    [ "$(jq -r .jsons.value <<<"$JSON_OUTPUT")" == "{}" ]
    [ "$(jq -r .jsons.values.config <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .jsons.values.param <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .jsons.values.flag <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .jsons.values.env <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .jsons.values.process <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .jsons.values.store <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .jsons.values.raw <<<"$JSON_OUTPUT")" == "{}" ]
    [ "$(jq -r .jsons2 <<<"$JSON_OUTPUT")" != "" ]
    [ "$(jq -r .jsons2.error <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .jsons2.message <<<"$JSON_OUTPUT")" == "custom message" ]
    [ "$(jq -r .jsons2.valid <<<"$JSON_OUTPUT")" == "true" ]
    [ "$(jq -r .jsons2.name <<<"$JSON_OUTPUT")" == "jsons2" ]
    [ "$(jq -r .jsons2.default <<<"$JSON_OUTPUT")" == "{}" ]
    [ "$(jq -r .jsons2.required <<<"$JSON_OUTPUT")" == "true" ]
    [ "$(jq -r .jsons2.type <<<"$JSON_OUTPUT")" == "json" ]
    [ "$(jq -r .jsons2.store <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .jsons2.config <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .jsons2.from <<<"$JSON_OUTPUT")" == "default" ]
    [ "$(jq -r .jsons2.value <<<"$JSON_OUTPUT")" == "{}" ]
    [ "$(jq -r .jsons2.values.config <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .jsons2.values.param <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .jsons2.values.flag <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .jsons2.values.env <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .jsons2.values.process <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .jsons2.values.store <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .jsons2.values.raw <<<"$JSON_OUTPUT")" == "{}" ]    
}

# bats test_tags=sdk, param, kv, error, non-validate
@test "ywt param kv with invalid params and non validate should be called" {
    run ywt param kv --required --name key2
    test_report
    assert_success "param should be called"
    [ "$(jq -r .key2.error <<<"$JSON_OUTPUT")" != "" ]
    [ "$(jq -r .key2.message <<<"$JSON_OUTPUT")" != "(--kv=key2: empty) is required" ]
    [ "$(jq -r .key2.valid <<<"$JSON_OUTPUT")" == "false" ]
    [ "$(jq -r .key2.name <<<"$JSON_OUTPUT")" == "key2" ]
    [ "$(jq -r .key2.default <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key2.required <<<"$JSON_OUTPUT")" == "true" ]
    [ "$(jq -r .key2.type <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key2.store <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key2.config <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key2.from <<<"$JSON_OUTPUT")" == "raw" ]
    [ "$(jq -r .key2.value <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key2.values.config <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key2.values.param <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key2.values.flag <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key2.values.env <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key2.values.process <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key2.values.store <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key2.values.raw <<<"$JSON_OUTPUT")" == "" ]
}

# bats test_tags=sdk, param, kv, error, validation
@test "ywt param kv with validate should be called" {
    run ywt param kv --validate --required --name key2
    test_report
    assert_success "param should be called"
    assert_output --partial "1 Invalid parameters"
    assert_output --partial "(--kv=key2: empty) is required"
}
# bats test_tags=sdk, param, kv
@test "ywt param kv should be called" {
    run ywt param kv --default value --required --name key3
    test_report
    assert_success "param should be called"
    [ "$(jq -r .key3 <<<"$JSON_OUTPUT")" != "" ]
    [ "$(jq -r .key3.error <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key3.message <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key3.valid <<<"$JSON_OUTPUT")" == "true" ]
    [ "$(jq -r .key3.name <<<"$JSON_OUTPUT")" == "key3" ]
    [ "$(jq -r .key3.default <<<"$JSON_OUTPUT")" == "value" ]
    [ "$(jq -r .key3.required <<<"$JSON_OUTPUT")" == "true" ]
    [ "$(jq -r .key3.type <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key3.store <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key3.config <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key3.from <<<"$JSON_OUTPUT")" == "default" ]
    [ "$(jq -r .key3.value <<<"$JSON_OUTPUT")" == "value" ]
    [ "$(jq -r .key3.values.config <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key3.values.param <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key3.values.flag <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key3.values.env <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key3.values.process <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key3.values.store <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .key3.values.raw <<<"$JSON_OUTPUT")" == "value" ]
}

# bats test_tags=sdk, param, get
@test "ywt param get should be called" {
    run ywt param get --default value --required --name key3
    test_report
    assert_success "param should be called"
    [ "$(jq -r .error <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .message <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .valid <<<"$JSON_OUTPUT")" == "true" ]
    [ "$(jq -r .name <<<"$JSON_OUTPUT")" == "key3" ]
    [ "$(jq -r .default <<<"$JSON_OUTPUT")" == "value" ]
    [ "$(jq -r .required <<<"$JSON_OUTPUT")" == "true" ]
    [ "$(jq -r .type <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .store <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .config <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .from <<<"$JSON_OUTPUT")" == "default" ]
    [ "$(jq -r .value <<<"$JSON_OUTPUT")" == "value" ]
    [ "$(jq -r .values.config <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .values.param <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .values.flag <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .values.env <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .values.process <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .values.store <<<"$JSON_OUTPUT")" == "" ]
    [ "$(jq -r .values.raw <<<"$JSON_OUTPUT")" == "value" ]
}

# bats test_tags=sdk, param, usage
@test "ywt param should be called" {
    run ywt param
    test_report
    assert_success "param should be called"
    assert_output --partial "Available functions"
    assert_output --partial "YWT Usage"
}
