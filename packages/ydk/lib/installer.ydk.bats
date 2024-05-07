
#!/usr/bin/env bats
# 🩳 ydk-shell@0.0.0-dev-0 sdk
# Source File: /workspace/rapd-shell/packages/ydk/lib/installer.ydk.sh
# https://bats-core.readthedocs.io/en/stable/writing-tests.html#tagging-tests
# bats file_tags=ydk, installer
# First test generated at Mon May  6 22:24:37 UTC 2024
# bats test_tags=ydk, installer, initial
@test "installer should be called" {
	run ydk installer
	ydk:test:report
	# assert_success "installer should be called"
	[[ "$status" -eq 252 ]]
	assert_output --partial "ydk-shell@"
	assert_output --partial "Need a help"
}

