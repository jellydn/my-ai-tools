import { describe, expect, test } from "bun:test";
import { chunkMarkdown, chunkTypeScript } from "../lib/code-taste/chunker.ts";
import {
	fetchRepositoryChunks,
	resolveRepositories,
	selectRepositoryFiles,
} from "../lib/code-taste/github.ts";
import {
	type AnalysisClient,
	buildProfile,
	hasDistinctEvidence,
	profileToMarkdown,
	selectDiverseChunks,
	type TasteProfile,
} from "../lib/code-taste/profile.ts";

function mockAnalysisClient(content: string): AnalysisClient {
	return {
		embeddings: {
			create: async (request) => ({
				data: request.input
					.map((_, index) => ({ index, embedding: [1 - index * 0.1, index * 0.1] }))
					.reverse(),
			}),
		},
		chat: {
			completions: {
				create: async () => ({ choices: [{ message: { content } }] }),
			},
		},
	};
}

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
		const chunks = chunkMarkdown(
			"owner/repo",
			"README.md",
			"# Usage\n\n```md\n# Example\n```\n\n# API\nDetails",
		);
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
		const stats = { oversizedUnits: 0 };
		const chunks = await chunkTypeScript(
			"owner/repo",
			"src/large.ts",
			`export function generated() {\n${"console.log(1);\n".repeat(600)}}`,
			stats,
		);
		expect(chunks).toEqual([]);
		expect(stats.oversizedUnits).toBe(1);
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
		...Array.from({ length: 20 }, (_, index) => ({
			path: `tiny-${index}.ts`,
			type: "blob" as const,
			size: 20,
		})),
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

test("fetchRepositoryChunks continues when one file download fails", async () => {
	const originalFetch = globalThis.fetch;
	const warnings: string[] = [];
	const warn = console.warn;
	console.warn = (...args: unknown[]) => {
		warnings.push(args.map(String).join(" "));
	};

	globalThis.fetch = (async (input) => {
		const url = typeof input === "string" || input instanceof URL ? String(input) : input.url;
		if (url.endsWith("/repos/owner/repo")) {
			return Response.json({
				full_name: "owner/repo",
				default_branch: "main",
				description: "Fixture",
				language: "TypeScript",
				stargazers_count: 1,
				pushed_at: "2026-07-01T00:00:00Z",
				fork: false,
				archived: false,
				size: 10,
			});
		}
		if (url.includes("/git/trees/main")) {
			return Response.json({
				tree: [
					{ path: "src/a.ts", type: "blob", size: 120 },
					{ path: "src/missing.ts", type: "blob", size: 80 },
				],
				truncated: false,
			});
		}
		if (url.endsWith("/src/a.ts")) {
			return new Response("export function run() { return 1; }");
		}
		if (url.endsWith("/src/missing.ts")) return new Response("Not found", { status: 404 });
		return new Response("Not found", { status: 404 });
	}) as typeof fetch;

	try {
		const repositories = await resolveRepositories("owner/repo", 1);
		const chunks = await fetchRepositoryChunks(repositories[0]!);
		expect(chunks.length).toBeGreaterThan(0);
		expect(chunks.some((chunk) => chunk.path === "src/a.ts")).toBe(true);
		expect(warnings.some((message) => message.includes("src/missing.ts"))).toBe(true);
	} finally {
		globalThis.fetch = originalFetch;
		console.warn = warn;
	}
});

