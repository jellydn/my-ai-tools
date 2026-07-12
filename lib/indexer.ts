import { readdirSync, readFileSync, statSync } from "node:fs";
import { extname, relative, resolve } from "node:path";

export const MAX_CHUNK_SIZE = 1000;
export const CHUNK_OVERLAP = 200;

export const SUPPORTED_EXTS = new Set([".md", ".txt", ".json", ".yaml", ".yml", ".sh", ".ps1"]);

export const EXCLUDED_DIRS = new Set([
	".git",
	"node_modules",
	"out",
	"dist",
	"coverage",
	".cache",
	"data",
	"public",
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

export const EXCLUDED_FILE_PATTERNS = [
	/(?:^|\/)\.env(?:$|\.)/,
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

export type Chunk = {
	path: string;
	text: string;
};

export function shouldIndexFile(filePath: string, repoRoot: string): boolean {
	const relativePath = relative(repoRoot, filePath);
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

export function walk(dir: string, repoRoot: string): string[] {
	const files: string[] = [];
	const entries = readdirSync(dir, { withFileTypes: true });

	for (const entry of entries) {
		const fullPath = resolve(dir, entry.name);
		if (entry.isDirectory()) {
			const relativePath = relative(repoRoot, fullPath);
			if (EXCLUDED_DIRS.has(entry.name)) continue;
			if (relativePath === "") continue;
			files.push(...walk(fullPath, repoRoot));
		} else if (entry.isFile()) {
			if (shouldIndexFile(fullPath, repoRoot)) {
				files.push(fullPath);
			}
		}
	}

	return files;
}

export function chunkText(text: string, maxSize: number, overlap: number): string[] {
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

export function chunkMarkdown(text: string): string[] {
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

export function chunkByFileType(filePath: string, content: string): string[] {
	const ext = extname(filePath).toLowerCase();
	if (ext === ".md") {
		return chunkMarkdown(content);
	}
	return chunkText(content, MAX_CHUNK_SIZE, CHUNK_OVERLAP);
}

export function indexRepository(repoRoot: string): Chunk[] {
	const filePaths = walk(repoRoot, repoRoot);
	console.log(`Found ${filePaths.length} supported files`);

	const allChunks: Chunk[] = [];

	for (const filePath of filePaths) {
		try {
			const content = readFileSync(filePath, "utf-8");
			const chunks = chunkByFileType(filePath, content);
			for (const text of chunks) {
				allChunks.push({
					path: relative(repoRoot, filePath),
					text,
				});
			}
			console.log(`  ${relative(repoRoot, filePath)}: ${chunks.length} chunks`);
		} catch (error) {
			console.error(`  Failed to read ${filePath}: ${error}`);
		}
	}

	console.log(`Total chunks to embed: ${allChunks.length}`);
	return allChunks;
}

export function isTextFile(filePath: string): boolean {
	try {
		const stat = statSync(filePath);
		return stat.isFile() && stat.size < 1024 * 1024;
	} catch {
		return false;
	}
}
