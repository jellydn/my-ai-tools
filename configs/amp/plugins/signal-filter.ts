// @amp-plugin
// Signal Filter — intercepts Amp events to filter and control agent actions.
//
// This plugin demonstrates Amp's middleware capability: hooks that observe
// tool calls, inspect shell commands and modified files, and return decisions
// such as allow, reject-and-continue, modify, or synthesize.
//
// It also implements slash-command routing via agent.start interception.
// Messages starting with /openrouter, /clinepass, or /opencode are sent to
// the corresponding external provider; the response is injected as context
// for Amp's main agent to act on.
//
// This does NOT replace Amp's main model. Amp's PluginAIModelProvider is a
// closed list. Instead, Signal Filter adds a middleware layer around the
// agent loop: filtering actions, routing prompts, and auditing turns.
//
// Configuration:
//   amp.configuration stores { rules, provider, model } — set via commands.
//   API keys live in environment variables (see resolveEndpoint below).

import type { AgentStartResult, PluginAPI, ToolCall, ToolCallResult } from "@ampcode/plugin";

// ---------------------------------------------------------------------------
// Provider presets (shared with external-provider.ts for standalone operation)
// ---------------------------------------------------------------------------

const PROVIDER_PRESETS = {
	openrouter: {
		baseURL: "https://openrouter.ai/api/v1",
		keyEnv: "OPENROUTER_API_KEY",
		label: "OpenRouter",
		defaultModel: "anthropic/claude-sonnet-4-6",
	},
	clinepass: {
		baseURL: "https://api.cline.bot/api/v1",
		keyEnv: "CLINE_API_KEY",
		label: "ClinePass",
		defaultModel: "anthropic/claude-sonnet-4-6",
	},
	opencode: {
		baseURL: "https://api.opencode.ai/v1",
		keyEnv: "OPENCODE_API_KEY",
		label: "OpenCode",
		defaultModel: "anthropic/claude-sonnet-4-6",
	},
	custom: {
		baseURL: "",
		keyEnv: "EXTERNAL_API_KEY",
		label: "Custom",
		defaultModel: "",
	},
} as const;

type ProviderKey = keyof typeof PROVIDER_PRESETS;

// ---------------------------------------------------------------------------
// Filter rule types
// ---------------------------------------------------------------------------

/** A rule that matches a tool call and specifies what to do. */
interface FilterRule {
	/** Unique name for this rule. */
	name: string;
	/** What to match against. */
	match: {
		/** Tool name to match (e.g. "shell_command", "edit_file"). Empty = any tool. */
		tool?: string;
		/** Shell command pattern to block (regex). Only applies to shell_command tool. */
		commandPattern?: string;
		/** File path pattern to match (regex). Applies to file-modifying tools. */
		filePattern?: string;
	};
	/** Action to take when the rule matches. */
	action: "block" | "confirm";
	/** Human-readable reason shown to the agent and user. */
	reason: string;
}

interface SignalFilterConfig {
	rules: FilterRule[];
	/** Provider for slash-command routing. */
	provider: ProviderKey;
	/** Model ID for slash-command routing. */
	model: string;
	/** Whether to audit-log all tool calls to the plugin logger. */
	auditLog: boolean;
}

const DEFAULT_CONFIG: SignalFilterConfig = {
	rules: [
		{
			name: "block-rm-rf",
			match: { tool: "shell_command", commandPattern: "\\brm\\s+-rf?\\s+/" },
			action: "block",
			reason: "Recursive force-delete of root paths is blocked by Signal Filter.",
		},
		{
			name: "block-force-push",
			match: { tool: "shell_command", commandPattern: "git\\s+push.*--force|--force-with-lease" },
			action: "block",
			reason: "Force push is blocked by Signal Filter. Use a non-destructive push.",
		},
		{
			name: "block-git-reset-hard",
			match: { tool: "shell_command", commandPattern: "git\\s+reset\\s+--hard" },
			action: "block",
			reason: "Hard reset is blocked by Signal Filter. Ask the user before resetting.",
		},
	],
	provider: "openrouter",
	model: PROVIDER_PRESETS.openrouter.defaultModel,
	auditLog: false,
};

// ---------------------------------------------------------------------------
// External provider call (for slash-command routing)
// ---------------------------------------------------------------------------

function resolveEndpoint(config: SignalFilterConfig): { baseURL: string; apiKey: string } {
	const preset = PROVIDER_PRESETS[config.provider];
	const baseURL = process.env.EXTERNAL_BASE_URL?.trim() || preset.baseURL;
	const apiKey = process.env[preset.keyEnv]?.trim() || process.env.EXTERNAL_API_KEY?.trim() || "";
	if (!baseURL) {
		throw new Error(`No base URL for provider "${config.provider}". Set EXTERNAL_BASE_URL.`);
	}
	if (!apiKey) {
		throw new Error(`No API key. Set ${preset.keyEnv} or EXTERNAL_API_KEY.`);
	}
	return { baseURL, apiKey };
}

