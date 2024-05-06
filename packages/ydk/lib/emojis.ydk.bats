
#!/usr/bin/env bats
# 🩳 ydk-shell@0.0.0-dev-0 sdk
# Source File: /workspace/rapd-shell/packages/ydk/lib/emojis.ydk.sh
# https://bats-core.readthedocs.io/en/stable/writing-tests.html#tagging-tests
# bats file_tags=ydk, emojis
# First test generated at Mon May  6 22:24:37 UTC 2024
# bats test_tags=ydk, emojis, initial
@test "emojis should be called" {
	run ydk emojis
	ydk:test:report
	# assert_success "emojis should be called"
	[[ "$status" -eq 1 ]]
	assert_output --partial "ydk-shell@"
	assert_output --partial "Usage: ydk"
}

