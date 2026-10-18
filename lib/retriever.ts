import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import type OpenAI from "openai";
import { createIndexLoader } from "./index-loader.ts";
import { createOpenAIClient, getDefaultEmbeddingModel } from "./openai-client.ts";
import { cosineSimilarity } from "./vector-similarity.ts";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const INDEX_PATH = resolve(__dirname, "..", "data", "index.json");

const EMBEDDING_MODEL = process.env.OPENAI_EMBEDDING_MODEL ?? getDefaultEmbeddingModel();

export type Chunk = {
	path: string;
	text: string;
	embedding: number[];
};

export type RetrievedChunk = {
	path: string;
	text: string;
	score: number;
};

export type Index = {
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

export const clearIndexCache = () => indexLoader.clear();

async function getIndex(): Promise<Index> {
	return indexLoader.load();
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

export async function retrieve(query: string, topK: number): Promise<RetrievedChunk[]> {
	const index = await getIndex();
	if (index.chunks.length === 0) {
		return [];
	}
	if (index.model !== EMBEDDING_MODEL) {
		throw new Error(`Index uses embedding model "${index.model}", but retrieval uses "${EMBEDDING_MODEL}"`);
	}

	const queryEmbedding = await embed(query);
	if (index.chunks.some((chunk) => chunk.embedding.length !== queryEmbedding.length)) {
		throw new Error("Index embedding dimensions do not match the query embedding");
	}
	const scored = index.chunks.map((chunk) => ({
		path: chunk.path,
		text: chunk.text,
		score: cosineSimilarity(queryEmbedding, chunk.embedding),
	}));

	scored.sort((a, b) => b.score - a.score);
	return scored.slice(0, topK);
}