async function callExternal(
	config: SignalFilterConfig,
	prompt: string,
	system = "You are a helpful assistant answering concisely and accurately.",
): Promise<string> {
	const { baseURL, apiKey } = resolveEndpoint(config);
	const response = await fetch(`${baseURL}/chat/completions`, {
		method: "POST",
		headers: {
			Authorization: `Bearer ${apiKey}`,
			"Content-Type": "application/json",
			"HTTP-Referer": "https://github.com/jellydn/my-ai-tools",
			"X-Title": "amp-signal-filter",
		},
		body: JSON.stringify({
			model: config.model,
			messages: [
				{ role: "system", content: system },
				{ role: "user", content: prompt },
			],
			max_tokens: 4096,
			temperature: 0.3,
		}),
	});
	if (!response.ok) {
		const body = await response.text().catch(() => "");
		throw new Error(`External provider returned ${response.status}: ${body.slice(0, 500)}`);
	}
	const data = (await response.json()) as {
		choices?: Array<{ message?: { content?: string } }>;
	};
	const content = data.choices?.[0]?.message?.content;
	if (!content) throw new Error("External provider returned an empty response");
	return content;
}

// ---------------------------------------------------------------------------
// Filter logic
// ---------------------------------------------------------------------------

/** Extract the shell command string from a tool call, if applicable. */
function getShellCommand(amp: PluginAPI, event: ToolCall): string | null {
	const parsed = amp.helpers.shellCommandFromToolCall(event);
	return parsed?.command ?? null;
}

/** Extract file paths from a tool call, if applicable. */
function getModifiedFiles(amp: PluginAPI, event: ToolCall): string[] {
	const uris = amp.helpers.filesModifiedByToolCall(event);
	if (!uris) return [];
	return uris.map((uri) => {
		try {
			return amp.helpers.filePathFromURI(uri);
		} catch {
			return uri.toString();
		}
	});
}

/** Check if a rule matches a tool call. */
function ruleMatches(amp: PluginAPI, rule: FilterRule, event: ToolCall): boolean {
	// Tool name filter
	if (rule.match.tool && event.tool !== rule.match.tool) return false;

	// Shell command pattern
	if (rule.match.commandPattern) {
		const cmd = getShellCommand(amp, event);
		if (!cmd) return false;
		try {
			if (!new RegExp(rule.match.commandPattern, "i").test(cmd)) return false;
		} catch {
			return false;
		}
	}

	// File path pattern
	if (rule.match.filePattern) {
		const files = getModifiedFiles(amp, event);
		if (files.length === 0) return false;
		try {
			const regex = new RegExp(rule.match.filePattern, "i");
			if (!files.some((f) => regex.test(f))) return false;
		} catch {
			return false;
		}
	}

	return true;
}

/** Evaluate all rules against a tool call and return the first match. */
function evaluateRules(amp: PluginAPI, rules: FilterRule[], event: ToolCall): FilterRule | null {
	for (const rule of rules) {
		if (ruleMatches(amp, rule, event)) return rule;
	}
	return null;
}

// ---------------------------------------------------------------------------
// Config helpers
// ---------------------------------------------------------------------------

async function getConfig(amp: PluginAPI): Promise<SignalFilterConfig> {
	const stored = (await amp.configuration.get()) as Partial<SignalFilterConfig>;
	return {
		rules: stored.rules ?? DEFAULT_CONFIG.rules,
		provider: stored.provider ?? DEFAULT_CONFIG.provider,
		model: stored.model ?? DEFAULT_CONFIG.model,
		auditLog: stored.auditLog ?? DEFAULT_CONFIG.auditLog,
	};
}

// ---------------------------------------------------------------------------
// Slash command routing
// ---------------------------------------------------------------------------

/** Slash command prefixes that route to external providers. */
const SLASH_COMMANDS: Array<{ prefix: string; provider: ProviderKey; label: string }> = [
	{ prefix: "/openrouter", provider: "openrouter", label: "OpenRouter" },
	{ prefix: "/clinepass", provider: "clinepass", label: "ClinePass" },
	{ prefix: "/opencode", provider: "opencode", label: "OpenCode" },
];

// ---------------------------------------------------------------------------
// Plugin entry point
// ---------------------------------------------------------------------------

