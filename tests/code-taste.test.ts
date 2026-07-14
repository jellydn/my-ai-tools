import { describe, expect, test } from "bun:test";
import { chunkMarkdown, chunkTypeScript } from "../lib/code-taste/chunker.ts";
import { profileToMarkdown, selectDiverseChunks, type TasteProfile } from "../lib/code-taste/profile.ts";

describe("semantic chunking", () => {
	test("keeps TypeScript declarations intact", async () => {
		const chunks = await chunkTypeScript(
			"owner/repo",
			"src/example.ts",
			`interface Options { dryRun: boolean }

// Executes without nesting.
export function run(options: Options) {
	if (options.dryRun) return;
	console.log("run");
}`,
		);

		expect(chunks.map((chunk) => chunk.symbol)).toEqual(["Options", "run"]);
		expect(chunks[1]?.text).toContain("interface Options");
		expect(chunks[1]?.text).toContain("if (options.dryRun) return;");
	});

	test("does not treat headings inside fenced Markdown as sections", () => {
		const chunks = chunkMarkdown("owner/repo", "README.md", "# Usage\n\n```md\n# Example\n```\n\n# API\nDetails");
		expect(chunks.map((chunk) => chunk.symbol)).toEqual(["Usage", "API"]);
	});

	test("omits oversized functions instead of splitting their bodies", async () => {
		const chunks = await chunkTypeScript(
			"owner/repo",
			"src/large.ts",
			`export function generated() {\n${"console.log(1);\n".repeat(600)}}`,
		);
		expect(chunks).toEqual([]);
	});
});

test("diverse selection balances repositories", () => {
	const chunks = ["one", "two", "three", "four"].map((symbol, index) => ({
		repo: index < 3 ? "owner/a" : "owner/b",
		path: `${symbol}.ts`,
		symbol,
		kind: "code" as const,
		text: symbol,
	}));
	const selected = selectDiverseChunks(
		chunks,
		[
			[1, 0],
			[0.99, 0.01],
			[0.98, 0.02],
			[0, 1],
		],
		2,
	);
	expect(new Set(selected.map((chunk) => chunk.repo)).size).toBe(2);
});

test("Markdown export includes confidence and citations", () => {
	const profile: TasteProfile = {
		name: "jellydn",
		githubTarget: "jellydn",
		generatedAt: "2026-07-14T00:00:00.000Z",
		models: { embedding: "embed", analysis: "analysis" },
		repositories: [],
		preferences: [
			{
				category: "TypeScript",
				preference: "Use early returns.",
				confidence: 0.91,
				evidence: [{ repo: "jellydn/a", file: "src/a.ts", symbol: "run" }],
			},
		],
	};
	const markdown = profileToMarkdown(profile);
	expect(markdown).toContain("# Dung's Coding Taste");
	expect(markdown).toContain("confidence: 0.91");
	expect(markdown).toContain("`jellydn/a` · `src/a.ts` · `run`");
});
