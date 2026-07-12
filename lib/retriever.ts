import { readFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import OpenAI from "openai";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const INDEX_PATH = resolve(__dirname, "..", "data", "index.json");

const EMBEDDING_MODEL = process.env.OPENAI_EMBEDDING_MODEL ?? "text-embedding-3-small";

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
let indexCache: Index | null = null;

function getClient(): OpenAI {
	if (!openai) {
		const apiKey = process.env.OPENAI_API_KEY;
		if (!apiKey) {
			throw new Error("OPENAI_API_KEY is not set");
		}
		openai = new OpenAI({ apiKey });
	}
	return openai;
}

async function loadIndex(): Promise<Index> {
	const raw = await readFile(INDEX_PATH, "utf-8");
	return JSON.parse(raw) as Index;
}

async function getIndex(): Promise<Index> {
	if (!indexCache) {
		indexCache = await loadIndex();
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
	return dot / (Math.sqrt(aNorm) * Math.sqrt(bNorm));
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

	const queryEmbedding = await embed(query);
	const scored = index.chunks.map((chunk) => ({
		path: chunk.path,
		text: chunk.text,
		score: cosineSimilarity(queryEmbedding, chunk.embedding),
	}));

	scored.sort((a, b) => b.score - a.score);
	return scored.slice(0, topK);
}
