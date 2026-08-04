import OpenAI from "openai";

const OPENROUTER_BASE_URL = "https://openrouter.ai/api/v1";

/** OpenAI-compatible client (OpenAI, OpenRouter, etc.) from env. */
export function createOpenAIClient(): OpenAI {
	const apiKey = process.env.OPENAI_API_KEY?.trim();
	if (!apiKey) {
		throw new Error("OPENAI_API_KEY is not set");
	}
	const configuredBaseURL = process.env.OPENAI_BASE_URL?.trim();
	const inferredBaseURL = apiKey.startsWith("sk-or-v1-") ? OPENROUTER_BASE_URL : undefined;
	const baseURL = configuredBaseURL || inferredBaseURL;
	return baseURL ? new OpenAI({ apiKey, baseURL }) : new OpenAI({ apiKey });
}
