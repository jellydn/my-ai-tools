#!/bin/bash
# Reasonix custom statusline script
# Receives JSON payload on stdin with keys like model, contextUsed, contextWindow, cwd

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
	local settings_file="$HOME/.reasonix/config.toml"
	if [ -f "$settings_file" ] && command -v python3 >/dev/null 2>&1; then
		FILEPATH="$settings_file" QUERY="$query" python3 -c '
import os, sys
try:
    import tomllib
except ImportError:
    import tomli as tomllib
try:
    with open(os.environ["FILEPATH"], "rb") as f:
        data = tomllib.load(f)
    keys = os.environ["QUERY"].strip(".").split(".")
    val = data
    for k in keys:
        val = val.get(k, {})
    if isinstance(val, (str, int, float)):
        print(val)
except Exception:
    pass
' 2>/dev/null | head -n 1
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
		git_dir="$(git -C "$cwd" rev-parse --git-dir 2>/dev/null || true)"
		if [ -n "$git_dir" ]; then
			case "$git_dir" in
				/*) ;;
				*) git_dir="$cwd/$git_dir" ;;
			esac
			cache_branch="${branch//\//_}"
			cache_file="$git_dir/reasonix-pr-cache-$cache_branch"
			if [ -n "$(find "$cache_file" -mmin -5 2>/dev/null)" ]; then
				pr_number="$(cat "$cache_file" 2>/dev/null || true)"
			else
				if command -v timeout >/dev/null 2>&1; then
					pr_number="$(timeout 3 gh pr view --json number -q '.number' 2>/dev/null || true)"
				else
					pr_number="$(gh pr view --json number -q '.number' 2>/dev/null || true)"
				fi
				printf '%s' "$pr_number" > "$cache_file" 2>/dev/null || true
			fi
		fi
	fi
fi

model="$(json_get '.model // .modelName // .currentModel // .activeModel')"
[ -z "$model" ] && model="$(settings_get 'default_model')"

context_used="$(json_get '.contextUsed // .context_used // .context.usedPercent // .contextPercentage')"
if [ -z "$context_used" ]; then
	used="$(json_get '.context_tokens // .tokensUsed // .used_tokens')"
	win="$(json_get '.contextWindow // .context_window // .max_tokens')"
	if [ -n "$used" ] && [ -n "$win" ] && [ "$win" -gt 0 ] 2>/dev/null; then
		context_used="$(awk -v u="$used" -v w="$win" 'BEGIN { printf "%.2f", u / w }')"
	fi
fi
context_str="$(format_percent "$context_used")"

parts=("$workspace")
[ -n "$branch" ] && parts+=("$branch$dirty")
[ -n "$pr_number" ] && parts+=("PR#$pr_number")
[ -n "$model" ] && parts+=("$model")
[ -n "$context_str" ] && parts+=("ctx $context_str")

line="${parts[0]}"
for part in "${parts[@]:1}"; do
	line="$line | $part"
done

printf '%s\n' "$line"
