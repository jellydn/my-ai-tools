import { mkdirSync, readdirSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { dirname, extname, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import OpenAI from "openai";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const REPO_ROOT = resolve(__dirname, "..");
const DATA_DIR = resolve(REPO_ROOT, "data");
const INDEX_PATH = resolve(DATA_DIR, "index.json");

const MAX_CHUNK_SIZE = 1000;
const CHUNK_OVERLAP = 200;
const EMBEDDING_BATCH_SIZE = 100;
const EMBEDDING_MODEL = process.env.OPENAI_EMBEDDING_MODEL ?? "text-embedding-3-small";

const SUPPORTED_EXTS = new Set([".md", ".txt", ".json", ".yaml", ".yml", ".sh", ".ps1"]);

const EXCLUDED_DIRS = new Set([
	".git",
	"node_modules",
	"out",
	"dist",
	"coverage",
	".cache",
	"data",
	"auth",
	".changeset",
	".codex",
	".antigravitycli",
	".claude",
	".cline",
	".cursor",
	".kilo",
	".opencode",
	".pi",
	".grok",
	".gemini",
	".ccs",
	".factory",
	".conductor",
	".commandcode",
	".mimo",
	".qodercli",
	".kiro",
	".herdr",
	".ai-launcher",
]);

const EXCLUDED_FILE_PATTERNS = [
	/\.env/,
	/\.env\./,
	/\.secret/,
	/\.key/,
	/\.pem/,
	/\.p12/,
	/\.pfx/,
	/\.crt/,
	/\.log/,
	/\.tgz/,
	/\.lcov/,
	/\.sqlite/,
	/package-lock\.json$/,
	/bun\.lock$/,
	/yarn\.lock$/,
	/pnpm-lock\.yaml$/,
	/tsconfig\.json$/,
	/renovate\.json$/,
	/biome\.json$/,
	/\.pre-commit-config\.yaml$/,
	/\.nojekyll$/,
	/\.gitignore$/,
	/\.gitattributes$/,
	/\.editorconfig$/,
	/accounts\.json$/,
	/sessions\.json$/,
	/delegation-.*\.json$/,
	/\.codex\/skills\/babysit-pr$/,
];

function shouldIndexFile(filePath: string): boolean {
	const relativePath = relative(REPO_ROOT, filePath);
	const parts = relativePath.split("/");

	for (const part of parts) {
		if (EXCLUDED_DIRS.has(part)) return false;
	}

	for (const pattern of EXCLUDED_FILE_PATTERNS) {
		if (pattern.test(relativePath)) return false;
	}

	const ext = extname(filePath).toLowerCase();
	return SUPPORTED_EXTS.has(ext);
}

function walk(dir: string): string[] {
	const files: string[] = [];
	const entries = readdirSync(dir, { withFileTypes: true });

	for (const entry of entries) {
		const fullPath = resolve(dir, entry.name);
		if (entry.isDirectory()) {
			const relativePath = relative(REPO_ROOT, fullPath);
			if (EXCLUDED_DIRS.has(entry.name)) continue;
			if (relativePath === "") continue;
			files.push(...walk(fullPath));
		} else if (entry.isFile()) {
			if (shouldIndexFile(fullPath)) {
				files.push(fullPath);
			}
		}
	}

	return files;
}

function chunkText(text: string, maxSize: number, overlap: number): string[] {
	const normalized = text.replace(/\r\n/g, "\n").trim();
	if (normalized.length === 0) return [];
	if (normalized.length <= maxSize) return [normalized];

	const chunks: string[] = [];
	let start = 0;

	while (start < normalized.length) {
		let end = Math.min(start + maxSize, normalized.length);
		if (end < normalized.length) {
			const nextBreak = normalized.lastIndexOf("\n\n", end);
			if (nextBreak !== -1 && nextBreak > start) {
				end = nextBreak + 2;
			} else {
				const nextLine = normalized.lastIndexOf("\n", end);
				if (nextLine !== -1 && nextLine > start) {
					end = nextLine + 1;
				}
			}
		}
		chunks.push(normalized.slice(start, end).trim());
		start += maxSize - overlap;
		if (start >= end) start = end;
	}

	return chunks.filter((chunk) => chunk.length > 0);
}

function chunkMarkdown(text: string): string[] {
	const normalized = text.replace(/\r\n/g, "\n").trim();
	if (normalized.length === 0) return [];

	const sections = normalized.split(/(?=\n*^#{1,4} .+$)/m);
	const chunks: string[] = [];

	for (const section of sections) {
		const trimmed = section.trim();
		if (trimmed.length === 0) continue;
		if (trimmed.length <= MAX_CHUNK_SIZE) {
			chunks.push(trimmed);
			continue;
		}

		const paragraphs = trimmed.split(/\n\n+/);
		for (const paragraph of paragraphs) {
			if (paragraph.length <= MAX_CHUNK_SIZE) {
				if (paragraph.trim().length > 0) chunks.push(paragraph.trim());
				continue;
			}
			chunks.push(...chunkText(paragraph, MAX_CHUNK_SIZE, CHUNK_OVERLAP));
		}
	}

	return chunks.filter((chunk) => chunk.length > 0);
}

function chunkByFileType(filePath: string, content: string): string[] {
	const ext = extname(filePath).toLowerCase();
	if (ext === ".md") {
		return chunkMarkdown(content);
	}
	return chunkText(content, MAX_CHUNK_SIZE, CHUNK_OVERLAP);
}

async function createEmbeddings(chunks: string[]): Promise<number[][]> {
	const apiKey = process.env.OPENAI_API_KEY;
	if (!apiKey) {
		throw new Error("OPENAI_API_KEY is not set");
	}

	const openai = new OpenAI({ apiKey });
	const embeddings: number[][] = [];

	for (let i = 0; i < chunks.length; i += EMBEDDING_BATCH_SIZE) {
		const batch = chunks.slice(i, i + EMBEDDING_BATCH_SIZE);
		const response = await openai.embeddings.create({
			model: EMBEDDING_MODEL,
			input: batch,
			encoding_format: "float",
		});
		for (const item of response.data) {
			embeddings.push(item.embedding);
		}
	}

	return embeddings;
}

function indexRepository() {
	const filePaths = walk(REPO_ROOT);
	console.log(`Found ${filePaths.length} supported files`);

	const allChunks: { path: string; text: string }[] = [];

	for (const filePath of filePaths) {
		try {
			const content = readFileSync(filePath, "utf-8");
			const chunks = chunkByFileType(filePath, content);
			for (const text of chunks) {
				allChunks.push({
					path: relative(REPO_ROOT, filePath),
					text,
				});
			}
			console.log(`  ${relative(REPO_ROOT, filePath)}: ${chunks.length} chunks`);
		} catch (error) {
			console.error(`  Failed to read ${filePath}: ${error}`);
		}
	}

	console.log(`Total chunks to embed: ${allChunks.length}`);

	return allChunks;
}

async function main() {
	const apiKey = process.env.OPENAI_API_KEY;
	if (!apiKey) {
		console.error("OPENAI_API_KEY is not set. Copy .env.example to .env and add your key.");
		process.exit(1);
	}

	const chunks = indexRepository();
	if (chunks.length === 0) {
		console.error("No chunks found to index.");
		process.exit(1);
	}

	const texts = chunks.map((c) => c.text);
	const embeddings = await createEmbeddings(texts);

	const indexedChunks = chunks.map((chunk, index) => ({
		path: chunk.path,
		text: chunk.text,
		embedding: embeddings[index],
	}));

	mkdirSync(DATA_DIR, { recursive: true });
	writeFileSync(
		INDEX_PATH,
		JSON.stringify({
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
