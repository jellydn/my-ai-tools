import OpenAI from "openai";

/** OpenRouter's OpenAI-compatible API endpoint. */
export const OPENROUTER_BASE_URL = "https://openrouter.ai/api/v1";

/**
 * Default embedding model. OpenRouter-compatible and free
 * (https://openrouter.ai/models?fmt=cards&output_modalities=embeddings);
 * used at build time (scripts/index-repo.ts) and at runtime (lib/retriever.ts)
 * when OPENAI_EMBEDDING_MODEL is not set. Keep both in sync.
 */
export const DEFAULT_EMBEDDING_MODEL = "nvidia/llama-nemotron-embed-vl-1b-v2:free";

export function isOpenRouterKey(apiKey: string): boolean {
	return apiKey.startsWith("sk-or-v1-");
}

/** OpenAI-compatible client (OpenAI, OpenRouter, etc.) from env. */
export function createOpenAIClient(): OpenAI {
	const apiKey = (process.env.OPENAI_API_KEY ?? process.env.OPENROUTER_API_KEY)?.trim();
	if (!apiKey) {
		throw new Error("OPENAI_API_KEY (or OPENROUTER_API_KEY) is not set");
	}

	// An OpenRouter key (sk-or-v1-...) is only accepted by OpenRouter's API,
	// never api.openai.com. Default the base URL so a bare key works at build
	// time and runtime without requiring OPENAI_BASE_URL to be configured.
	const explicitBaseURL = process.env.OPENAI_BASE_URL?.trim();
	const baseURL = explicitBaseURL || (isOpenRouterKey(apiKey) ? OPENROUTER_BASE_URL : undefined);

	return baseURL ? new OpenAI({ apiKey, baseURL }) : new OpenAI({ apiKey });
}
