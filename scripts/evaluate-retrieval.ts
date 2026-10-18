import { readFile } from "node:fs/promises";
import { resolve } from "node:path";
import { pipeline } from "@huggingface/transformers";
import type { ChunkMetadata, DocumentType } from "../lib/indexer.ts";

const INDEX_PATH = resolve("public/index-browser.json");
const MODEL = "Xenova/all-MiniLM-L6-v2";
const TOP_K_VALUES = [3, 5, 10, 20] as const;

type BrowserChunk = {
	path: string;
	text: string;
	metadata: ChunkMetadata;
	embedding: Float32Array;
};

type EvaluationCase = {
	question: string;
	preferredTypes: DocumentType[];
	relevantPath: RegExp;
};

const evaluationCases: EvaluationCase[] = [
	{
		question: "How do I add an MCP server?",
		preferredTypes: ["documentation", "example_config"],
		relevantPath: /^(README\.md|configs\/mcp-registry\.json|wiki\/wiki\/concepts\/mcp-registry\.md)$/,
	},
	{
		question: "How does the repository chat work?",
		preferredTypes: ["documentation", "source"],
		relevantPath: /^(README\.md|docs\/rag-architecture\.md|server\.ts|lib\/retriever\.ts|public\/browser-chat\.js)$/,
	},
	{
		question: "What changed in recent pull requests?",
		preferredTypes: ["pull_request"],
		relevantPath: /^pull\/\d+$/,
	},
];

function dotProduct(a: Float32Array, b: Float32Array): number {
	let sum = 0;
	for (let index = 0; index < a.length; index++) sum += (a[index] ?? 0) * (b[index] ?? 0);
	return sum;
}

function rank(query: Float32Array, chunks: BrowserChunk[], topK: number, types: DocumentType[] = []) {
	const allowedTypes = types.length > 0 ? new Set(types) : null;
	return chunks
		.filter((chunk) => !allowedTypes || allowedTypes.has(chunk.metadata.type))
		.map((chunk) => ({ ...chunk, score: dotProduct(query, chunk.embedding) }))
		.sort((a, b) => b.score - a.score)
		.slice(0, topK);
}

async function loadIndex(): Promise<{
	generatedAt: string;
	repository: string;
	sourceRef: string;
	chunks: BrowserChunk[];
}> {
	const value = JSON.parse(await readFile(INDEX_PATH, "utf-8")) as {
		schemaVersion: number;
		generatedAt: string;
		model: string;
		repository: string;
		sourceRef: string;
		dim: number;
		chunks: Array<Omit<BrowserChunk, "embedding">>;
		embeddings: string;
	};
	if (
		value.schemaVersion !== 2 ||
		value.model !== MODEL ||
		!value.dim ||
		!value.chunks.length ||
		!value.repository ||
		!value.sourceRef
	) {
		throw new Error("Browser index is empty, stale, or uses a different embedding model; run npm run index:browser");
	}
	const bytes = Buffer.from(value.embeddings, "base64");
	if (bytes.byteLength !== value.chunks.length * value.dim * Float32Array.BYTES_PER_ELEMENT) {
		throw new Error("Browser index embedding dimensions are inconsistent; rebuild the index");
	}
	const vectors = new Float32Array(bytes.buffer, bytes.byteOffset, bytes.byteLength / Float32Array.BYTES_PER_ELEMENT);
	return {
		generatedAt: value.generatedAt,
		repository: value.repository,
		sourceRef: value.sourceRef,
		chunks: value.chunks.map((chunk, index) => ({
			...chunk,
			embedding: vectors.subarray(index * value.dim, (index + 1) * value.dim),
		})),
	};
}

function estimatedPromptTokens(chunks: BrowserChunk[]): number {
	return Math.ceil(chunks.reduce((total, chunk) => total + chunk.path.length + chunk.text.length, 0) / 4);
}

