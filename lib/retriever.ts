import { readFile, stat } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import type OpenAI from "openai";
import type { DocumentType } from "./indexer.ts";
import { createOpenAIClient } from "./openai-client.ts";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const INDEX_PATH = resolve(__dirname, "..", "data", "index.json");

const EMBEDDING_MODEL = process.env.OPENAI_EMBEDDING_MODEL ?? "text-embedding-3-small";

export type Chunk = {
	path: string;
	text: string;
	metadata: {
		type: DocumentType;
		author?: string;
		url?: string;
	};
	embedding: number[];
};

export type RetrievedChunk = {
	path: string;
	text: string;
	metadata: Chunk["metadata"];
	score: number;
};

export type RetrievalOptions = {
	topK: 3 | 5 | 10 | 20;
	types?: DocumentType[];
};

export type Index = {
	schemaVersion: number;
	generatedAt: string;
	model: string;
	chunks: Chunk[];
};

let openai: OpenAI | null = null;
let indexCache: Index | null = null;
let indexCacheMtime = 0;
let indexCacheSize = 0;

function getClient(): OpenAI {
	if (!openai) {
		openai = createOpenAIClient();
	}
	return openai;
}

export function validateIndex(value: unknown): Index {
	if (!value || typeof value !== "object") throw new Error("Invalid index: expected an object");
	const index = value as Partial<Index>;
	if (index.schemaVersion !== 2) throw new Error("Unsupported index schema; rebuild the repository index");
	if (index.model !== EMBEDDING_MODEL) {
		throw new Error(`Index model ${index.model ?? "unknown"} does not match configured model ${EMBEDDING_MODEL}`);
	}
	if (!Array.isArray(index.chunks) || index.chunks.length === 0) throw new Error("Invalid index: no chunks");
	const dimension = index.chunks[0]?.embedding?.length ?? 0;
	if (dimension === 0) throw new Error("Invalid index: empty embedding");
	for (const chunk of index.chunks) {
		if (
			typeof chunk.path !== "string" ||
			typeof chunk.text !== "string" ||
			!chunk.metadata ||
			!Array.isArray(chunk.embedding) ||
			chunk.embedding.length !== dimension
		) {
			throw new Error("Invalid index: inconsistent chunk or embedding dimensions");
		}
	}
	return index as Index;
}

async function loadIndex(): Promise<Index> {
	const raw = await readFile(INDEX_PATH, "utf-8");
	return validateIndex(JSON.parse(raw));
}

async function getIndex(): Promise<Index> {
	const stats = await stat(INDEX_PATH);
	if (!indexCache || stats.mtimeMs !== indexCacheMtime || stats.size !== indexCacheSize) {
		indexCache = await loadIndex();
		indexCacheMtime = stats.mtimeMs;
		indexCacheSize = stats.size;
	}
	return indexCache;
}

function cosineSimilarity(a: number[], b: number[]): number {
	let dot = 0;
	let aNorm = 0;
	let bNorm = 0;
	for (let index = 0; index < a.length; index++) {
		const aValue = a[index] ?? 0;
		const bValue = b[index] ?? 0;
		dot += aValue * bValue;
		aNorm += aValue * aValue;
		bNorm += bValue * bValue;
	}
	const denominator = Math.sqrt(aNorm) * Math.sqrt(bNorm);
	return denominator === 0 ? 0 : dot / denominator;
}

export function rankChunks(
	queryEmbedding: number[],
	chunks: Chunk[],
	{ topK, types }: RetrievalOptions,
): RetrievedChunk[] {
	const allowedTypes = types?.length ? new Set(types) : null;
	const candidates = allowedTypes ? chunks.filter((chunk) => allowedTypes.has(chunk.metadata.type)) : chunks;
	const scored = candidates.map((chunk) => ({
		path: chunk.path,
		text: chunk.text,
		metadata: chunk.metadata,
		score: cosineSimilarity(queryEmbedding, chunk.embedding),
	}));

	scored.sort((a, b) => b.score - a.score);
	return scored.slice(0, topK);
}

export async function embed(text: string): Promise<number[]> {
	const client = getClient();
	const response = await client.embeddings.create({
		model: EMBEDDING_MODEL,
		input: text,
		encoding_format: "float",
	});
	if (!response.data[0]) {
		throw new Error("No embedding returned from OpenAI");
	}
	return response.data[0].embedding;
}

export async function retrieve(query: string, options: RetrievalOptions): Promise<RetrievedChunk[]> {
	const index = await getIndex();
	const allowedTypes = options.types?.length ? new Set(options.types) : null;
	const candidates = allowedTypes ? index.chunks.filter((chunk) => allowedTypes.has(chunk.metadata.type)) : index.chunks;
	if (candidates.length === 0) {
		return [];
	}

	const queryEmbedding = await embed(query);
	if (queryEmbedding.length !== index.chunks[0]?.embedding.length) {
		throw new Error("Query embedding dimension does not match the repository index; rebuild the index");
	}
	return rankChunks(queryEmbedding, candidates, { ...options, types: undefined });
}
