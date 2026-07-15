import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { indexKnowledgeBase } from "../lib/indexer.ts";
import { createOpenAIClient } from "../lib/openai-client.ts";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const REPO_ROOT = resolve(__dirname, "..");
const DATA_DIR = resolve(REPO_ROOT, "data");
const INDEX_PATH = resolve(DATA_DIR, "index.json");

const EMBEDDING_BATCH_SIZE = 100;
const EMBEDDING_MODEL = process.env.OPENAI_EMBEDDING_MODEL ?? "text-embedding-3-small";

async function createEmbeddings(chunks: string[]): Promise<number[][]> {
	const openai = createOpenAIClient();
	const embeddings: number[][] = [];

	for (let i = 0; i < chunks.length; i += EMBEDDING_BATCH_SIZE) {
		const batch = chunks.slice(i, i + EMBEDDING_BATCH_SIZE);
		const response = await openai.embeddings.create({
			model: EMBEDDING_MODEL,
			input: batch,
			encoding_format: "float",
		});
		for (const item of [...response.data].sort((a, b) => (a.index ?? 0) - (b.index ?? 0))) {
			embeddings.push(item.embedding);
		}
	}

	return embeddings;
}

async function main() {
	const apiKey = process.env.OPENAI_API_KEY?.trim();
	if (!apiKey) {
		console.error("OPENAI_API_KEY is not set. Copy .env.example to .env and add your key.");
		process.exit(1);
	}

	const chunks = await indexKnowledgeBase(REPO_ROOT);
	if (chunks.length === 0) {
		console.error("No chunks found to index.");
		process.exit(1);
	}

	const texts = chunks.map((c) => c.text);
	const embeddings = await createEmbeddings(texts);

	const indexedChunks = chunks.map((chunk, index) => ({
		path: chunk.path,
		text: chunk.text,
		metadata: chunk.metadata,
		embedding: embeddings[index],
	}));

	mkdirSync(DATA_DIR, { recursive: true });
	writeFileSync(
		INDEX_PATH,
		JSON.stringify({
			schemaVersion: 2,
			generatedAt: new Date().toISOString(),
			model: EMBEDDING_MODEL,
			chunks: indexedChunks,
		}),
		"utf-8",
	);

	console.log(`Index saved to ${relative(REPO_ROOT, INDEX_PATH)}`);
	console.log(`Total chunks: ${indexedChunks.length}`);
}

main().catch((error) => {
	console.error(error);
	process.exit(1);
});
