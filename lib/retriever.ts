import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import type OpenAI from "openai";
import { createIndexLoader } from "./index-loader.ts";
import type { DocumentType } from "./indexer.ts";
import { createOpenAIClient, getDefaultEmbeddingModel } from "./openai-client.ts";
import { cosineSimilarity } from "./vector-similarity.ts";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const INDEX_PATH = resolve(__dirname, "..", "data", "index.json");

const EMBEDDING_MODEL = process.env.OPENAI_EMBEDDING_MODEL ?? getDefaultEmbeddingModel();

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
const indexLoader = createIndexLoader(INDEX_PATH);

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
	if (!Array.isArray(index.chunks)) throw new Error("Invalid index: no chunks");
	if (index.chunks.length === 0) return index as Index;
	const dimension = index.chunks[0]?.embedding?.length ?? 0;
	if (dimension === 0) throw new Error("Invalid index: empty embedding");
	for (const chunk of index.chunks) {
		if (
			!chunk ||
			typeof chunk.path !== "string" ||
			typeof chunk.text !== "string" ||
			!chunk.metadata ||
			typeof chunk.metadata !== "object" ||
			!["documentation", "source", "issue", "pull_request", "cli_help", "example_config"].includes(chunk.metadata.type) ||
			(chunk.metadata.url !== undefined && typeof chunk.metadata.url !== "string") ||
			(chunk.metadata.author !== undefined && typeof chunk.metadata.author !== "string") ||
			!Array.isArray(chunk.embedding) ||
			!chunk.embedding.every((value) => typeof value === "number" && Number.isFinite(value)) ||
			chunk.embedding.length !== dimension
		) {
			throw new Error("Invalid index: inconsistent chunk or embedding dimensions");
		}
	}
	return index as Index;
}

export const clearIndexCache = () => indexLoader.clear();

async function getIndex(): Promise<Index> {
	return validateIndex(await indexLoader.load());
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
