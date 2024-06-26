
#!/usr/bin/env bats
# 🩳 ydk-shell@0.0.0-dev-0 sdk
# Source File: /workspace/rapd-shell/packages/ydk/lib/usage.ydk.sh
# https://bats-core.readthedocs.io/en/stable/writing-tests.html#tagging-tests
# bats file_tags=ydk, usage
# First test generated at Mon May  6 22:24:38 UTC 2024
# bats test_tags=ydk, usage, initial
@test "usage should be called" {
	run ydk usage
	ydk:test:report
	assert_success "usage should be called"
	[[ "$status" -eq 0 ]]
	assert_output --partial "ydk-shell@"
	assert_output --partial "Need a help"
}

