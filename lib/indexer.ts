import { readdirSync, readFileSync, statSync } from "node:fs";
import { extname, relative, resolve } from "node:path";

export const MAX_CHUNK_SIZE = 1000;
export const CHUNK_OVERLAP = 150;
const MAX_GITHUB_ITEMS_PER_TYPE = 100;
const MAX_GITHUB_BODY_CHARS = 6000;
const MAX_GITHUB_CHUNKS_PER_ITEM = 4;
const MAX_GITHUB_CHUNKS_PER_TYPE = 200;
const MAX_GITHUB_PAGES = 10;
const MAX_LOCAL_FILE_BYTES = 1024 * 1024;
const MAX_LOCAL_INPUT_BYTES = 20 * 1024 * 1024;
const MAX_LOCAL_CHUNKS = 5000;

export const SUPPORTED_EXTS = new Set([
	".md",
	".txt",
	".json",
	".jsonc",
	".yaml",
	".yml",
	".toml",
	".sh",
	".ps1",
	".ts",
	".js",
]);

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
	metadata: ChunkMetadata;
};

export type DocumentType = "documentation" | "issue" | "pull_request" | "cli_help" | "example_config" | "source";

export type ChunkMetadata = {
	type: DocumentType;
	author?: string;
	url?: string;
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
	if (!Number.isInteger(maxSize) || maxSize <= 0 || !Number.isInteger(overlap) || overlap < 0 || overlap >= maxSize) {
		throw new Error("Chunk size must be positive and overlap must be between zero and chunk size");
	}
	const normalized = text.replace(/\r\n/g, "\n").trim();
	if (normalized.length === 0) return [];
	if (normalized.length <= maxSize) return [normalized];

	const chunks: string[] = [];
	let start = 0;

	while (start < normalized.length) {
		let end = Math.min(start + maxSize, normalized.length);
		if (end < normalized.length) {
			const nextBreak = normalized.lastIndexOf("\n\n", end - 2);
			if (nextBreak !== -1 && nextBreak + 2 > start + overlap) {
				end = nextBreak + 2;
			} else {
				const nextLine = normalized.lastIndexOf("\n", end - 1);
				if (nextLine !== -1 && nextLine + 1 > start + overlap) {
					end = nextLine + 1;
				}
			}
		}
		chunks.push(normalized.slice(start, end));
		if (end === normalized.length) break;
		start = Math.max(end - overlap, start + 1);
	}

	return chunks.filter((chunk) => chunk.trim().length > 0);
}

export function chunkMarkdown(text: string): string[] {
	return chunkText(text, MAX_CHUNK_SIZE, CHUNK_OVERLAP);
}

export function chunkByFileType(filePath: string, content: string): string[] {
	const ext = extname(filePath).toLowerCase();
	if (ext === ".md") {
		return chunkMarkdown(content);
	}
	return chunkText(content, MAX_CHUNK_SIZE, CHUNK_OVERLAP);
}

function classifyPath(path: string): DocumentType {
	if (path === "cli.sh" || path === "generate.sh") return "cli_help";
	if (path.startsWith("configs/")) return "example_config";
	if (path === "README.md" || path === "SOUL.md" || path.startsWith("CHANGELOG") || path.startsWith("docs/")) {
		return "documentation";
	}
	return "source";
}

function localSourceUrl(path: string): string {
	const repo = process.env.GITHUB_REPOSITORY ?? "jellydn/my-ai-tools";
	const sourceRef = process.env.GITHUB_SOURCE_REF?.trim() || "main";
	const encodedPath = path.split("/").map(encodeURIComponent).join("/");
	return `https://github.com/${repo}/blob/${encodeURIComponent(sourceRef)}/${encodedPath}`;
}

export function indexRepository(repoRoot: string): Chunk[] {
	const filePaths = walk(repoRoot, repoRoot);
	console.log(`Found ${filePaths.length} supported files`);

	const allChunks: Chunk[] = [];
	let totalInputBytes = 0;

	for (const filePath of filePaths) {
		try {
			const fileBytes = statSync(filePath).size;
			if (fileBytes > MAX_LOCAL_FILE_BYTES) {
				throw new Error(`File exceeds ${MAX_LOCAL_FILE_BYTES} byte indexing limit; exclude or split it`);
			}
			totalInputBytes += fileBytes;
			if (totalInputBytes > MAX_LOCAL_INPUT_BYTES) {
				throw new Error(`Repository exceeds ${MAX_LOCAL_INPUT_BYTES} byte indexing limit`);
			}
			const content = readFileSync(filePath, "utf-8");
			const chunks = chunkByFileType(filePath, content);
			if (allChunks.length + chunks.length > MAX_LOCAL_CHUNKS) {
				throw new Error(`Repository exceeds ${MAX_LOCAL_CHUNKS} local chunk indexing limit`);
			}
			for (const text of chunks) {
				const path = relative(repoRoot, filePath);
				allChunks.push({
					path,
					text,
					metadata: { type: classifyPath(path), url: localSourceUrl(path) },
				});
			}
			console.log(`  ${relative(repoRoot, filePath)}: ${chunks.length} chunks`);
		} catch (error) {
			throw new Error(`Failed to index ${relative(repoRoot, filePath)}: ${error}`);
		}
	}

	console.log(`Total chunks to embed: ${allChunks.length}`);
	return allChunks;
}

