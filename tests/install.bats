#!/usr/bin/env bats
# Test suite for install.sh

@test "install.sh has inlined logging functions" {
    # Verify that logging functions are defined in install.sh
    grep -q "^log_info()" "$BATS_TEST_DIRNAME/../install.sh"
    grep -q "^log_success()" "$BATS_TEST_DIRNAME/../install.sh"
    grep -q "^log_error()" "$BATS_TEST_DIRNAME/../install.sh"
    grep -q "^log_warning()" "$BATS_TEST_DIRNAME/../install.sh"
}

@test "install.sh does not source lib/common.sh" {
    # Verify that install.sh does not try to source lib/common.sh
    ! grep -q "source.*lib/common.sh" "$BATS_TEST_DIRNAME/../install.sh"
}

@test "install.sh has color definitions" {
    # Verify that color definitions are present
    grep -q "RED=" "$BATS_TEST_DIRNAME/../install.sh"
    grep -q "GREEN=" "$BATS_TEST_DIRNAME/../install.sh"
}

@test "install.sh check_prerequisites function exists" {
    # Verify check_prerequisites is defined
    grep -q "^check_prerequisites()" "$BATS_TEST_DIRNAME/../install.sh"
}

@test "install.sh main function exists" {
    # Verify main function is defined
    grep -q "^main()" "$BATS_TEST_DIRNAME/../install.sh"
}

@test "install.sh syntax is valid" {
    # Check bash syntax
    bash -n "$BATS_TEST_DIRNAME/../install.sh"
}