async function validateLinks(chunks: BrowserChunk[], repository: string, sourceRef: string, checkLinks: boolean) {
	const unique = [...new Map(chunks.map((chunk) => [chunk.metadata.url, chunk])).values()];
	let structurallyValid = 0;
	let opened = 0;
	for (const chunk of unique) {
		const url = chunk.metadata.url;
		const expectedPrefix = `https://github.com/${repository}/blob/${encodeURIComponent(sourceRef)}/`;
		const sourceMatches =
			chunk.metadata.type === "issue" || chunk.metadata.type === "pull_request"
				? url?.startsWith(`https://github.com/${repository}/`) && url.endsWith(`/${chunk.path}`)
				: url?.startsWith(expectedPrefix) && url.endsWith(`/${chunk.path}`);
		if (sourceMatches) structurallyValid++;
		if (checkLinks && url) {
			try {
				const response = await fetch(url, { method: "HEAD", signal: AbortSignal.timeout(5000) });
				if (response.ok) opened++;
			} catch {
				// Network failures are reported in the summary instead of aborting the benchmark.
			}
		}
	}
	return { checked: unique.length, structurallyValid, opened: checkLinks ? opened : null };
}

async function main() {
	const index = await loadIndex();
	const indexAgeHours = (Date.now() - Date.parse(index.generatedAt)) / 3_600_000;
	const extractor = await pipeline("feature-extraction", MODEL);
	const queryVectors = new Map<string, Float32Array>();
	for (const evaluationCase of evaluationCases) {
		const output = await extractor(evaluationCase.question, { pooling: "mean", normalize: true });
		queryVectors.set(evaluationCase.question, output.data as Float32Array);
	}

	console.log("# Retrieval top-k comparison\n");
	console.log(
		"| top-k | relevance density | answer-support rate | estimated prompt tokens | retrieval latency |\n|---:|---:|---:|---:|---:|",
	);
	for (const topK of TOP_K_VALUES) {
		let relevant = 0;
		let supported = 0;
		let tokens = 0;
		const startedAt = performance.now();
		for (const evaluationCase of evaluationCases) {
			const ranked = rank(queryVectors.get(evaluationCase.question)!, index.chunks, topK);
			const relevantCount = ranked.filter((chunk) => evaluationCase.relevantPath.test(chunk.path)).length;
			relevant += relevantCount;
			supported += Number(relevantCount > 0);
			tokens += estimatedPromptTokens(ranked);
		}
		const latency = performance.now() - startedAt;
		console.log(
			`| ${topK} | ${((relevant / (evaluationCases.length * topK)) * 100).toFixed(0)}% | ${((supported / evaluationCases.length) * 100).toFixed(0)}% | ${Math.round(tokens / evaluationCases.length)} | ${(latency / evaluationCases.length).toFixed(2)} ms |`,
		);
	}

	console.log("\n# Metadata filtering comparison\n");
	console.log("| question | mode | relevant | noise | sources |\n|---|---|---:|---:|---|");
	const traceChunks: BrowserChunk[] = [];
	for (const evaluationCase of evaluationCases) {
		for (const [mode, types] of [
			["unfiltered", []],
			["filtered", evaluationCase.preferredTypes],
		] as const) {
			const ranked = rank(queryVectors.get(evaluationCase.question)!, index.chunks, 5, [...types]);
			if (mode === "unfiltered") traceChunks.push(...ranked);
			const relevant = ranked.filter((chunk) => evaluationCase.relevantPath.test(chunk.path)).length;
			const noise = ranked.filter((chunk) => !evaluationCase.relevantPath.test(chunk.path)).length;
			console.log(
				`| ${evaluationCase.question} | ${mode} | ${relevant}/${ranked.length} | ${noise}/${ranked.length} | ${ranked.map((chunk) => `\`${chunk.path}\``).join(", ")} |`,
			);
		}
	}

	const links = await validateLinks(
		traceChunks,
		index.repository,
		index.sourceRef,
		process.argv.includes("--check-links"),
	);
	console.log("\n# Retrieval trace\n");
	console.log(`- Index generated: ${index.generatedAt} (${indexAgeHours.toFixed(1)} hours old)`);
	console.log(`- Indexed revision: ${index.repository}@${index.sourceRef}`);
	console.log(`- Canonical URL/path checks: ${links.structurallyValid}/${links.checked}`);
	console.log(
		`- HTTP link checks: ${links.opened === null ? "not run (pass --check-links)" : `${links.opened}/${links.checked}`}`,
	);
	if (indexAgeHours > 24)
		console.log("- Warning: index is older than 24 hours; rebuild before using results for release decisions.");
	console.log(
		"\nAnswer-support rate is a retrieval-only proxy: it means at least one human-labeled source was present. It is not an LLM judge score.",
	);
}

main().catch((error) => {
	console.error(error);
	process.exit(1);
});
