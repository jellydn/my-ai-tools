import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { pipeline } from "@huggingface/transformers";
import { indexRepository } from "../lib/indexer.ts";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const REPO_ROOT = resolve(__dirname, "..");
const PUBLIC_DIR = resolve(REPO_ROOT, "public");
const INDEX_PATH = resolve(PUBLIC_DIR, "index-browser.json");

const EMBEDDING_MODEL = "Xenova/all-MiniLM-L6-v2";
const EMBEDDING_BATCH_SIZE = 32;

async function createEmbeddings(texts: string[]): Promise<number[][]> {
	const extractor = await pipeline("feature-extraction", EMBEDDING_MODEL);

	const embeddings: number[][] = [];

	for (let i = 0; i < texts.length; i += EMBEDDING_BATCH_SIZE) {
		const batch = texts.slice(i, i + EMBEDDING_BATCH_SIZE);
		const output = await extractor(batch, { pooling: "mean", normalize: true });
		const batchEmbeddings = output.tolist() as number[][];
		embeddings.push(...batchEmbeddings);
	}

	return embeddings;
}

function encodeEmbeddingsToBase64(embeddings: number[][], dim: number): string {
	const float32 = new Float32Array(embeddings.length * dim);
	for (let i = 0; i < embeddings.length; i++) {
		const vector = embeddings[i];
		if (!vector) continue;
		for (let j = 0; j < dim; j++) {
			float32[i * dim + j] = vector[j] ?? 0;
		}
	}
	return Buffer.from(float32.buffer).toString("base64");
}

async function main() {
	const chunks = indexRepository(REPO_ROOT);
	if (chunks.length === 0) {
		console.error("No chunks found to index.");
		process.exit(1);
	}

	const texts = chunks.map((c) => c.text);
	const embeddings = await createEmbeddings(texts);

	const dim = embeddings[0]?.length ?? 0;
	if (dim === 0) {
		console.error("No embeddings returned.");
		process.exit(1);
	}

	const encodedEmbeddings = encodeEmbeddingsToBase64(embeddings, dim);

	mkdirSync(PUBLIC_DIR, { recursive: true });
	writeFileSync(
		INDEX_PATH,
		JSON.stringify({
			generatedAt: new Date().toISOString(),
			model: EMBEDDING_MODEL,
			dim,
			chunks: chunks.map((chunk) => ({ path: chunk.path, text: chunk.text })),
			embeddings: encodedEmbeddings,
		}),
		"utf-8",
	);

	console.log(`Browser index saved to ${relative(REPO_ROOT, INDEX_PATH)}`);
	console.log(`Total chunks: ${chunks.length}, dim: ${dim}`);
}

main().catch((error) => {
	console.error(error);
	process.exit(1);
});
