// @amp-agent-mode {"key":"fusion","label":"Fusion"}

import type { PluginAPI } from "@ampcode/plugin";
import { EXECUTOR_MAX_TIMEOUT_MS } from "../lib/fusion-watchdog";

/** Soft warning threshold for oversized task specifications (~2000 tokens). */
const MAX_RECOMMENDED_TASK_CHARS = 8000;

const LEAD_INSTRUCTIONS = `
You are the Fusion lead. Own interpretation, investigation, architecture, task decomposition, review, and final verification. You have no file mutation or shell tools. Delegate every implementation change through fusion_executor.

Send the executor a bounded specification with OBJECTIVE, FILES, INTERFACES, CONSTRAINTS, SKILLS, and VERIFICATION. Keep each specification concise and focused — never paste full PRDs or raw requirements verbatim; state self-contained objectives and list exact paths only for relevant skills. Gate the result by reading every claimed path or artifact and checking scope, symbols, exact verification outcomes, and loaded skills. Send at most one targeted correction, then stop with evidence if it still fails. Relay blocking questions without dropping or reordering options.

Do not broaden scope or delegate commits, pushes, deployments, destructive actions, or external side effects without explicit user approval.

Finish with the outcome, decisions, verification evidence, and unresolved gaps.
`;

const EXECUTOR_INSTRUCTIONS = `
You are the Fusion executor. Implement only the bounded specification from the lead. Read targets and every listed exact skill path before editing, preserve unrelated work, and match repository patterns. Do not redesign or broaden scope. Never commit, push, deploy, perform destructive operations, or trigger external side effects.

Persist requested artifacts before the final response and run requested checks directly. Never claim a check passed without its evidence. Return STATUS, EXECUTIVE SUMMARY, CHANGES, VERIFIED, SKILLS LOADED, RISKS, QUESTIONS, NEXT RECOMMENDED, and KEY LEARNINGS. Escalate missing interfaces, conflicting requirements, and consequential choices instead of guessing.
`;

const LEAD_TOOLS = [
	"Read",
	"finder",
	"librarian",
	"oracle",
	"read_web_page",
	"skill",
	"Task",
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
	"librarian",
	"oracle",
	"shell_command",
	"shell_command_status",
	"skill",
	"view_media",
	"web_search",
	"mcp__*",
] as const;

function failedExecutorEnvelope(reason: string, verification = "none"): string {
	return [
		"STATUS: failed",
		"EXECUTIVE SUMMARY: Fusion executor did not complete successfully.",
		"CHANGES: none",
		`VERIFIED: ${verification}`,
		"SKILLS LOADED: none",
		`RISKS: ${reason}`,
		"QUESTIONS: none",
		"NEXT RECOMMENDED: Inspect the failure, then resend one targeted correction specification if still needed.",
		"KEY LEARNINGS: Executor failures must surface as structured envelopes so the lead can gate without guessing.",
	].join("\n");
}

function isFusionLeadDefinition(definition: { kind: string; name?: string } | undefined | null): boolean {
	return definition?.kind === "agent-definition" && definition?.name === "fusion-lead";
}

function isFusionExecutorDefinition(definition: { kind: string; name?: string } | undefined | null): boolean {
	return definition?.kind === "agent-definition" && definition?.name === "fusion-executor";
}

