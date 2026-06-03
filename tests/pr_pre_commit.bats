#!/usr/bin/env bats
# Tests for .pre-commit-config.yaml

load helpers

PRE_COMMIT_CONFIG="$REPO_ROOT/.pre-commit-config.yaml"

@test ".pre-commit-config.yaml exists" {
    [ -f "$PRE_COMMIT_CONFIG" ]
}

@test ".pre-commit-config.yaml is valid YAML (bash syntax check via grep structure)" {
    run grep -c "^repos:" "$PRE_COMMIT_CONFIG"
    [ "$status" -eq 0 ]
    [ "$output" -ge 1 ]
}

@test ".pre-commit-config.yaml references mirrors-oxfmt repo" {
    run grep -F "oxc-project/mirrors-oxfmt" "$PRE_COMMIT_CONFIG"
    [ "$status" -eq 0 ]
}

@test ".pre-commit-config.yaml uses oxfmt rev v0.51.0" {
    run grep -F "v0.51.0" "$PRE_COMMIT_CONFIG"
    [ "$status" -eq 0 ]
}

@test ".pre-commit-config.yaml has oxfmt hook id" {
    run grep -F "id: oxfmt" "$PRE_COMMIT_CONFIG"
    [ "$status" -eq 0 ]
}

@test ".pre-commit-config.yaml does not reference mirrors-prettier" {
    run grep -F "mirrors-prettier" "$PRE_COMMIT_CONFIG"
    [ "$status" -ne 0 ]
}

@test ".pre-commit-config.yaml does not have prettier hook id" {
    run grep -E "^\s+- id: prettier$" "$PRE_COMMIT_CONFIG"
    [ "$status" -ne 0 ]
}

@test ".pre-commit-config.yaml still contains pre-commit-hooks repo" {
    run grep -F "pre-commit/pre-commit-hooks" "$PRE_COMMIT_CONFIG"
    [ "$status" -eq 0 ]
}

@test ".pre-commit-config.yaml still contains check-yaml hook" {
    run grep -F "id: check-yaml" "$PRE_COMMIT_CONFIG"
    [ "$status" -eq 0 ]
}

@test ".pre-commit-config.yaml does not define types_or for oxfmt" {
    run grep -F "types_or" "$PRE_COMMIT_CONFIG"
    [ "$status" -ne 0 ]
}
