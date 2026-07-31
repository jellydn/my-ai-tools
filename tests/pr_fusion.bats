#!/usr/bin/env bats

load helpers

@test "portable Fusion skill is valid and documents enforcement limits" {
	local skill="$REPO_ROOT/skills/orchestrating-fusion/SKILL.md"
	[ -f "$skill" ]
	run grep -F "name: orchestrating-fusion" "$skill"
	[ "$status" -eq 0 ]
	run grep -F "Prompt text is not a security boundary" "$skill"
	[ "$status" -eq 0 ]
	run grep -F "Include each exact \`SKILL.md\` path" "$skill"
	[ "$status" -eq 0 ]
	run grep -F "one targeted correction specification" "$skill"
	[ "$status" -eq 0 ]
	run grep -F "KEY LEARNINGS" "$skill"
	[ "$status" -eq 0 ]
}

@test "OpenCode Fusion lead is read-only and can only delegate named roles" {
	local lead="$REPO_ROOT/configs/opencode/agent/fusion-lead.md"
	local executor="$REPO_ROOT/configs/opencode/agent/fusion-executor.md"
	[ -f "$lead" ]
	[ -f "$executor" ]
	run grep -F "  edit: deny" "$lead"
	[ "$status" -eq 0 ]
	run grep -F "  bash: deny" "$lead"
	[ "$status" -eq 0 ]
	run grep -F "    fusion-executor: allow" "$lead"
	[ "$status" -eq 0 ]
	run grep -F "model: omniroute/paid" "$lead"
	[ "$status" -eq 0 ]
	run grep -F "model: omniroute/free" "$executor"
	[ "$status" -eq 0 ]
	run grep -F '    "*": ask' "$executor"
	[ "$status" -eq 0 ]
	run grep -F "SKILLS LOADED" "$executor"
	[ "$status" -eq 0 ]
}

@test "Pi installs subagent support and defines enforced Fusion tool surfaces" {
	require_jq
	run jq -e '.packages | index("npm:@tintinweb/pi-subagents") != null' "$REPO_ROOT/configs/pi/settings.json"
	[ "$status" -eq 0 ]
	run jq -e '.packages | index("npm:pi-permission-system") != null' "$REPO_ROOT/configs/pi/settings.json"
	[ "$status" -eq 0 ]
	run grep -F 'tools: "read, grep, find"' "$REPO_ROOT/configs/pi/agents/fusion-lead.md"
	[ "$status" -eq 0 ]
	run grep -F 'extensions: false' "$REPO_ROOT/configs/pi/agents/fusion-lead.md"
	[ "$status" -eq 0 ]
	run grep -F 'tools: "read, grep, find, write, edit, bash"' "$REPO_ROOT/configs/pi/agents/fusion-executor.md"
	[ "$status" -eq 0 ]
	run grep -F "    external_directory: deny" "$REPO_ROOT/configs/pi/agents/fusion-executor.md"
	[ "$status" -eq 0 ]
	run grep -F "model: openai-codex/gpt-5.6-tera" "$REPO_ROOT/configs/pi/agents/fusion-lead.md"
	[ "$status" -eq 0 ]
	run grep -F "model: omniroute/cu/auto" "$REPO_ROOT/configs/pi/agents/fusion-executor.md"
	[ "$status" -eq 0 ]
}

