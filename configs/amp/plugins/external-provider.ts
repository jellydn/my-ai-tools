// @amp-plugin
// External Provider — delegation tools for OpenRouter, Cline, and other
// OpenAI-compatible APIs. Exposes `external_ask`, `external_code_review`,
// and `external_implement` tools plus configuration commands.
//
// This plugin does NOT replace Amp's main model. Amp's PluginAIModelProvider
// is a closed list (amp | anthropic | baseten | fireworks | openai | vertexai |
// xai). Instead, this plugin delegates subtasks to an external provider via
// standard OpenAI Chat Completions requests, returning the result as a tool
// output that Amp's main agent can act on.
//
// Configuration:
//   amp.configuration stores { provider, model } — set via commands.
//   API keys live in environment variables (never in plugin config):
//     EXTERNAL_BASE_URL  – override the provider's default base URL
//     EXTERNAL_API_KEY   – API key for any provider (fallback)
//     OPENROUTER_API_KEY – OpenRouter-specific key (preferred over fallback)
//     CLINE_API_KEY      – Cline-specific key (preferred over fallback)

import type { PluginAPI } from "@ampcode/plugin";

/** Known provider presets with default base URLs and env-var names. */
const PROVIDER_PRESETS = {
	openrouter: {
		baseURL: "https://openrouter.ai/api/v1",
		keyEnv: "OPENROUTER_API_KEY",
		label: "OpenRouter",
		defaultModel: "anthropic/claude-sonnet-4-6",
	},
	cline: {
		baseURL: "https://api.cline.bot/api/v1",
		keyEnv: "CLINE_API_KEY",
		label: "Cline",
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

interface ExternalProviderConfig {
	provider: ProviderKey;
	model: string;
}

const DEFAULT_CONFIG: ExternalProviderConfig = {
	provider: "openrouter",
	model: PROVIDER_PRESETS.openrouter.defaultModel,
};

/** System prompts for each tool. */
const ASK_SYSTEM = `You are a helpful assistant answering questions concisely and accurately.`;

const CODE_REVIEW_SYSTEM = `You are a senior code reviewer. Analyze the provided code or diff and give actionable feedback.
Focus on: correctness, security, performance, readability, and missing edge cases.
Format your response as a prioritized list of findings with severity (critical/major/minor/nit).`;

const IMPLEMENT_SYSTEM = `You are a senior software engineer. Given a task description and relevant context, produce a concrete implementation plan.
Respond with a JSON object (no markdown fences) containing exactly these fields:
{
  "summary": "One-line description of the change",
  "patch": "A unified diff or apply_patch format patch that can be applied to the repository",
  "commands": ["list", "of", "commands", "to", "verify", "the", "change"]
}
If the task is too ambiguous to produce a patch, set "patch" to an empty string and explain why in "summary".`;

/** Resolve the effective base URL and API key for the current provider. */
function resolveEndpoint(config: ExternalProviderConfig): { baseURL: string; apiKey: string } {
	const preset = PROVIDER_PRESETS[config.provider];
	const baseURL = process.env.EXTERNAL_BASE_URL?.trim() || preset.baseURL;
	const apiKey = process.env[preset.keyEnv]?.trim() || process.env.EXTERNAL_API_KEY?.trim() || "";
	if (!baseURL) {
		throw new Error(
			`No base URL configured for provider "${config.provider}". Set EXTERNAL_BASE_URL or choose a known provider.`,
		);
	}
	if (!apiKey) {
		throw new Error(`No API key found. Set ${preset.keyEnv} or EXTERNAL_API_KEY in your environment.`);
	}
	return { baseURL, apiKey };
}

/** Send a chat completion request to an OpenAI-compatible endpoint. */
async function chatCompletion(
	config: ExternalProviderConfig,
	system: string,
	user: string,
	maxTokens = 4096,
): Promise<string> {
	const { baseURL, apiKey } = resolveEndpoint(config);
	const response = await fetch(`${baseURL}/chat/completions`, {
		method: "POST",
		headers: {
			Authorization: `Bearer ${apiKey}`,
			"Content-Type": "application/json",
			"HTTP-Referer": "https://github.com/jellydn/my-ai-tools",
			"X-Title": "amp-external-provider",
		},
		body: JSON.stringify({
			model: config.model,
			messages: [
				{ role: "system", content: system },
				{ role: "user", content: user },
			],
			max_tokens: maxTokens,
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
	if (!content) {
		throw new Error("External provider returned an empty response");
	}
	return content;
}

/** Read config from amp.configuration with defaults. */
async function getConfig(amp: PluginAPI): Promise<ExternalProviderConfig> {
	const stored = (await amp.configuration.get()) as Partial<ExternalProviderConfig>;
	return {
		provider: stored.provider ?? DEFAULT_CONFIG.provider,
		model: stored.model ?? DEFAULT_CONFIG.model,
	};
}

export default function (amp: PluginAPI) {
	amp.logger.log("external-provider plugin initialized");

	// --- Tools -----------------------------------------------------------

	amp.registerTool({
		name: "external_ask",
		description:
			"Ask an external model (OpenRouter, Cline, or any OpenAI-compatible API) a question. " +
			"Use this when you want a second opinion or need to leverage a model not available as an Amp provider. " +
			"The response is plain text returned as a tool result.",
		inputSchema: {
			type: "object",
			properties: {
				prompt: {
					type: "string",
					description: "The question or prompt to send to the external model.",
				},
				model: {
					type: "string",
					description:
						"Optional model ID override (e.g. 'anthropic/claude-sonnet-4-6'). " + "Defaults to the configured model.",
				},
			},
			required: ["prompt"],
		},
		async execute(input) {
			const config = await getConfig(amp);
			const model = (input.model as string | undefined)?.trim();
			if (model) config.model = model;
			const prompt = input.prompt as string;
			amp.logger.log(`external_ask: model=${config.model} prompt=${prompt.length} chars`);
			const result = await chatCompletion(config, ASK_SYSTEM, prompt);
			return result;
		},
	});

	amp.registerTool({
		name: "external_code_review",
		description:
			"Send code or a diff to an external model for review. " +
			"Returns a prioritized list of findings with severity ratings. " +
			"Use this for a second opinion on code quality, security, or design.",
		inputSchema: {
			type: "object",
			properties: {
				code: {
					type: "string",
					description: "The code or diff to review.",
				},
				context: {
					type: "string",
					description: "Optional context about the code (what file, what feature, etc.).",
				},
				model: {
					type: "string",
					description: "Optional model ID override.",
				},
			},
			required: ["code"],
		},
		async execute(input) {
			const config = await getConfig(amp);
			const model = (input.model as string | undefined)?.trim();
			if (model) config.model = model;
			const code = input.code as string;
			const context = (input.context as string | undefined) || "";
			const user = context ? `Context: ${context}\n\nCode:\n${code}` : code;
			amp.logger.log(`external_code_review: model=${config.model} code=${code.length} chars`);
			const result = await chatCompletion(config, CODE_REVIEW_SYSTEM, user, 8192);
			return result;
		},
	});

	amp.registerTool({
		name: "external_implement",
		description:
			"Ask an external model to produce a structured implementation patch for a task. " +
			"Returns a JSON object with summary, patch, and verification commands. " +
			"Amp can then inspect and apply the proposed patch using its own tools. " +
			"The external model does NOT directly modify files — it proposes changes for Amp to apply.",
		inputSchema: {
			type: "object",
			properties: {
				task: {
					type: "string",
					description: "A clear description of the implementation task.",
				},
				context: {
					type: "string",
					description: "Optional relevant code, file paths, or constraints to include in the request.",
				},
				model: {
					type: "string",
					description: "Optional model ID override.",
				},
			},
			required: ["task"],
		},
		async execute(input) {
			const config = await getConfig(amp);
			const model = (input.model as string | undefined)?.trim();
			if (model) config.model = model;
			const task = input.task as string;
			const context = (input.context as string | undefined) || "";
			const user = context ? `Task: ${task}\n\nContext:\n${context}` : `Task: ${task}`;
			amp.logger.log(`external_implement: model=${config.model} task=${task.length} chars`);
			const result = await chatCompletion(config, IMPLEMENT_SYSTEM, user, 8192);
			return result;
		},
	});

	// --- Commands --------------------------------------------------------

	amp.registerCommand(
		"external-provider:select-provider",
		{
			title: "Select Provider",
			category: "External Provider",
			description: "Choose the external model provider (OpenRouter, Cline, or Custom).",
		},
		async (ctx) => {
			const options = Object.entries(PROVIDER_PRESETS).map(([key, preset]) => `${key} (${preset.label})`);
			const selected = await ctx.ui.select({
				title: "Select External Provider",
				options,
				message: "Choose the provider for external_ask / external_code_review / external_implement.",
			});
			if (!selected) return;
			const provider = selected.split(" ")[0] as ProviderKey;
			if (!(provider in PROVIDER_PRESETS)) return;
			const preset = PROVIDER_PRESETS[provider];
			const current = await getConfig(amp);
			const model = current.provider === provider ? current.model : preset.defaultModel;
			await amp.configuration.update({ provider, model });
			await ctx.ui.notify(`External provider set to ${preset.label}, model: ${model}`);
		},
	);

	amp.registerCommand(
		"external-provider:select-model",
		{
			title: "Select Model",
			category: "External Provider",
			description: "Set the model ID used by external provider tools.",
		},
		async (ctx) => {
			const current = await getConfig(amp);
			const model = await ctx.ui.input({
				title: "External Model ID",
				helpText: "Enter the model ID for the selected provider (e.g. anthropic/claude-sonnet-4-6).",
				initialValue: current.model,
				submitButtonText: "Save",
			});
			if (!model?.trim()) return;
			await amp.configuration.update({ model: model.trim() });
			await ctx.ui.notify(`External model set to: ${model.trim()}`);
		},
	);

	amp.registerCommand(
		"external-provider:test-connection",
		{
			title: "Test Connection",
			category: "External Provider",
			description: "Send a test request to verify the external provider is reachable and the API key works.",
		},
		async (ctx) => {
			const config = await getConfig(amp);
			try {
				const result = await chatCompletion(config, ASK_SYSTEM, "Reply with exactly: OK", 16);
				await ctx.ui.notify(`Connection successful. Provider responded: ${result.trim()}`);
			} catch (error) {
				await ctx.ui.notify(`Connection failed: ${(error as Error).message}`);
			}
		},
	);

	amp.registerCommand(
		"external-provider:show-usage",
		{
			title: "Show Configuration",
			category: "External Provider",
			description: "Display the current external provider, model, and resolved endpoint.",
		},
		async (ctx) => {
			const config = await getConfig(amp);
			const preset = PROVIDER_PRESETS[config.provider];
			const baseURL = process.env.EXTERNAL_BASE_URL?.trim() || preset.baseURL || "(not set)";
			const keyEnv = preset.keyEnv;
			const hasKey = Boolean(process.env[keyEnv]?.trim() || process.env.EXTERNAL_API_KEY?.trim());
			await ctx.ui.notify(
				`Provider: ${preset.label} | Model: ${config.model} | Base URL: ${baseURL} | Key: ${hasKey ? "set" : "MISSING"}`,
			);
		},
	);
}
