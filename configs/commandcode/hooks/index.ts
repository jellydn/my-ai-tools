#!/usr/bin/env bun

import { checkGitCommand } from "./git-guard";
import type { PostToolUseHandler, PreToolUseHandler } from "./lib";
import { runHook } from "./lib";

const preToolUse: PreToolUseHandler = async (payload) => {
	// Command Code uses "shell" as the matcher, but tool_name is "shell_command"
	if (payload.tool_name !== "shell_command" && payload.tool_name !== "shell") {
		return {};
	}

	if (payload.tool_input) {
		const command = String((payload.tool_input as { command?: string }).command ?? "");

		const gitCheck = checkGitCommand(command);
		if (!gitCheck.allowed) {
			console.error(`❌ ${gitCheck.reason}`);
			return {
				continue: true,
				systemMessage: gitCheck.reason,
				hookSpecificOutput: {
					hookEventName: "PreToolUse" as const,
					permissionDecision: "deny" as const,
					permissionDecisionReason: gitCheck.reason,
				},
			};
		}

		if (command.includes("rm -rf /") || command.includes("rm -rf ~")) {
			console.error("❌ Dangerous command detected! Blocking execution.");
			return {
				continue: true,
				systemMessage: `Dangerous command detected: ${command}`,
				hookSpecificOutput: {
					hookEventName: "PreToolUse" as const,
					permissionDecision: "deny" as const,
					permissionDecisionReason: `Dangerous command detected: ${command}`,
				},
			};
		}
	}

	return {};
};

const postToolUse: PostToolUseHandler = async (_payload) => {
	return {};
};

// Run the hook with our handlers
runHook({
	preToolUse,
	postToolUse,
});
