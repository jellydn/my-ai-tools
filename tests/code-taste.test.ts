import { describe, expect, test } from "bun:test";
import { chunkMarkdown, chunkTypeScript } from "../lib/code-taste/chunker.ts";
import { selectRepositoryFiles } from "../lib/code-taste/github.ts";
import {
	hasDistinctEvidence,
	profileToMarkdown,
	selectDiverseChunks,
	type TasteProfile,
} from "../lib/code-taste/profile.ts";

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

	test("matches Markdown fence marker and length", () => {
		const markdown = [
			"# Tilde fence",
			"~~~~md",
			"```",
			"# Not a heading",
			"```",
			"~~~~",
			"# Four backticks",
			"````md",
			"```",
			"# Still not a heading",
			"````",
			"# Final",
		].join("\n");
		const chunks = chunkMarkdown("owner/repo", "README.md", markdown);
		expect(chunks.map((chunk) => chunk.symbol)).toEqual(["Tilde fence", "Four backticks", "Final"]);
	});

	test("keeps blank lines inside fences and handles unclosed fences", () => {
		const fencedContent = `~~~ts\n${"const value = 1;\n".repeat(250)}\n\nconst afterBlank = 2;\n~~~`;
		const chunks = chunkMarkdown(
			"owner/repo",
			"README.md",
			`# Code\n${fencedContent}\n\n# Unclosed\n\`\`\`md\n# Not a heading`,
		);
		expect(chunks.map((chunk) => chunk.symbol)).toEqual(["Code", "Unclosed"]);
		expect(chunks[0]?.text).toContain("const afterBlank = 2;");
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

test("representative selection prefers central chunks and balances repositories", () => {
	const chunks = ["one", "two", "three", "four"].map((symbol, index) => ({
		repo: index < 3 ? "owner/a" : "owner/b",
		path: `src/${symbol}.ts`,
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
	const central = selectDiverseChunks(
		chunks.slice(0, 3),
		[
			[1, 0],
			[0.99, 0.01],
			[0, 1],
		],
		1,
	);
	expect(central[0]?.symbol).toBe("two");
});

test("repository file selection samples important buckets instead of tiny files", () => {
	const files = [
		{ path: "src/index.ts", type: "blob" as const, size: 50 },
		{ path: "src/domain/service.ts", type: "blob" as const, size: 9_000 },
		{ path: "tests/service.test.ts", type: "blob" as const, size: 5_000 },
		{ path: "src/commands/run.ts", type: "blob" as const, size: 4_000 },
		{ path: "README.md", type: "blob" as const, size: 6_000 },
		{ path: "src/application.ts", type: "blob" as const, size: 15_000 },
		...Array.from({ length: 20 }, (_, index) => ({ path: `tiny-${index}.ts`, type: "blob" as const, size: 20 })),
	];
	const selected = selectRepositoryFiles(files, 5).map((file) => file.path);
	expect(selected).toContain("src/domain/service.ts");
	expect(selected).toContain("tests/service.test.ts");
	expect(selected).toContain("src/commands/run.ts");
	expect(selected).toContain("README.md");
	expect(selected).toContain("src/application.ts");
});

test("evidence must span distinct files", () => {
	expect(
		hasDistinctEvidence([
			{ repo: "owner/repo", file: "src/a.ts", symbol: "Options" },
			{ repo: "owner/repo", file: "src/a.ts", symbol: "run" },
		]),
	).toBe(false);
	expect(
		hasDistinctEvidence([
			{ repo: "owner/repo", file: "src/a.ts", symbol: "run" },
			{ repo: "owner/repo", file: "src/b.ts", symbol: "main" },
		]),
	).toBe(true);
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