type GitHubItem = {
	number: number;
	title: string;
	body: string | null;
	state: string;
	html_url: string;
	user: { login: string } | null;
};

async function fetchGitHubPage(url: string): Promise<GitHubItem[]> {
	const headers: Record<string, string> = {
		Accept: "application/vnd.github+json",
		"User-Agent": "my-ai-tools-indexer",
	};
	const token = process.env.GITHUB_TOKEN?.trim();
	if (token) headers.Authorization = `Bearer ${token}`;

	for (let attempt = 1; attempt <= 2; attempt++) {
		try {
			const response = await fetch(url, { headers, signal: AbortSignal.timeout(10_000) });
			if (!response.ok) {
				throw new Error(`GitHub API returned ${response.status} ${response.statusText}`);
			}
			return (await response.json()) as GitHubItem[];
		} catch (error) {
			if (attempt === 2) throw error;
			await new Promise((resolve) => setTimeout(resolve, 500));
		}
	}
	return [];
}

function chunkGitHubItem(item: GitHubItem, type: "issue" | "pull_request"): Chunk[] {
	const label = type === "issue" ? "Issue" : "Pull Request";
	const path = type === "issue" ? `issues/${item.number}` : `pull/${item.number}`;
	const body = (item.body ?? "No description provided.").slice(0, MAX_GITHUB_BODY_CHARS);
	const content = `# ${label} #${item.number}: ${item.title}\n\nState: ${item.state}\nAuthor: ${item.user?.login ?? "unknown"}\n\n${body}`;
	return chunkMarkdown(content)
		.slice(0, MAX_GITHUB_CHUNKS_PER_ITEM)
		.map((text) => ({
			path,
			text,
			metadata: {
				type,
				author: item.user?.login,
				url: item.html_url,
			},
		}));
}

function selectGitHubChunks(items: GitHubItem[], type: "issue" | "pull_request"): Chunk[] {
	const chunksByItem = items.map((item) => chunkGitHubItem(item, type));
	const summaries = chunksByItem.flatMap((chunks) => chunks.slice(0, 1));
	const details = chunksByItem.flatMap((chunks) => chunks.slice(1));
	return [...summaries, ...details].slice(0, MAX_GITHUB_CHUNKS_PER_TYPE);
}

export async function indexGitHub(repo = process.env.GITHUB_REPOSITORY ?? "jellydn/my-ai-tools"): Promise<Chunk[]> {
	if (!/^[\w.-]+\/[\w.-]+$/.test(repo)) {
		throw new Error(`Invalid GITHUB_REPOSITORY: ${repo}`);
	}

	try {
		const issues: GitHubItem[] = [];
		for (let page = 1; issues.length < MAX_GITHUB_ITEMS_PER_TYPE && page <= MAX_GITHUB_PAGES; page++) {
			const items = await fetchGitHubPage(
				`https://api.github.com/repos/${repo}/issues?state=all&sort=created&direction=desc&per_page=100&page=${page}`,
			);
			issues.push(...items.filter((item) => !("pull_request" in item)));
			if (items.length < 100) break;
		}
		issues.splice(MAX_GITHUB_ITEMS_PER_TYPE);
		if (issues.length < MAX_GITHUB_ITEMS_PER_TYPE) {
			console.warn(`GitHub issue scan found ${issues.length} issues after at most ${MAX_GITHUB_PAGES} pages`);
		}
		const pulls = await fetchGitHubPage(
			`https://api.github.com/repos/${repo}/pulls?state=all&sort=created&direction=desc&per_page=${MAX_GITHUB_ITEMS_PER_TYPE}`,
		);
		const chunks = [...selectGitHubChunks(issues, "issue"), ...selectGitHubChunks(pulls, "pull_request")];
		console.log(`GitHub: ${issues.length} issues, ${pulls.length} pull requests, ${chunks.length} bounded chunks`);
		return chunks;
	} catch (error) {
		console.warn(`GitHub documents were not indexed: ${error}`);
		return [];
	}
}

export async function indexKnowledgeBase(repoRoot: string): Promise<Chunk[]> {
	const localChunks = indexRepository(repoRoot);
	const githubChunks = await indexGitHub();
	const chunks = [...localChunks, ...githubChunks];
	console.log(`Total chunks to embed: ${chunks.length}`);
	return chunks;
}

export function isTextFile(filePath: string): boolean {
	try {
		const stat = statSync(filePath);
		return stat.isFile() && stat.size < 1024 * 1024;
	} catch {
		return false;
	}
}
