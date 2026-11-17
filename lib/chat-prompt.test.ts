import { describe, expect, test } from "bun:test";
import { buildSystemPrompt } from "./chat-prompt.ts";

describe("chat prompt", () => {
	test("labels retrieved excerpts and preserves grounding rules", () => {
		const prompt = buildSystemPrompt([{ path: "README.md", text: "Use ./cli.sh --dry-run" }]);
		expect(prompt).toContain("--- README.md ---");
		expect(prompt).toContain("Use ./cli.sh --dry-run");
		expect(prompt).toContain("This is not documented in the repository.");
	});
});
