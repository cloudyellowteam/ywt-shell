
#!/usr/bin/env bats
# 🩳 ydk-shell@0.0.0-dev-0 sdk
# Source File: /workspace/rapd-shell/packages/ydk/lib/hrml.ydk.sh
# https://bats-core.readthedocs.io/en/stable/writing-tests.html#tagging-tests
# bats file_tags=ydk, hrml
# First test generated at Mon May  6 22:24:37 UTC 2024
# bats test_tags=ydk, hrml, initial
@test "hrml should be called" {
	run ydk hrml
	ydk:test:report
	# assert_success "hrml should be called"
	[[ "$status" -eq 1 ]]
	assert_output --partial "ydk-shell@"
	assert_output --partial "Usage: ydk"
}

