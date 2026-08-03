// @amp-agent-mode {"key":"fusion","label":"Fusion"}

import type { PluginAPI } from "@ampcode/plugin";
import { createActivityWatchdog, EXECUTOR_MAX_TIMEOUT_MS, ExecutorWaitError } from "../lib/fusion-watchdog";

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

/**
 * One conceptual object — an executor session — stored as a single record.
 * This eliminates the split-state bug where activity/in-flight maps could be
 * LRU-evicted independently of the lifecycle map, causing the watchdog to
 * read stale data for a still-active executor.
 */
interface ExecutorSession {
	status: "active" | "closed";
	lastActivity: number;
	inFlight: Set<string>;
}

export default function fusionAgents(amp: PluginAPI) {
	// Exact thread IDs owned by this plugin instance. Name checks alone are not a unique principal.
	const leadThreadIDs = new Set<string>();
	// Single map for all executor session state — one eviction policy, no desync.
	const executors = new Map<string, ExecutorSession>();

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

	// Semantic eviction for executor sessions: never discard active executors.
	// Closed entries are purged first. If all remaining entries are active
	// and the collection still exceeds MAX_COLLECTION_SIZE, we leave them —
	// active executors will be purged naturally when they become closed via
	// closeExecutor(). Evicting active entries would break in-flight work.
	const evictClosedSessions = () => {
		if (executors.size <= MAX_COLLECTION_SIZE) return;
		for (const [key, session] of executors) {
			if (session.status === "closed") executors.delete(key);
		}
		// If still over the limit after purging closed entries, all remaining
		// entries are active. Do NOT evict them — they will be cleaned up
		// when they transition to closed via closeExecutor().
		if (executors.size > MAX_COLLECTION_SIZE) {
			console.warn(
				`[fusion] Executor map has ${executors.size} active entries (limit ${MAX_COLLECTION_SIZE}). All are active — deferring eviction until they close.`,
			);
		}
	};

	// Keep all collections bounded to prevent unbounded growth in long-lived sessions.
	const limitCollections = () => {
		evictOldest(leadThreadIDs);
		evictClosedSessions();
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

	const getSession = (threadID: string): ExecutorSession | undefined => executors.get(threadID);
	const isActiveExecutor = (threadID: string) => executors.get(threadID)?.status === "active";
	const isClosedExecutor = (threadID: string) => executors.get(threadID)?.status === "closed";

	// Refresh Map insertion order on touch so evictOldest preserves recently-active sessions.
	const touchSession = (threadID: string) => {
		const session = executors.get(threadID);
		if (session) {
			executors.delete(threadID);
			executors.set(threadID, session);
		}
	};

	const setLastActivity = (threadID: string, timestamp: number = Date.now()) => {
		const session = executors.get(threadID);
		if (session) {
			session.lastActivity = timestamp;
			touchSession(threadID);
		}
	};

	const addInFlight = (threadID: string, toolUseID: string) => {
		const session = executors.get(threadID);
		if (session) {
			session.inFlight.add(toolUseID);
			touchSession(threadID);
		}
	};

	const removeInFlight = (threadID: string, toolUseID: string) => {
		const session = executors.get(threadID);
		if (!session) return;
		session.inFlight.delete(toolUseID);
	};

	const hasInFlight = (threadID: string): boolean => {
		const session = executors.get(threadID);
		return session ? session.inFlight.size > 0 : false;
	};

	const setLifecycle = (threadID: string, status: ExecutorSession["status"]) => {
		const session = executors.get(threadID);
		if (session) {
			session.status = status;
			touchSession(threadID);
		}
	};

	const closeExecutor = (threadID: string) => {
		const session = executors.get(threadID);
		if (!session) return;
		session.status = "closed";
		session.inFlight.clear();
		// Keep lastActivity for diagnostics until the session is evicted.
		touchSession(threadID);
	};

	amp.on("tool.call", async (event) => {
		const threadID = event.thread.id;

		// 1. Fast-path: Track activity/in-flight and allow active executor tool calls immediately.
		if (isActiveExecutor(threadID)) {
			setLastActivity(threadID, Date.now());
			addInFlight(threadID, event.toolUseID);
			return { action: "allow" };
		}

		// 2. Fast-path: Reject closed/inactive executor tool calls immediately without lookups.
		if (isClosedExecutor(threadID)) {
			return {
				action: "reject-and-continue",
				message: "Fusion executor task is no longer active. Stop tool use and wait for a new delegated task.",
			};
		}

		// 3. Delegation checks for the fusion_executor tool.
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

		// 4. Fallback for orphaned or completed executor threads not in our active lifecycle map.
		if (!leadThreadIDs.has(threadID)) {
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

	// Track tool results for active executors as activity signals.
	// This catches long-running tool calls (shell_command, apply_patch) that
	// span multiple watchdog intervals — the result arrival proves the executor
	// is still making progress, not stuck.
	amp.on("tool.result", (event) => {
		const threadID = event.thread.id;
		if (isActiveExecutor(threadID)) {
			removeInFlight(threadID, event.toolUseID);
			setLastActivity(threadID, Date.now());
		}
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
			limitCollections();

			const thread = await executor.createThread({
				parentThreadID: ctx.thread.id,
				show: true,
			});
			const startTime = Date.now();
			executors.set(thread.id, {
				status: "active",
				lastActivity: startTime,
				inFlight: new Set(),
			});
			limitCollections();
			try {
				await thread.append([{ type: "user-message", content: task }]);

				// Activity-aware wait: race a single long-lived waitForResponse
				// against an independent activity watchdog. The watchdog checks
				// inactivity and max-wait deadlines on an interval and rejects
				// with a typed ExecutorWaitError. This avoids the two blockers
				// of the old polling approach:
				//  1. No regex matching of Amp's timeout error message — the
				//     watchdog owns all timeout classification.
				//  2. One continuous waitForResponse subscription — no missed
				//     responses between poll cycles.
				const watchdog = createActivityWatchdog(
					() => getSession(thread.id)?.lastActivity ?? startTime,
					() => hasInFlight(thread.id),
					startTime,
				);

				try {
					// Give waitForResponse a small grace period beyond the watchdog's
					// max-wait so the watchdog always fires first.
					const response = await Promise.race([
						thread.waitForResponse({ timeoutMs: EXECUTOR_MAX_TIMEOUT_MS + 5_000 }),
						watchdog.promise,
					]);
					return response.content
						.filter((block) => block.type === "text")
						.map((block) => block.text)
						.join("\n");
				} finally {
					watchdog.cleanup();
				}
			} catch (error) {
				try {
					await thread.cancel();
				} catch {
					// Late calls still fail closed through the closed-executor lifecycle.
				}
				const reason =
					error instanceof Error ? error.message : typeof error === "string" ? error : "Executor task failed or timed out.";
				let verification: string;
				if (error instanceof ExecutorWaitError) {
					verification =
						error.kind === "max-wait"
							? "max-wait timeout — executor was still active but exceeded the absolute time cap"
							: "inactivity timeout — executor had no tool activity and was cancelled";
				} else {
					verification = "failed — unresolved verification commands were not completed";
				}
				return failedExecutorEnvelope(reason, verification);
			} finally {
				closeExecutor(thread.id);
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
