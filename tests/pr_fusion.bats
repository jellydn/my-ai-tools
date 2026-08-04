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
	run grep -F "Verification contract:" "$skill"
	[ "$status" -eq 0 ]
	run grep -F "interactive root then runs that exact command" "$skill"
	[ "$status" -eq 0 ]
	run grep -F "project-local skills under the task working directory" "$skill"
	[ "$status" -eq 0 ]
	run grep -F "plugin-owned lead thread IDs" "$skill"
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
	run grep -F "model: cursor-acp/cursor-grok-4.5-medium" "$lead"
	[ "$status" -eq 0 ]
	run grep -F "model: cursor-acp/auto" "$executor"
	[ "$status" -eq 0 ]
	run grep -F '    "*": ask' "$executor"
	[ "$status" -eq 0 ]
	run grep -F "SKILLS LOADED" "$executor"
	[ "$status" -eq 0 ]
	run grep -F "runtime may terminate the task when approval is denied" "$executor"
	[ "$status" -eq 0 ]
}

@test "Pi installs subagent support and defines enforced Fusion tool surfaces" {
	require_jq
	run jq -e '
		def package_source: if type == "object" then .source else . end;
		(.packages | map(package_source) | index("npm:@tintinweb/pi-subagents") != null)
	' "$REPO_ROOT/configs/pi/settings.json"
	[ "$status" -eq 0 ]
	run grep -F 'tools: "read, grep, find"' "$REPO_ROOT/configs/pi/agents/fusion-lead.md"
	[ "$status" -eq 0 ]
	run grep -F 'extensions: false' "$REPO_ROOT/configs/pi/agents/fusion-lead.md"
	[ "$status" -eq 0 ]
	run grep -F 'tools: "read, grep, find, write, edit, bash"' "$REPO_ROOT/configs/pi/agents/fusion-executor.md"
	[ "$status" -eq 0 ]
	run grep -F "extensions: false" "$REPO_ROOT/configs/pi/agents/fusion-executor.md"
	[ "$status" -eq 0 ]
	run grep -F "skills: false" "$REPO_ROOT/configs/pi/agents/fusion-executor.md"
	[ "$status" -eq 0 ]
	run grep -F "    external_directory: deny" "$REPO_ROOT/configs/pi/agents/fusion-executor.md"
	[ "$status" -eq 0 ]
	run grep -F "model: cursor/grok-4.5" "$REPO_ROOT/configs/pi/agents/fusion-lead.md"
	[ "$status" -eq 0 ]
	run grep -F "model: cursor/auto" "$REPO_ROOT/configs/pi/agents/fusion-executor.md"
	[ "$status" -eq 0 ]
	run grep -F "openai-codex/gpt-5.6-tera" "$REPO_ROOT/configs/pi/settings.json"
	[ "$status" -ne 0 ]
	run grep -F "omniroute/cu/auto" "$REPO_ROOT/configs/pi/settings.json"
	[ "$status" -ne 0 ]
	run jq -e '
		(.enabledModels | index("cursor/grok-4.5") != null) and
		(.enabledModels | index("cursor/auto") != null) and
		(.enabledModels | index("openai-codex/gpt-5.6-tera") == null) and
		(.enabledModels | index("omniroute/cu/auto") == null)
	' "$REPO_ROOT/configs/pi/settings.json"
	[ "$status" -eq 0 ]
	# Cross-file: agent model pins must resolve against enabledModels + models.json catalogue.
	local lead_model executor_model
	lead_model=$(sed -n 's/^model: //p' "$REPO_ROOT/configs/pi/agents/fusion-lead.md" | head -1)
	executor_model=$(sed -n 's/^model: //p' "$REPO_ROOT/configs/pi/agents/fusion-executor.md" | head -1)
	run jq -e --arg m "$lead_model" '.enabledModels | index($m) != null' "$REPO_ROOT/configs/pi/settings.json"
	[ "$status" -eq 0 ]
	run jq -e --arg m "$executor_model" '.enabledModels | index($m) != null' "$REPO_ROOT/configs/pi/settings.json"
	[ "$status" -eq 0 ]
	run jq -e --arg m "$executor_model" '
		($m | split("/")) as $parts
		| (.providers[$parts[0]] == null)
		  or (.providers[$parts[0]].models | map(.id) | index($parts[1]) != null)
	' "$REPO_ROOT/configs/pi/models.json"
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
	run jq -e '
		def package_source: if type == "object" then .source else . end;
		.theme == "custom" and
		([.packages[] | package_source] | index("npm:existing-package") != null) and
		([.packages[] | package_source] | index("npm:@tintinweb/pi-subagents") != null)
	' "$test_home/.pi/agent/settings.json"
	[ "$status" -eq 0 ]
	run jq -e '
		def package_source: if type == "object" then .source else . end;
		[.packages[] | select(package_source == "npm:@tintinweb/pi-subagents")] | length == 1
	' "$test_home/.pi/agent/settings.json"
	[ "$status" -eq 0 ]
	run find "$test_home/.pi/agent" -maxdepth 1 -name '.settings.json.my-ai-tools.*'
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

@test "Pi installer recognizes object-form package entries without duplicating them" {
	require_jq
	local test_home="$BATS_TEST_TMPDIR/pi-object-packages"
	mkdir -p "$test_home/.pi/agent"
	cat >"$test_home/.pi/agent/settings.json" <<'JSON'
{
  "theme": "custom",
  "packages": [
    {"source": "npm:@tintinweb/pi-subagents", "skills": []}
  ]
}
JSON

	run env HOME="$test_home" REPO_ROOT="$REPO_ROOT" bash -c '
		export DRY_RUN=false YES_TO_ALL=false VERBOSE=false
		source "$REPO_ROOT/cli.sh"
		copy_pi_configs
	'
	[ "$status" -eq 0 ]
	run jq -e '
		def package_source: if type == "object" then .source else . end;
		([.packages[] | select(package_source == "npm:@tintinweb/pi-subagents")] | length == 1) and
		([.packages[] | select(type == "object" and .source == "npm:@tintinweb/pi-subagents")] | length == 1) and
		([.packages[] | select(type == "string" and . == "npm:@tintinweb/pi-subagents")] | length == 0)
	' "$test_home/.pi/agent/settings.json"
	[ "$status" -eq 0 ]
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
	local watchdog="$REPO_ROOT/configs/amp/lib/fusion-watchdog.ts"
	[ -f "$watchdog" ]
	# Watchdog helper must NOT live in the plugins directory — Amp scans every
	# .ts file there as a standalone plugin, and the helper has no default
	# export, causing "Plugin must export a default function" crashes.
	[ ! -f "$REPO_ROOT/configs/amp/plugins/fusion-watchdog.ts" ]
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
	run grep -F 'event.tool === "fusion_executor"' "$plugin"
	[ "$status" -eq 0 ]
	run grep -F 'show: true' "$plugin"
	[ "$status" -ne 0 ]
	# agent.run() pattern — no manual createThread/show.
	run grep -F 'executor.run(' "$plugin"
	[ "$status" -eq 0 ]
	run grep -F 'parentThreadID: ctx.thread.id' "$plugin"
	[ "$status" -eq 0 ]
	run grep -F 'leadThreadIDs.add' "$plugin"
	[ "$status" -eq 0 ]
	run grep -F 'failedExecutorEnvelope' "$plugin"
	[ "$status" -eq 0 ]
	# Bounded eviction for lead thread IDs, active lead set, and agent cache.
	run grep -F 'evictOldest(leadThreadIDs)' "$plugin"
	[ "$status" -eq 0 ]
	run grep -F 'evictOldest(activeLeadThreadIDs)' "$plugin"
	[ "$status" -eq 0 ]
	run grep -F 'evictOldest(threadAgentCache)' "$plugin"
	[ "$status" -eq 0 ]
	# Watchdog module is a standalone tested utility — ExecutorWaitError lives there.
	run grep -F 'class ExecutorWaitError' "$watchdog"
	[ "$status" -eq 0 ]
	# Plugin imports the timeout constant from the watchdog module.
	run grep -F 'EXECUTOR_MAX_TIMEOUT_MS' "$plugin"
	[ "$status" -eq 0 ]
	# No custom watchdog race — agent.run() timeoutMs handles the absolute cap.
	# A Promise.race that can't cancel the losing promise leaves the executor
	# running in the background, so it was removed for safety.
	[ "$(grep -c 'createActivityWatchdog' "$plugin")" -eq 0 ]
	[ "$(grep -c 'Promise.race' "$plugin")" -eq 0 ]
	[ "$(grep -c 'watchdog.cleanup' "$plugin")" -eq 0 ]
	# Active lead tracking uses a Set (concurrent-safe) not a single variable.
	run grep -F 'activeLeadThreadIDs' "$plugin"
	[ "$status" -eq 0 ]
	run grep -F 'activeLeadThreadIDs.add' "$plugin"
	[ "$status" -eq 0 ]
	run grep -F 'activeLeadThreadIDs.delete' "$plugin"
	[ "$status" -eq 0 ]
	# No single-variable active-run state — concurrent leads must not overwrite.
	[ "$(grep -c 'activeRunLastActivity' "$plugin")" -eq 0 ]
	[ "$(grep -c 'activeRunInFlight' "$plugin")" -eq 0 ]
	[ "$(grep -c 'activeRunLeadThreadID' "$plugin")" -eq 0 ]
	# No split-state maps.
	[ "$(grep -c 'executorLifecycle' "$plugin")" -eq 0 ]
	[ "$(grep -c 'executorLastActivity' "$plugin")" -eq 0 ]
	[ "$(grep -c 'executorInFlight' "$plugin")" -eq 0 ]
	[ "$(grep -c 'ExecutorSession' "$plugin")" -eq 0 ]
	[ "$(grep -c 'evictClosedSessions' "$plugin")" -eq 0 ]
	# No manual lifecycle — use agent.run() instead.
	[ "$(grep -c 'createThread' "$plugin")" -eq 0 ]
	[ "$(grep -c 'thread.append' "$plugin")" -eq 0 ]
	[ "$(grep -c 'waitForResponse' "$plugin")" -eq 0 ]
	# MAX_RECOMMENDED_TASK_CHARS must be a plugin local, not in the watchdog module.
	run grep -F 'MAX_RECOMMENDED_TASK_CHARS' "$plugin"
	[ "$status" -eq 0 ]
	run grep -F 'MAX_RECOMMENDED_TASK_CHARS' "$watchdog"
	[ "$status" -ne 0 ]
	run grep -F 'MAX_COLLECTION_SIZE' "$plugin"
	[ "$status" -eq 0 ]
	run grep -F 'RETAIN_COUNT' "$plugin"
	[ "$status" -eq 0 ]
	[ "$(grep -c 'isKnownExecutor' "$plugin")" -eq 0 ]
	run sed -n '/const LEAD_TOOLS = \[/,/\] as const;/p' "$plugin"
	[ "$status" -eq 0 ]
	[[ "$output" != *"apply_patch"* ]]
	[[ "$output" != *"shell_command"* ]]
	[[ "$output" == *"Task"* ]]
	run sed -n '/const EXECUTOR_TOOLS = \[/,/\] as const;/p' "$plugin"
	[ "$status" -eq 0 ]
	[[ "$output" == *"shell_command"* ]]
	[[ "$output" == *"web_search"* ]]
	[[ "$output" == *"mcp__*"* ]]
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
	run grep -F 'project-local skill paths under the task working directory' "$pi_agent"
	[ "$status" -eq 0 ]
}

@test "installers copy all native Fusion adapters" {
	run grep -F 'safe_copy_dir "$SCRIPT_DIR/configs/opencode/agent"' "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
	run grep -F 'copy_config_file "$plugin_dir" "$HOME/.config/amp/plugins"' "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
	# Installer must copy shared library modules to a non-plugin directory.
	run grep -F 'safe_copy_dir "$SCRIPT_DIR/configs/amp/lib" "$HOME/.config/amp/lib"' "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
	run grep -F 'safe_copy_dir "$SCRIPT_DIR/configs/codex/agents"' "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
	run grep -F 'safe_copy_dir "$SCRIPT_DIR/configs/pi/agents"' "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
	run grep -F 'pi_settings_has_required_packages' "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
	run grep -F 'def get_source: if type == "object" then .source else . end' "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
}

@test "every TypeScript file in amp plugins exports a default function" {
	# Amp scans every .ts file in ~/.config/amp/plugins as a standalone plugin.
	# A module without a default export crashes with "Plugin must export a
	# default function". This regression guard ensures no helper modules are
	# accidentally placed in the plugins directory.
	for ts_file in "$REPO_ROOT"/configs/amp/plugins/*.ts; do
		[ -f "$ts_file" ]
		run grep -F 'export default function' "$ts_file"
		[ "$status" -eq 0 ]
	done
}

@test "Amp installer removes stale fusion-watchdog plugin during upgrades" {
	# Regression: fusion-watchdog.ts was relocated from plugins/ to lib/.
	# A stale copy in ~/.config/amp/plugins causes a plugin startup crash.
	# The installer must remove it during upgrades.
	run grep -F 'execute "rm -f' "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
	run grep -F 'stale_plugin' "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
}

@test "OpenCode ships open-cursor with cursor-acp provider and omnirouter/free default" {
	require_jq
	run jq -e '
		.model == "omnirouter/free" and
		.agent.explorer.model == "omnirouter/free" and
		.provider["cursor-acp"].options.baseURL == "http://127.0.0.1:32124/v1" and
		.provider["cursor-acp"].models.auto.name == "Auto" and
		.provider["cursor-acp"].models["cursor-grok-4.5-medium"].name == "Grok 4.5 Medium"
	' "$REPO_ROOT/configs/opencode/opencode.json"
	[ "$status" -eq 0 ]
	run grep -F 'opencode:install_open_cursor' "$REPO_ROOT/cli.sh"
	[ "$status" -eq 0 ]
	run grep -F 'install_open_cursor()' "$REPO_ROOT/lib/install.sh"
	[ "$status" -eq 0 ]
	run grep -F '@rama_nigg/open-cursor' "$REPO_ROOT/lib/install.sh"
	[ "$status" -eq 0 ]
}
