#!/usr/bin/env bash
# Shared helpers for config validation tests

REPO_ROOT="$BATS_TEST_DIRNAME/.."

require_jq() {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
}