export default function (amp: PluginAPI) {
	amp.logger.log("signal-filter plugin initialized");

	// --- agent.start: slash-command routing + context injection -----------

	amp.on("agent.start", async (event, ctx) => {
		const message = event.message;

		// Check for slash-command routing
		for (const cmd of SLASH_COMMANDS) {
			if (!message.startsWith(cmd.prefix + " ")) continue;

			const prompt = message.slice(cmd.prefix.length + 1).trim();
			if (!prompt) {
				return {
					message: {
						content: `Usage: ${cmd.prefix} <prompt> — routes the prompt to ${cmd.label} and injects the response as context.`,
						display: true,
					},
				} satisfies AgentStartResult;
			}

			const config = await getConfig(amp);
			config.provider = cmd.provider;
			ctx.logger.log(`slash-command: ${cmd.prefix} → ${cmd.label}, model=${config.model}`);

			try {
				const response = await callExternal(config, prompt);
				return {
					message: {
						content: [
							`An external ${cmd.label} model (${config.model}) returned this response to "${prompt}":`,
							"",
							response,
							"",
							"Use this as guidance for the task. You are still the primary agent.",
						].join("\n"),
						display: true,
					},
				} satisfies AgentStartResult;
			} catch (error) {
				const msg = (error as Error).message;
				ctx.logger.log(`slash-command ${cmd.prefix} failed: ${msg}`);
				return {
					message: {
						content: `${cmd.label} request failed: ${msg}. Proceed without external guidance.`,
						display: true,
					},
				} satisfies AgentStartResult;
			}
		}

		// No slash command — let the turn proceed normally
	});

	// --- tool.call: filter rules ------------------------------------------

	amp.on("tool.call", async (event, ctx) => {
		const config = await getConfig(amp);

		// Optional audit logging
		if (config.auditLog) {
			const cmd = getShellCommand(amp, event);
			const files = getModifiedFiles(amp, event);
			ctx.logger.log(
				`tool.call: tool=${event.tool} cmd=${cmd ? `"${cmd.slice(0, 120)}"` : "n/a"} files=${files.length > 0 ? files.join(", ") : "none"}`,
			);
		}

		// Evaluate filter rules
		const matchedRule = evaluateRules(amp, config.rules, event);
		if (!matchedRule) {
			return { action: "allow" } satisfies ToolCallResult;
		}

		if (matchedRule.action === "block") {
			ctx.logger.log(`BLOCKED by rule "${matchedRule.name}": ${matchedRule.reason}`);
			return {
				action: "reject-and-continue",
				message: `Blocked by Signal Filter rule "${matchedRule.name}": ${matchedRule.reason}`,
			} satisfies ToolCallResult;
		}

		if (matchedRule.action === "confirm") {
			// For confirm rules, ask the user via UI if the thread is active
			const isActive = amp.activeThread.current?.id === event.thread.id;
			if (isActive) {
				const cmd = getShellCommand(amp, event);
				const files = getModifiedFiles(amp, event);
				const detail = cmd ? `Command: ${cmd}` : files.length > 0 ? `Files: ${files.join(", ")}` : event.tool;
				const confirmed = await ctx.ui.confirm({
					title: `Signal Filter: ${matchedRule.name}`,
					message: `${matchedRule.reason}\n\n${detail}\n\nAllow this action?`,
					confirmButtonText: "Allow",
				});
				if (!confirmed) {
					ctx.logger.log(`REJECTED by user for rule "${matchedRule.name}"`);
					return {
						action: "reject-and-continue",
						message: `User denied action blocked by Signal Filter rule "${matchedRule.name}": ${matchedRule.reason}`,
					} satisfies ToolCallResult;
				}
			}
			// Non-active threads or confirmed actions proceed
		}

		return { action: "allow" } satisfies ToolCallResult;
	});

	// --- tool.result: audit logging ---------------------------------------

	amp.on("tool.result", async (event, ctx) => {
		const config = await getConfig(amp);
		if (!config.auditLog) return;
		ctx.logger.log(`tool.result: tool=${event.tool} status=${event.status} error=${event.error ?? "none"}`);
	});

	// --- agent.end: turn audit --------------------------------------------

	amp.on("agent.end", async (event, ctx) => {
		const config = await getConfig(amp);
		if (!config.auditLog) return;
		ctx.logger.log(`agent.end: thread=${event.thread.id} status=${event.status} messages=${event.messages.length}`);
	});

	// --- Commands ---------------------------------------------------------

	amp.registerCommand(
		"signal-filter:show-rules",
		{
			title: "Show Rules",
			category: "Signal Filter",
			description: "Display all active filter rules.",
		},
		async (ctx) => {
			const config = await getConfig(amp);
			if (config.rules.length === 0) {
				await ctx.ui.notify("No filter rules configured.");
				return;
			}
			const lines = config.rules.map(
				(r, i) =>
					`${i + 1}. ${r.name} [${r.action}] — ${r.reason}` +
					(r.match.tool ? ` (tool: ${r.match.tool})` : "") +
					(r.match.commandPattern ? ` (cmd: /${r.match.commandPattern}/)` : "") +
					(r.match.filePattern ? ` (file: /${r.match.filePattern}/)` : ""),
			);
			await ctx.ui.notify(`Signal Filter rules:\n${lines.join("\n")}`);
		},
	);

	amp.registerCommand(
		"signal-filter:toggle-audit",
		{
			title: "Toggle Audit Log",
			category: "Signal Filter",
			description: "Enable or disable audit logging of all tool calls and agent turns.",
		},
		async (ctx) => {
			const config = await getConfig(amp);
			const newValue = !config.auditLog;
			await amp.configuration.update({ auditLog: newValue });
			await ctx.ui.notify(`Signal Filter audit logging ${newValue ? "enabled" : "disabled"}.`);
		},
	);

	amp.registerCommand(
		"signal-filter:add-rule",
		{
			title: "Add Rule",
			category: "Signal Filter",
			description: "Add a new filter rule interactively.",
		},
		async (ctx) => {
			const name = await ctx.ui.input({
				title: "Rule Name",
				helpText: "A unique name for this filter rule.",
				submitButtonText: "Add",
			});
			if (!name?.trim()) return;

			const action = await ctx.ui.select({
				title: "Rule Action",
				options: ["block", "confirm"],
				message: "Should this rule block the action or require confirmation?",
			});
			if (!action) return;

			const tool = await ctx.ui.input({
				title: "Tool Name (optional)",
				helpText: "Tool to match (e.g. shell_command, edit_file). Leave empty for any tool.",
				submitButtonText: "Save",
			});

			const commandPattern = await ctx.ui.input({
				title: "Command Pattern (optional)",
				helpText: "Regex pattern to match in shell commands. Leave empty to skip.",
				submitButtonText: "Save",
			});

			const filePattern = await ctx.ui.input({
				title: "File Pattern (optional)",
				helpText: "Regex pattern to match file paths. Leave empty to skip.",
				submitButtonText: "Save",
			});

			const reason = await ctx.ui.input({
				title: "Reason",
				helpText: "Human-readable reason shown when this rule triggers.",
				submitButtonText: "Save",
			});
			if (!reason?.trim()) return;

			const config = await getConfig(amp);
			const newRule: FilterRule = {
				name: name.trim(),
				match: {
					tool: tool?.trim() || undefined,
					commandPattern: commandPattern?.trim() || undefined,
					filePattern: filePattern?.trim() || undefined,
				},
				action: action as FilterRule["action"],
				reason: reason.trim(),
			};
			await amp.configuration.update({ rules: [...config.rules, newRule] });
			await ctx.ui.notify(`Rule "${name.trim()}" added.`);
		},
	);

	amp.registerCommand(
		"signal-filter:reset-rules",
		{
			title: "Reset Rules",
			category: "Signal Filter",
			description: "Reset filter rules to defaults.",
		},
		async (ctx) => {
			const confirmed = await ctx.ui.confirm({
				title: "Reset Rules?",
				message: "This will replace all custom rules with the default set.",
				confirmButtonText: "Reset",
			});
			if (!confirmed) return;
			await amp.configuration.update({ rules: DEFAULT_CONFIG.rules });
			await ctx.ui.notify("Signal Filter rules reset to defaults.");
		},
	);

	amp.registerCommand(
		"signal-filter:select-provider",
		{
			title: "Select Provider",
			category: "Signal Filter",
			description: "Choose the external provider for slash-command routing.",
		},
		async (ctx) => {
			const options = Object.entries(PROVIDER_PRESETS).map(([key, preset]) => `${key} (${preset.label})`);
			const selected = await ctx.ui.select({
				title: "Select External Provider",
				options,
				message: "Provider for /openrouter, /clinepass, /opencode slash commands.",
			});
			if (!selected) return;
			const provider = selected.split(" ")[0] as ProviderKey;
			if (!(provider in PROVIDER_PRESETS)) return;
			const preset = PROVIDER_PRESETS[provider];
			const current = await getConfig(amp);
			const model = current.provider === provider ? current.model : preset.defaultModel;
			await amp.configuration.update({ provider, model });
			await ctx.ui.notify(`Provider set to ${preset.label}, model: ${model}`);
		},
	);

	amp.registerCommand(
		"signal-filter:select-model",
		{
			title: "Select Model",
			category: "Signal Filter",
			description: "Set the model ID for slash-command routing.",
		},
		async (ctx) => {
			const current = await getConfig(amp);
			const model = await ctx.ui.input({
				title: "Model ID",
				helpText: "Model ID for the selected provider (e.g. anthropic/claude-sonnet-4-6).",
				initialValue: current.model,
				submitButtonText: "Save",
			});
			if (!model?.trim()) return;
			await amp.configuration.update({ model: model.trim() });
			await ctx.ui.notify(`Model set to: ${model.trim()}`);
		},
	);
}
