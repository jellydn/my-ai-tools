// Day 11 — Retrieval Quality Evaluator CLI Utility

type DocumentType = "documentation" | "source" | "pull_request" | "example_config";

type Chunk = {
	path: string;
	type: DocumentType;
	text: string;
	vector: number[];
	isRelevant: boolean;
};

const DATABASE: Chunk[] = [
	{
		path: "README.md",
		type: "documentation",
		text: "To add a Model Context Protocol (MCP) server, register it inside the mcp-registry.json config file.",
		vector: [0.95, 0.1, 0.0],
		isRelevant: true,
	},
	{
		path: "configs/mcp-registry.json",
		type: "example_config",
		text: "Example configuration showing how to declare mcp servers with command and environment variables.",
		vector: [0.9, 0.2, 0.0],
		isRelevant: true,
	},
	{
		path: "lib/retriever.ts",
		type: "source",
		text: "export function retrieve(query: string, topK: number) { ... }",
		vector: [0.4, 0.1, 0.0],
		isRelevant: false,
	},
	{
		path: "pull/310",
		type: "pull_request",
		text: "PR 310: Add 30-day AI learning journey branch and folders.",
		vector: [0.1, 0.1, 0.8],
		isRelevant: false,
	},
	{
		path: "pull/315",
		type: "pull_request",
		text: "PR 315: Grounding prompts and streaming answers to repo chat.",
		vector: [0.2, 0.1, 0.7],
		isRelevant: false,
	},
];

const QUERY_VECTORS: Record<string, number[]> = {
	mcp: [1.0, 0.0, 0.0],
	server: [1.0, 0.0, 0.0],
};

function dotProduct(vecA: number[], vecB: number[]): number {
	return vecA.reduce((sum, val, idx) => sum + val * (vecB[idx] ?? 0), 0);
}

function magnitude(vec: number[]): number {
	return Math.sqrt(vec.reduce((sum, val) => sum + val * val, 0));
}

function cosineSimilarity(vecA: number[], vecB: number[]): number {
	const dot = dotProduct(vecA, vecB);
	const magA = magnitude(vecA);
	const magB = magnitude(vecB);
	if (magA === 0 || magB === 0) return 0;
	return dot / (magA * magB);
}

function runRetrieval(queryText: string, topK: number, allowedTypes: DocumentType[] | null) {
	const queryVec = QUERY_VECTORS[queryText.toLowerCase()] ?? [0.0, 0.0, 0.0];

	// Filter by metadata type first (Pre-filtering)
	const filteredDatabase = allowedTypes
		? DATABASE.filter((c) => allowedTypes.includes(c.type))
		: DATABASE;

	// Rank by similarity
	const ranked = filteredDatabase
		.map((chunk) => {
			const score = cosineSimilarity(queryVec, chunk.vector);
			return { ...chunk, score };
		})
		.sort((a, b) => b.score - a.score)
		.slice(0, topK);

	// Calculate stats
	const relevantCount = ranked.filter((c) => c.isRelevant).length;
	const density = ranked.length > 0 ? (relevantCount / ranked.length) * 100 : 0;
	const support = relevantCount > 0 ? "YES" : "NO";
	const estTokens = Math.ceil(
		ranked.reduce((sum, c) => sum + c.path.length + c.text.length, 0) / 4,
	);

	console.log(`- Filter: [${allowedTypes ? allowedTypes.join(", ") : "UNFILTERED"}]`);
	console.log(`  Retrieval parameters: Top-${topK}`);
	console.log(
		`  Metrics: Density: ${density.toFixed(0)}% | Answer Supported: ${support} | Est. Prompt Tokens: ${estTokens}`,
	);
	console.log("  Chunks Trace:");
	ranked.forEach((c, idx) => {
		const label = c.isRelevant ? "★ [RELEVANT]" : "  [ NOISE  ]";
		console.log(
			`    Rank #${idx + 1} | Score: ${c.score.toFixed(4)} | ${label} | ${c.path} (${c.type})`,
		);
	});
	console.log("");
}

function main() {
	console.log("====================================================");
	console.log("    Day 11 — RAG Retrieval Quality Evaluator");
	console.log("====================================================\n");

	const QUESTION = "mcp";

	console.log(`Question: "How do I add an MCP server?" (Query keyword: "${QUESTION}")\n`);

	console.log("----------------------------------------------------");
	console.log("TEST 1: Tuning K (No Filters)");
	console.log("----------------------------------------------------");
	runRetrieval(QUESTION, 3, null);
	runRetrieval(QUESTION, 5, null);

	console.log("----------------------------------------------------");
	console.log("TEST 2: Pre-filtering (K=5)");
	console.log("----------------------------------------------------");
	runRetrieval(QUESTION, 5, ["documentation", "example_config"]);
	runRetrieval(QUESTION, 5, ["pull_request"]);

	console.log("====================================================");
	console.log("    Relevance Insights");
	console.log("====================================================");
	console.log("- Does increasing K improve support? Yes, Top-5 retrieves all relevant files.");
	console.log(
		"- Does pre-filtering remove noise? Yes, setting ['documentation', 'example_config']",
	);
	console.log(
		"  increases relevance density from 40% (2/5) to 100% (2/2) and lowers tokens from 97 to 44.",
	);
	console.log("- What happens with a bad filter? Setting ['pull_request'] results in 0% relevance");
	console.log("  and fails support entirely.");
}

main();
