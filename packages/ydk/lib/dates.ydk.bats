
#!/usr/bin/env bats
# 🩳 ydk-shell@0.0.0-dev-0 sdk
# Source File: /workspace/rapd-shell/packages/ydk/lib/dates.ydk.sh
# https://bats-core.readthedocs.io/en/stable/writing-tests.html#tagging-tests
# bats file_tags=ydk, dates
# First test generated at Mon May  6 22:24:36 UTC 2024
# bats test_tags=ydk, dates, initial
@test "dates should be called" {
	run ydk dates
	ydk:test:report
	# assert_success "dates should be called"
	[[ "$status" -eq 1 ]]
	assert_output --partial "ydk-shell@"
	assert_output --partial "Usage: ydk"
}

