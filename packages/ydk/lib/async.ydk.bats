
#!/usr/bin/env bats
# 🩳 ydk-shell@0.0.0-dev-0 sdk
# Source File: /workspace/rapd-shell/packages/ydk/lib/async.ydk.sh
# https://bats-core.readthedocs.io/en/stable/writing-tests.html#tagging-tests
# bats file_tags=ydk, async
# First test generated at Mon May  6 22:24:36 UTC 2024
# bats test_tags=ydk, async, initial
@test "async should be called" {
	run ydk async "sleep 1; echo Task 1 completed" "sleep 2; echo Task 2 completed; exit 1"  "sleep 1; echo Task 3 completed"
	ydk:test:report
	assert_success "async should be called"
	[[ "$status" -eq 0 ]]
	assert_output --partial "ydk-shell@"
	assert_output --partial "Waiting for 3 commands to finish"
	assert_output --partial "sleep 1 of 3"
	assert_output --partial "sleep 2 of 3"
	assert_output --partial "sleep 3 of 3"
}

