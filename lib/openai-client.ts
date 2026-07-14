import OpenAI from "openai";

/** OpenAI-compatible client (OpenAI, OpenRouter, etc.) from env. */
export function createOpenAIClient(): OpenAI {
	const apiKey = process.env.OPENAI_API_KEY?.trim();
	if (!apiKey) {
		throw new Error("OPENAI_API_KEY is not set");
	}
	const baseURL = process.env.OPENAI_BASE_URL?.trim();
	return baseURL ? new OpenAI({ apiKey, baseURL }) : new OpenAI({ apiKey });
}
