
#!/usr/bin/env bats
# 🩳 ydk-shell@0.0.0-dev-0 sdk
# Source File: /workspace/rapd-shell/packages/ydk/lib/docs.ydk.sh
# https://bats-core.readthedocs.io/en/stable/writing-tests.html#tagging-tests
# bats file_tags=ydk, docs
# First test generated at Wed May  8 15:37:14 UTC 2024
# bats test_tags=ydk, docs, initial
@test "docs should be called" {
	run ydk docs
	ydk:test:report
	# assert_success "docs should be called"
	[[ "$status" -eq 1 ]]
	assert_output --partial "ydk-shell@"
	assert_output --partial "Usage: ydk"
}

