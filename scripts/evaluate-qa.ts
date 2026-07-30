// Day 14 — End-to-End Document Q&A App Pipeline CLI Evaluator
import { z } from "zod";

type DocumentType = "documentation" | "source";

type Document = {
	path: string;
	type: DocumentType;
	content: string;
};

type Chunk = {
	documentPath: string;
	type: DocumentType;
	index: number;
	text: string;
	vector: number[];
};

// ── 1. Load mock documents (Markdown formats) ─────────────────────────────────
const DOCS_CORPUS: Document[] = [
	{
		path: "docs/postgres.md",
		type: "documentation",
		content:
			"# PostgreSQL Pool Config\nConfigure PostgreSQL connection pool for backend server using max connections threshold of 20.",
	},
	{
		path: "docs/style.md",
		type: "documentation",
		content:
			"# Dashboard Styling\nStyle the dashboard using CSS grid and dark theme variables to ensure WCAG accessibility compliance.",
	},
	{
		path: "docs/auth.md",
		type: "source",
		content:
			"// Auth Handler\nFix null pointer exception crash in API auth handler by verifying token presence beforehand.",
	},
];

// ── 2. Heading-Aware Chunking (Day 9) ──────────────────────────────────────────
function chunkDocuments(docs: Document[]): Chunk[] {
	const chunks: Chunk[] = [];
	docs.forEach((doc) => {
		// Simple header/newline aware chunking simulation
		const lines = doc.content.split("\n");
		let currentHeader = "";
		let chunkText = "";
		let chunkIdx = 1;

		lines.forEach((line) => {
			if (line.startsWith("#")) {
				currentHeader = line.replace("#", "").trim();
			}
			chunkText += (chunkText ? "\n" : "") + line;

			// Split when chunk size is reached or on natural boundaries
			if (chunkText.length > 50) {
				// Mock vectors for simple similarity mapping
				let vector = [0.0, 0.0, 0.0];
				if (doc.path.includes("postgres")) vector = [0.95, 0.1, 0.0];
				else if (doc.path.includes("style")) vector = [0.1, 0.95, 0.0];
				else if (doc.path.includes("auth")) vector = [0.3, 0.0, 0.95];

				chunks.push({
					documentPath: doc.path,
					type: doc.type,
					index: chunkIdx++,
					text: `[Header: ${currentHeader || "None"}] ${chunkText}`,
					vector,
				});
				chunkText = ""; // Reset
			}
		});
	});
	return chunks;
}