export default function fusionAgents(amp: PluginAPI) {
	// Exact thread IDs owned by this plugin instance. Name checks alone are not a unique principal.
	const leadThreadIDs = new Set<string>();

	// Lead threads that currently have an executor run in flight. Uses a Set
	// (not a single variable) so concurrent Fusion leads don't overwrite each
	// other's state. When this set is empty, orphaned executor threads are
	// rejected to prevent background mutation after a run ends.
	const activeLeadThreadIDs = new Set<string>();

	// Cache thread agent definitions to avoid redundant database lookups.
	// @ampcode/plugin types are not bundled in this repo, so the cached value is
	// the narrow shape we actually read (.definition) rather than the full agent.
	type ThreadAgent = { definition?: { kind: string; name?: string } | null };
	const threadAgentCache = new Map<string, ThreadAgent>();

	// Bounded retention: once a collection exceeds MAX_COLLECTION_SIZE, drop the
	// oldest entries and keep the RETAIN_COUNT most recent. Map/Set iterate in
	// insertion order (oldest first), so evicting the leading indices preserves
	// active entries — evicting the tail would discard in-flight executors.
	const MAX_COLLECTION_SIZE = 1000;
	const RETAIN_COUNT = 200;

	const evictOldest = <K, V>(collection: Map<K, V> | Set<K>) => {
		if (collection.size <= MAX_COLLECTION_SIZE) return;
		const keys = Array.from(collection.keys());
		for (let i = 0; i < keys.length - RETAIN_COUNT; i++) {
			const key = keys[i];
			if (key !== undefined) collection.delete(key);
		}
	};

	const limitCollections = () => {
		evictOldest(leadThreadIDs);
		evictOldest(activeLeadThreadIDs);
		evictOldest(threadAgentCache);
	};

	const getThreadAgent = async (threadID: string): Promise<ThreadAgent> => {
		let agent = threadAgentCache.get(threadID);
		if (!agent) {
			agent = await amp.threads.get(threadID).agent();
			threadAgentCache.set(threadID, agent);
			limitCollections();
		}
		return agent;
	};

	amp.on("tool.call", async (event) => {
		const threadID = event.thread.id;

		// Delegation check: only the Fusion lead can call fusion_executor.
		if (event.tool === "fusion_executor") {
			if (leadThreadIDs.has(threadID)) {
				return { action: "allow" };
			}
			const caller = await getThreadAgent(threadID);
			const definition = caller?.definition;
			if (isFusionLeadDefinition(definition)) {
				leadThreadIDs.add(threadID);
				limitCollections();
				return { action: "allow" };
			}
			return {
				action: "reject-and-continue",
				message: "Only the Fusion lead can delegate to the Fusion executor.",
			};
		}

		// Reject orphaned fusion-executor threads when no run is active.
		// This prevents stale executor threads from making tool calls after
		// their run has ended or timed out.
		if (!leadThreadIDs.has(threadID) && activeLeadThreadIDs.size === 0) {
			const agent = await getThreadAgent(threadID);
			const definition = agent?.definition;
			if (isFusionExecutorDefinition(definition)) {
				return {
					action: "reject-and-continue",
					message: "Fusion executor task is no longer active. Stop tool use and wait for a new delegated task.",
				};
			}
		}

		return { action: "allow" };
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
			const task = typeof input?.task === "string" ? input.task.trim() : "";
			if (!task) return "Missing implementation specification.";
			if (task.length > MAX_RECOMMENDED_TASK_CHARS) {
				console.warn(
					`[fusion] Specification length (${task.length} chars) exceeds recommended maximum (${MAX_RECOMMENDED_TASK_CHARS} chars / ~2000 tokens). Consider decomposing into smaller tasks.`,
				);
			}
			const caller = await ctx.thread.agent();
			const definition = caller?.definition;
			if (!isFusionLeadDefinition(definition)) {
				return "Only the Fusion lead can delegate to the Fusion executor.";
			}
			leadThreadIDs.add(ctx.thread.id);
			activeLeadThreadIDs.add(ctx.thread.id);
			limitCollections();

			// Use agent.run() — the documented custom-subagent pattern. This
			// handles thread lifecycle internally and avoids the 30-second
			// thread.messages RPC timeout that the manual approach hits.
			// run()'s timeoutMs provides the 60-minute absolute cap.
			try {
				const result = await executor.run(task, {
					parentThreadID: ctx.thread.id,
					timeoutMs: EXECUTOR_MAX_TIMEOUT_MS,
				});
				return result.text;
			} catch (error) {
				const reason =
					error instanceof Error ? error.message : typeof error === "string" ? error : "Executor task failed or timed out.";
				const isTimeout = /timeout|timed out/i.test(reason);
				const verification = isTimeout
					? "timeout — executor exceeded the maximum wait"
					: "failed — unresolved verification commands were not completed";
				return failedExecutorEnvelope(reason, verification);
			} finally {
				activeLeadThreadIDs.delete(ctx.thread.id);
			}
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
