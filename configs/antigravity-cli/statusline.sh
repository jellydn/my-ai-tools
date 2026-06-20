#!/bin/bash

set -e

payload="$(cat 2>/dev/null || true)"

json_get() {
	local query="$1"
	if [ -n "$payload" ] && command -v jq >/dev/null 2>&1; then
		jq -r "$query // empty" 2>/dev/null <<<"$payload" | head -n 1
	fi
}

settings_get() {
	local query="$1"
	local settings_file="$HOME/.gemini/antigravity-cli/settings.json"
	if [ -f "$settings_file" ] && command -v jq >/dev/null 2>&1; then
		jq -r "$query // empty" "$settings_file" 2>/dev/null | head -n 1
	fi
}

format_percent() {
	local value="$1"

	if [ -z "$value" ]; then
		return 0
	fi

	if [[ "$value" == *% ]]; then
		printf '%s\n' "$value"
		return 0
	fi

	if [[ "$value" =~ ^0\.[0-9]+$ ]]; then
		awk -v n="$value" 'BEGIN { printf "%d%%\n", n * 100 }'
		return 0
	fi

	printf '%s%%\n' "$value"
}

cwd="$(json_get '.cwd // .currentWorkingDirectory // .current_working_directory // .workspace.currentDirectory // .workspace.cwd // .workspace.path // .workspacePath // .workspace_dir')"
[ -z "$cwd" ] && cwd="$PWD"
cwd="${cwd#file://}"

workspace="$(basename "$cwd")"

branch=""
dirty=""
pr_number=""
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	branch="$(git -C "$cwd" branch --show-current 2>/dev/null || true)"
	if [ -n "$(git -C "$cwd" status --short 2>/dev/null)" ]; then
		dirty="*"
	fi
	if [ -n "$branch" ] && command -v gh >/dev/null 2>&1; then
		if command -v timeout >/dev/null 2>&1; then
			pr_number="$(timeout 3 gh pr view --json number -q '.number' 2>/dev/null || true)"
		else
			pr_number="$(gh pr view --json number -q '.number' 2>/dev/null || true)"
		fi
	fi
fi

model="$(json_get '.modelName // .currentModel // .activeModel // (if (.model | type) == "string" then .model else (.model.name // .model.displayName // .model.id) end)')"
[ -z "$model" ] && model="$(settings_get '.model')"

state="$(json_get '.state // .status // .agentState // .agent.state')"

context="$(json_get '.context.percentUsed // .context.usedPercent // .context.percentage // .tokenUsage.percentUsed // .tokenUsage.contextPercent // .contextPercentage // .usage.contextPercentage')"
context="$(format_percent "$context")"

parts=("$workspace")
[ -n "$branch" ] && parts+=("$branch$dirty")
[ -n "$pr_number" ] && parts+=("PR#$pr_number")
[ -n "$model" ] && parts+=("$model")
[ -n "$state" ] && parts+=("$state")
[ -n "$context" ] && parts+=("ctx $context")

line="${parts[0]}"
for part in "${parts[@]:1}"; do
	line="$line | $part"
done

printf '%s\n' "$line"