@test "Pi installer adds Fusion dependency to existing settings without replacing user config" {
	require_jq
	local test_home="$BATS_TEST_TMPDIR/pi-home"
	mkdir -p "$test_home/.pi/agent"
	cat >"$test_home/.pi/agent/settings.json" <<'JSON'
{"theme":"custom","packages":["npm:existing-package"]}
JSON

	run env HOME="$test_home" REPO_ROOT="$REPO_ROOT" bash -c '
		export DRY_RUN=false YES_TO_ALL=false VERBOSE=false
		source "$REPO_ROOT/cli.sh"
		copy_pi_configs
	'
	[ "$status" -eq 0 ]
	run jq -e '.theme == "custom" and (.packages | index("npm:existing-package") != null) and (.packages | index("npm:@tintinweb/pi-subagents") != null) and (.packages | index("npm:pi-permission-system") != null)' "$test_home/.pi/agent/settings.json"
	[ "$status" -eq 0 ]
	run jq -e '[.packages[] | select(. == "npm:@tintinweb/pi-subagents")] | length == 1' "$test_home/.pi/agent/settings.json"
	[ "$status" -eq 0 ]
	run find "$test_home/.pi/agent" -maxdepth 1 -name '.settings.json.my-ai-tools.*'
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

@test "Pi installer dry-run does not modify existing settings" {
	require_jq
	local test_home="$BATS_TEST_TMPDIR/pi-dry-run-home"
	mkdir -p "$test_home/.pi/agent"
	printf '%s\n' '{"theme":"custom","packages":[]}' >"$test_home/.pi/agent/settings.json"
	local before
	before=$(sha256sum "$test_home/.pi/agent/settings.json")

	run env HOME="$test_home" REPO_ROOT="$REPO_ROOT" bash -c '
		export DRY_RUN=true YES_TO_ALL=false VERBOSE=false
		source "$REPO_ROOT/cli.sh"
		copy_pi_configs
	'
	[ "$status" -eq 0 ]
	[ "$(sha256sum "$test_home/.pi/agent/settings.json")" = "$before" ]
	run find "$test_home/.pi/agent" -maxdepth 1 -name '.settings.json.my-ai-tools.*'
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

@test "Pi installer removes temporary settings after a merge failure" {
	require_jq
	local test_home="$BATS_TEST_TMPDIR/pi-invalid-home"
	mkdir -p "$test_home/.pi/agent"
	printf '%s\n' '{invalid json' >"$test_home/.pi/agent/settings.json"

	run env HOME="$test_home" REPO_ROOT="$REPO_ROOT" bash -c '
		export DRY_RUN=false YES_TO_ALL=false VERBOSE=false
		source "$REPO_ROOT/cli.sh"
		copy_pi_configs
	'
	[ "$status" -ne 0 ]
	run find "$test_home/.pi/agent" -maxdepth 1 -name '.settings.json.my-ai-tools.*'
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

@test "Codex Fusion roles use native TOML sandbox policies" {
	local lead="$REPO_ROOT/configs/codex/agents/fusion-lead.toml"
	local executor="$REPO_ROOT/configs/codex/agents/fusion-executor.toml"
	run grep -F 'sandbox_mode = "read-only"' "$lead"
	[ "$status" -eq 0 ]
	run grep -F 'sandbox_mode = "workspace-write"' "$executor"
	[ "$status" -eq 0 ]
	run grep -F 'model = "gpt-5.6-luna"' "$executor"
	[ "$status" -eq 0 ]
}

@test "Amp Fusion mode restricts lead tools and exposes executor delegation" {
	local plugin="$REPO_ROOT/configs/amp/plugins/fusion-agents.ts"
	run grep -F 'name: "fusion_executor"' "$plugin"
	[ "$status" -eq 0 ]
	run grep -F 'key: "fusion"' "$plugin"
	[ "$status" -eq 0 ]
	run grep -F '"fusion_executor",' "$plugin"
	[ "$status" -eq 0 ]
	run grep -F 'model: "amp/glm-5.2"' "$plugin"
	[ "$status" -eq 0 ]
	run grep -F 'model: "xai/grok-4.5"' "$plugin"
	[ "$status" -eq 0 ]
	run grep -F 'definition.name !== "fusion-executor"' "$plugin"
	[ "$status" -eq 0 ]
	run grep -F 'isSafeExecutorShellCommand(shell.command, shell.dir)' "$plugin"
	[ "$status" -eq 0 ]
	run grep -F 'await ctx.ui.confirm({' "$plugin"
	[ "$status" -eq 0 ]
	run grep -F 'amp.activeThread.current?.id !== event.thread.id' "$plugin"
	[ "$status" -eq 0 ]
	run grep -F 'show: true' "$plugin"
	[ "$status" -eq 0 ]
	run sed -n '/const LEAD_TOOLS = \[/,/\] as const;/p' "$plugin"
	[ "$status" -eq 0 ]
	[[ "$output" != *"apply_patch"* ]]
	[[ "$output" != *"shell_command"* ]]
}

@test "Amp executor shell policy only permits exact workspace verification commands" {
	local plugin="$REPO_ROOT/configs/amp/plugins/fusion-agents.ts"
	run npx --yes tsx@4.23.0 -e '
		(async () => {
			const { isSafeExecutorShellCommand: safe } = await import(`file://${process.argv[1]}`);
			if (!safe("git diff --check")) process.exit(1);
			if (!safe(" git diff --check ")) process.exit(2);
			if (safe("git diff --check && rm -rf /")) process.exit(3);
			if (safe("npm test")) process.exit(4);
			if (safe("git diff --check", "/tmp")) process.exit(5);
		})().catch((error) => {
			console.error(error);
			process.exit(6);
		});
	' "$plugin"
	[ "$status" -eq 0 ]
}

@test "OpenCode approval-gates and Pi root-mediates non-inspection verification" {
	local opencode_agent="$REPO_ROOT/configs/opencode/agent/fusion-executor.md"
	local pi_agent="$REPO_ROOT/configs/pi/agents/fusion-executor.md"
	for agent in "$opencode_agent" "$pi_agent"; do
		run grep -F '    "git diff --no-ext-diff --no-textconv": allow' "$agent"
		[ "$status" -eq 0 ]
		run grep -E '^    ".*\*.*": allow$' "$agent"
		[ "$status" -ne 0 ]
	done
	run grep -F '    "*": ask' "$opencode_agent"
	[ "$status" -eq 0 ]
	run grep -F '    "*": deny' "$pi_agent"
	[ "$status" -eq 0 ]
	run grep -F 'report VERIFICATION REQUIRED with the exact command' "$pi_agent"
	[ "$status" -eq 0 ]
}

@test "installers copy all native Fusion adapters" {
	run grep -F 'safe_copy_dir "$SCRIPT_DIR/configs/opencode/agent"' "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
	run grep -F 'copy_config_file "$plugin_dir" "$HOME/.config/amp/plugins"' "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
	run grep -F 'safe_copy_dir "$SCRIPT_DIR/configs/codex/agents"' "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
	run grep -F 'safe_copy_dir "$SCRIPT_DIR/configs/pi/agents"' "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
}
