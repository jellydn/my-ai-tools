// @amp-agent-mode {"key":"fusion","label":"Fusion"}

import type { PluginAPI } from "@ampcode/plugin";

const LEAD_INSTRUCTIONS = `
You are the Fusion lead. Own interpretation, investigation, architecture, task decomposition, review, and final verification. You have no file mutation or shell tools. Delegate every implementation change through fusion_executor.

Send the executor a bounded specification with OBJECTIVE, FILES, INTERFACES, CONSTRAINTS, SKILLS, and VERIFICATION. List exact paths only for relevant skills. Gate the result by reading every claimed path or artifact and checking scope, symbols, exact verification outcomes, and loaded skills. Send at most one targeted correction, then stop with evidence if it still fails. Relay blocking questions without dropping or reordering options.

Do not broaden scope or delegate commits, pushes, deployments, destructive actions, or external side effects without explicit user approval.

Finish with the outcome, decisions, verification evidence, and unresolved gaps.
`;

const EXECUTOR_INSTRUCTIONS = `
You are the Fusion executor. Implement only the bounded specification from the lead. Read targets and every listed exact skill path before editing, preserve unrelated work, and match repository patterns. Do not redesign or broaden scope. Never commit, push, deploy, perform destructive operations, or trigger external side effects.

Persist requested artifacts before the final response, run requested checks, and return STATUS, EXECUTIVE SUMMARY, CHANGES, VERIFIED, SKILLS LOADED, RISKS, QUESTIONS, NEXT RECOMMENDED, and KEY LEARNINGS. Escalate missing interfaces, conflicting requirements, and consequential choices instead of guessing.
`;

const LEAD_TOOLS = [
	"Read",
	"finder",
	"librarian",
	"oracle",
	"read_web_page",
	"skill",
	"view_media",
	"web_search",
	"fusion_executor",
] as const;

const EXECUTOR_TOOLS = [
	"Read",
	"apply_patch",
	"create_file",
	"edit_file",
	"finder",
	"shell_command",
	"shell_command_status",
	"view_media",
] as const;

export function isSafeExecutorShellCommand(command: string, dir?: string): boolean {
	if (dir) return false;

	return new Set([
		"pwd",
		"git status --short",
		"git diff --check",
		"git diff --no-ext-diff --no-textconv",
		"git diff --cached --no-ext-diff --no-textconv",
	]).has(command.trim());
}

export default function fusionAgents(amp: PluginAPI) {
	amp.on("tool.call", async (event) => {
		const shell = amp.helpers.shellCommandFromToolCall(event);
		if (!shell) return { action: "allow" };

		const agent = await amp.threads.get(event.thread.id).agent();
		const definition = agent.definition;
		if (definition.kind !== "agent-definition" || definition.name !== "fusion-executor") {
			return { action: "allow" };
		}

		return isSafeExecutorShellCommand(shell.command, shell.dir)
			? { action: "allow" }
			: {
					action: "reject-and-continue",
					message: "Fusion executor shell policy rejected this command. Ask the user to run it explicitly.",
				};
	});

	const executor = amp.createAgent({
		name: "fusion-executor",
		model: "amp/glm-5.2",
		instructions: EXECUTOR_INSTRUCTIONS,
		tools: EXECUTOR_TOOLS,
		reasoningEffort: "medium",
		display: { label: "Fusion Executor", color: "#76946a" },
	});

	amp.registerTool({
		name: "fusion_executor",
		description: "Delegate one bounded implementation task to the Fusion executor.",
		inputSchema: {
			type: "object",
			properties: {
				task: { type: "string", description: "Bounded implementation specification." },
			},
			required: ["task"],
		},
		async execute(input, ctx) {
			const task = typeof input.task === "string" ? input.task.trim() : "";
			if (!task) return "Missing implementation specification.";

			const result = await executor.run(task, {
				parentThreadID: ctx.thread.id,
				timeoutMs: 20 * 60 * 1000,
			});
			return result.text;
		},
	});

	const lead = amp.createAgent({
		name: "fusion-lead",
		model: "xai/grok-4.5",
		instructions: LEAD_INSTRUCTIONS,
		tools: LEAD_TOOLS,
		reasoningEffort: "high",
		display: { label: "Fusion", color: "#7e9cd8" },
	});

	amp.registerAgentMode({
		key: "fusion",
		label: "Fusion",
		description: "Read-only lead delegates implementation to a focused executor",
		color: "#7e9cd8",
		agent: lead.definition,
	});
}