test("mocked pipeline rejects invalid evidence and exports a valid preference", async () => {
	const originalFetch = globalThis.fetch;
	globalThis.fetch = (async (input) => {
		const url = typeof input === "string" || input instanceof URL ? String(input) : input.url;
		if (url.endsWith("/repos/owner/repo")) {
			return Response.json({
				full_name: "owner/repo",
				default_branch: "main",
				description: "Fixture",
				language: "TypeScript",
				stargazers_count: 1,
				pushed_at: "2026-07-01T00:00:00Z",
				fork: false,
				archived: false,
				size: 10,
			});
		}
		if (url.includes("/git/trees/main")) {
			return Response.json({
				tree: [
					{ path: "src/a.ts", type: "blob", size: 120 },
					{ path: "src/b.ts", type: "blob", size: 80 },
				],
				truncated: false,
			});
		}
		if (url.endsWith("/src/a.ts")) {
			return new Response(
				"interface Options { dryRun: boolean }\nexport function run(options: Options) { return options.dryRun; }",
			);
		}
		if (url.endsWith("/src/b.ts")) return new Response("export function main() { return true; }");
		return new Response("Not found", { status: 404 });
	}) as typeof fetch;

	try {
		const repositories = await resolveRepositories("owner/repo", 1);
		const chunks = await fetchRepositoryChunks(repositories[0]!);
		const response = `\`\`\`json\n${JSON.stringify({
			preferences: [
				{ category: "Invalid", preference: "Hallucinated evidence", evidence: ["E1", "E99"] },
				{ category: "Invalid", preference: "One-file evidence", evidence: ["E1", "E2"] },
				{ category: "TypeScript", preference: "Prefer focused functions", evidence: ["E2", "E3"] },
			],
		})}\n\`\`\``;
		const profile = await buildProfile(
			"owner/repo",
			repositories,
			chunks,
			chunks.length,
			mockAnalysisClient(response),
		);
		expect(profile.preferences.map((preference) => preference.preference)).toEqual([
			"Prefer focused functions",
		]);
		const markdown = profileToMarkdown(profile);
		expect(markdown).toContain("`owner/repo` · `src/a.ts` · `run`");
		expect(markdown).toContain("`owner/repo` · `src/b.ts` · `main`");
	} finally {
		globalThis.fetch = originalFetch;
	}
});

test("LLM evidence payload escapes XML attribute characters", async () => {
	let userContent = "";
	const openai = {
		embeddings: {
			create: async (request: { input: string[] }) => ({
				data: request.input.map((_, index) => ({ index, embedding: [1, 0] })),
			}),
		},
		chat: {
			completions: {
				create: async (request: { messages?: Array<{ role: string; content: string }> }) => {
					userContent = request.messages?.find((message) => message.role === "user")?.content ?? "";
					return {
						choices: [
							{
								message: {
									content: JSON.stringify({
										preferences: [
											{
												category: "TypeScript",
												preference: "Escape paths",
												evidence: ["E1", "E2"],
											},
										],
									}),
								},
							},
						],
					};
				},
			},
		},
	} satisfies AnalysisClient;

	const repository = {
		fullName: 'owner/"repo"',
		defaultBranch: "main",
		description: null,
		language: "TypeScript",
		stars: 0,
		pushedAt: "2026-07-01T00:00:00Z",
	};
	const chunks = [
		{
			repo: 'owner/"repo"',
			path: 'src/"a".ts',
			symbol: 'run<"x">',
			kind: "code" as const,
			text: "export function run() {}",
		},
		{
			repo: 'owner/"repo"',
			path: "src/b.ts",
			symbol: "main",
			kind: "code" as const,
			text: "export function main() {}",
		},
	];
	await buildProfile('owner/"repo"', [repository], chunks, 2, openai);
	expect(userContent).toContain('repo="owner/&quot;repo&quot;"');
	expect(userContent).toContain('file="src/&quot;a&quot;.ts"');
	expect(userContent).toContain('symbol="run&lt;&quot;x&quot;&gt;"');
});

test("pipeline rejects malformed model output", async () => {
	const repository = {
		fullName: "owner/repo",
		defaultBranch: "main",
		description: null,
		language: "TypeScript",
		stars: 0,
		pushedAt: "2026-07-01T00:00:00Z",
	};
	const chunks = [
		{
			repo: "owner/repo",
			path: "src/a.ts",
			symbol: "run",
			kind: "code" as const,
			text: "function run() {}",
		},
	];
	await expect(
		buildProfile("owner/repo", [repository], chunks, 1, mockAnalysisClient("not JSON")),
	).rejects.toBeDefined();
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
	expect(markdown).toContain("# jellydn's Coding Taste");
	expect(markdown).toContain("confidence: 0.91");
	expect(markdown).toContain("`jellydn/a` · `src/a.ts` · `run`");
});
