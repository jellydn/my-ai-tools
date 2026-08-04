import OpenAI from "openai";

/** OpenRouter's OpenAI-compatible API endpoint. */
export const OPENROUTER_BASE_URL = "https://openrouter.ai/api/v1";

/**
 * Default embedding model for OpenAI keys. Used at build time
 * (scripts/index-repo.ts) and at runtime (lib/retriever.ts) when
 * OPENAI_EMBEDDING_MODEL is not set. Keep both in sync.
 */
export const DEFAULT_EMBEDDING_MODEL = "text-embedding-3-small";

/**
 * Default embedding model for OpenRouter keys: OpenRouter-compatible and free
 * (https://openrouter.ai/models?fmt=cards&output_modalities=embeddings).
 */
export const DEFAULT_OPENROUTER_EMBEDDING_MODEL = "nvidia/llama-nemotron-embed-vl-1b-v2:free";

export function isOpenRouterKey(apiKey: string): boolean {
	return apiKey.startsWith("sk-or-v1-");
}

/** First non-empty key, trimmed; OPENAI_API_KEY wins when both are set. */
export function resolveApiKey(): string | undefined {
	return process.env.OPENAI_API_KEY?.trim() || process.env.OPENROUTER_API_KEY?.trim() || undefined;
}

/**
 * Provider-aware default embedding model: OpenRouter's free model for
 * OpenRouter keys, OpenAI's model otherwise. Mirrors the base-URL inference in
 * createOpenAIClient() so a bare key works without OPENAI_EMBEDDING_MODEL.
 */
export function getDefaultEmbeddingModel(): string {
	const apiKey = resolveApiKey();
	return apiKey && isOpenRouterKey(apiKey)
		? DEFAULT_OPENROUTER_EMBEDDING_MODEL
		: DEFAULT_EMBEDDING_MODEL;
}

/** OpenAI-compatible client (OpenAI, OpenRouter, etc.) from env. */
export function createOpenAIClient(): OpenAI {
	const apiKey = resolveApiKey();
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
