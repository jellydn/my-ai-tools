import { afterEach, describe, expect, test } from "bun:test";
import { createOpenAIClient } from "./openai-client.ts";

const originalKey = process.env.OPENAI_API_KEY;
const originalBaseURL = process.env.OPENAI_BASE_URL;

function setClientEnvironment(key: string, baseURL?: string) {
	process.env.OPENAI_API_KEY = key;
	if (baseURL === undefined) delete process.env.OPENAI_BASE_URL;
	else process.env.OPENAI_BASE_URL = baseURL;
}

function clientBaseURL() {
	const url = new URL(createOpenAIClient().baseURL);
	return url.origin + url.pathname.replace(/\/$/, "");
}

afterEach(() => {
	if (originalKey === undefined) delete process.env.OPENAI_API_KEY;
	else process.env.OPENAI_API_KEY = originalKey;
	if (originalBaseURL === undefined) delete process.env.OPENAI_BASE_URL;
	else process.env.OPENAI_BASE_URL = originalBaseURL;
});

describe("OpenAI-compatible client", () => {
	test("uses OpenRouter automatically for OpenRouter keys", () => {
		setClientEnvironment("sk-or-v1-test-key");
		expect(clientBaseURL()).toBe("https://openrouter.ai/api/v1");
	});

	test("keeps ordinary OpenAI keys on the default endpoint", () => {
		setClientEnvironment("sk-test-key");
		expect(clientBaseURL()).toBe("https://api.openai.com/v1");
	});

	test("keeps an explicit compatible endpoint authoritative", () => {
		setClientEnvironment("sk-or-v1-test-key", "https://example.test/v1");
		expect(clientBaseURL()).toBe("https://example.test/v1");
	});
});