// ── 3. Cosine Similarity & Retrieval (Day 8 & Day 11) ───────────────────────
const QUERY_VECTORS: Record<string, number[]> = {
	postgres: [1.0, 0.0, 0.0],
	style: [0.0, 1.0, 0.0],
	auth: [0.0, 0.0, 1.0],
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

function retrieve(
	query: string,
	chunks: Chunk[],
	topK: number,
	allowedTypes: DocumentType[] | null,
): Chunk[] {
	let queryVec = [0.0, 0.0, 0.0];
	const qLower = query.toLowerCase();

	if (qLower.includes("postgres") || qLower.includes("pool")) queryVec = QUERY_VECTORS.postgres;
	else if (qLower.includes("style") || qLower.includes("css")) queryVec = QUERY_VECTORS.style;
	else if (qLower.includes("auth") || qLower.includes("crash")) queryVec = QUERY_VECTORS.auth;

	// Metadata Pre-filtering (Day 11)
	const filtered = allowedTypes ? chunks.filter((c) => allowedTypes.includes(c.type)) : chunks;

	return filtered
		.map((c) => ({
			...c,
			score: cosineSimilarity(queryVec, c.vector),
		}))
		.filter((c) => (c as any).score > 0.3)
		.sort((a, b) => (b as any).score - (a as any).score)
		.slice(0, topK);
}

// ── 4. Prompt Registry & Zod Validation Template (Day 12) ─────────────────────
const qaSchema = z.object({
	question: z.string().min(1, "Question cannot be empty"),
	responseStyle: z.enum(["concise", "detailed", "default"]),
});
type QAVars = z.infer<typeof qaSchema>;

const RAG_SYSTEM_PROMPT = `You are a document Q&A assistant.
Answer the user's question ONLY using the retrieved document excerpts below.
If the retrieved context is insufficient to answer the question, say exactly: "This is not documented."
Always cite your claims using exact brackets format: [documentPath#chunk-index]`;

function compilePrompt(vars: QAVars, retrieved: Chunk[]): { system: string; user: string } {
	const parsed = qaSchema.parse(vars);
	const preferences =
		parsed.responseStyle !== "default" ? `\nPreferred Response Style: ${parsed.responseStyle}` : "";

	const system = `${RAG_SYSTEM_PROMPT}${preferences}`;

	const excerpts = retrieved
		.map((c) => `Source: ${c.documentPath} (Chunk ${c.index})\nContent: ${c.text}`)
		.join("\n\n");
	const user = `Excerpts:\n${excerpts || "No relevant context found."}\n\nQuestion: ${parsed.question}`;

	return { system, user };
}

// ── 5. Grounded Answering Simulation (Day 10) ──────────────────────────────────
function generateAnswer(
	query: string,
	retrieved: Chunk[],
	style: "concise" | "detailed" | "default",
): string {
	if (retrieved.length === 0) {
		return "This is not documented.";
	}

	const primary = retrieved[0];
	const sourceTag = `[${primary.documentPath}#chunk-${primary.index}]`;

	let baseAnswer = "";
	if (query.toLowerCase().includes("postgres")) {
		baseAnswer = `Configure the PostgreSQL connection pool for the backend server with max connections set to 20. ${sourceTag}`;
	} else if (query.toLowerCase().includes("style")) {
		baseAnswer = `Style the dashboard using CSS grid and dark theme variables to meet WCAG access standards. ${sourceTag}`;
	} else if (query.toLowerCase().includes("auth")) {
		baseAnswer = `Resolve the null pointer exception crash in the auth handler by verifying token presence. ${sourceTag}`;
	} else {
		return "This is not documented.";
	}

	if (style === "concise") {
		return `[concise] Set max connections to 20. ${sourceTag}`;
	}
	if (style === "detailed") {
		return `[detailed] According to the database document, you should configure a PostgreSQL pool using a max connections parameter of 20 to protect performance. ${sourceTag}`;
	}

	return baseAnswer;
}

// ── Main Execution ───────────────────────────────────────────────────────────
function main() {
	console.log("====================================================");
	console.log("    Day 14 — End-to-End Document Q&A App Pipeline");
	console.log("====================================================\n");

	console.log("1. Running Ingestion & Chunker...");
	const chunks = chunkDocuments(DOCS_CORPUS);
	console.log(`  Parsed ${DOCS_CORPUS.length} documents into ${chunks.length} segments.`);
	console.log("");

	// Simulated User Session: Querying database with concise style memory
	const query = "How do I configure the PostgreSQL pool?";
	const userPreferences: QAVars = {
		question: query,
		responseStyle: "concise", // Loaded from User Preference Memory
	};

	console.log(`2. User Query: "${query}"`);
	console.log(`   Memory Preference style loaded: "${userPreferences.responseStyle}"`);
	console.log("");

	console.log("3. Executing Metadata Pre-filtering & Retrieval (K=2)...");
	const matches = retrieve(query, chunks, 2, ["documentation"]);
	matches.forEach((m) => {
		console.log(
			`  - Match: [${m.documentPath}#chunk-${m.index}] | Similarity score: ${(m as any).score.toFixed(4)}`,
		);
	});
	console.log("");

	console.log("4. Compiling Zod-Validated Prompt Template...");
	const compiled = compilePrompt(userPreferences, matches);
	console.log("\n[System Prompt]:");
	console.log(compiled.system);
	console.log("\n[User Payload]:");
	console.log(compiled.user);
	console.log("");

	console.log("5. Generating Grounded Answer...");
	const answer = generateAnswer(query, matches, userPreferences.responseStyle);
	console.log(`\nAnswer: "${answer}"`);
	console.log("");

	// Test undocumented query grounding check
	console.log("----------------------------------------------------");
	console.log("GROUNDING CHECK: Querying undocumented topic");
	console.log("----------------------------------------------------");
	const unsupportedQuery = "What is the weather like?";
	console.log(`Query: "${unsupportedQuery}"`);
	const unsupportedMatches = retrieve(unsupportedQuery, chunks, 2, null);
	const unsupportedAnswer = generateAnswer(unsupportedQuery, unsupportedMatches, "default");
	console.log(`Answer: "${unsupportedAnswer}"`);
}

main();
