import type { ChunkingStats, SemanticChunk } from "./chunker.ts";
import { chunkFile } from "./chunker.ts";

export type Repository = {
	fullName: string;
	defaultBranch: string;
	description: string | null;
	language: string | null;
	stars: number;
	pushedAt: string;
};

type GitHubRepository = {
	full_name: string;
	default_branch: string;
	description: string | null;
	language: string | null;
	stargazers_count: number;
	pushed_at: string;
	fork: boolean;
	archived: boolean;
	size: number;
};

export type RepositoryFile = {
	path: string;
	type: "blob" | "tree";
	size?: number;
};

type FileBucket =
	| "architecture"
	| "cli"
	| "configuration"
	| "core"
	| "documentation"
	| "other"
	| "tests";

const EXCLUDED_PATHS =
	/(^|\/)(node_modules|dist|build|coverage|vendor|\.next|\.git|fixtures?|snapshots?|generated)(\/|$)/;
const SUPPORTED_FILE = /\.(?:ts|tsx|md)$/i;
const MAX_FILE_SIZE = 100_000;
const MAX_FILES_PER_REPOSITORY = 100;
const BUCKET_LIMITS: Record<FileBucket, number> = {
	core: 30,
	tests: 20,
	cli: 10,
	configuration: 10,
	documentation: 15,
	architecture: 10,
	other: 5,
};

function headers(): Record<string, string> {
	const result: Record<string, string> = {
		Accept: "application/vnd.github+json",
		"X-GitHub-Api-Version": "2022-11-28",
		"User-Agent": "code-taste",
	};
	if (process.env.GITHUB_TOKEN) result.Authorization = `Bearer ${process.env.GITHUB_TOKEN}`;
	return result;
}

async function github<T>(path: string): Promise<T> {
	const response = await fetch(`https://api.github.com${path}`, { headers: headers() });
	if (!response.ok) {
		const rateLimit =
			response.headers.get("x-ratelimit-remaining") === "0"
				? " Set GITHUB_TOKEN for a higher limit."
				: "";
		throw new Error(
			`GitHub request failed (${response.status} ${response.statusText}).${rateLimit}`,
		);
	}
	return (await response.json()) as T;
}

function nextGitHubPage(linkHeader: string | null): string | undefined {
	if (!linkHeader) return undefined;
	const match = /<([^>]+)>;\s*rel="next"/.exec(linkHeader);
	return match?.[1];
}

async function listUserRepositories(username: string): Promise<GitHubRepository[]> {
	const collected: GitHubRepository[] = [];
	let url: string | undefined =
		`https://api.github.com/users/${encodeURIComponent(username)}/repos?per_page=100&sort=pushed`;
	while (url) {
		const response = await fetch(url, { headers: headers() });
		if (!response.ok) {
			const rateLimit =
				response.headers.get("x-ratelimit-remaining") === "0"
					? " Set GITHUB_TOKEN for a higher limit."
					: "";
			throw new Error(
				`GitHub request failed (${response.status} ${response.statusText}).${rateLimit}`,
			);
		}
		collected.push(...((await response.json()) as GitHubRepository[]));
		url = nextGitHubPage(response.headers.get("link"));
	}
	return collected;
}

function toRepository(repo: GitHubRepository): Repository {
	return {
		fullName: repo.full_name,
		defaultBranch: repo.default_branch,
		description: repo.description,
		language: repo.language,
		stars: repo.stargazers_count,
		pushedAt: repo.pushed_at,
	};
}

function representativeScore(repo: GitHubRepository): number {
	const ageInDays = (Date.now() - Date.parse(repo.pushed_at)) / 86_400_000;
	const recency = Math.max(0, 365 - ageInDays) / 365;
	const language = repo.language === "TypeScript" ? 1 : 0;
	return (
		language * 3 + Math.log10(repo.stargazers_count + 1) + recency + Math.min(repo.size / 10_000, 1)
	);
}

function fileBucket(file: RepositoryFile): FileBucket {
	const path = file.path.toLowerCase();
	if (/\.(?:test|spec)\.tsx?$|(^|\/)tests?\//.test(path)) return "tests";
	if (/^readme\.md$|(^|\/)(?:docs?|wiki)\//.test(path)) return "documentation";
	if (/(^|\/)(?:cli|commands?|bin|scripts?)(\/|\.)/.test(path)) return "cli";
	if (/(^|\/)(?:config|configs|settings)(\/|\.)|\.config\.tsx?$/.test(path)) return "configuration";
	if ((file.size ?? 0) >= 12_000) return "architecture";
	if (/(^|\/)(?:src|lib|app|packages)\//.test(path)) return "core";
	return "other";
}

export function fileImportance(path: string): number {
	const lower = path.toLowerCase();
	let score = 0.35;
	if (/(^|\/)(?:src|lib|app|packages)\//.test(lower)) score += 0.25;
	if (/\.(?:test|spec)\.tsx?$|(^|\/)tests?\//.test(lower)) score += 0.2;
	if (/^readme\.md$|(^|\/)(?:docs?|wiki)\//.test(lower)) score += 0.2;
	if (/(^|\/)(?:cli|commands?|bin)(\/|\.)/.test(lower)) score += 0.15;
	if (/(^|\/)index\.tsx?$/.test(lower)) score -= 0.25;
	return Math.max(0, Math.min(score, 1));
}

function fileScore(file: RepositoryFile): number {
	const size = file.size ?? 0;
	const moderateSize = size >= 1_000 && size <= 30_000 ? 1 - Math.abs(size - 10_000) / 20_000 : 0;
	return fileImportance(file.path) * 3 + moderateSize;
}

export function selectRepositoryFiles(
	files: RepositoryFile[],
	maximum = MAX_FILES_PER_REPOSITORY,
): RepositoryFile[] {
	const candidates = files.filter(
		(entry) =>
			entry.type === "blob" &&
			SUPPORTED_FILE.test(entry.path) &&
			!EXCLUDED_PATHS.test(entry.path) &&
			(entry.size ?? 0) <= MAX_FILE_SIZE,
	);
	const selected: RepositoryFile[] = [];
	const selectedPaths = new Set<string>();
	const buckets = (Object.entries(BUCKET_LIMITS) as Array<[FileBucket, number]>).map(
		([bucket, limit]) => ({
			files: candidates
				.filter((file) => fileBucket(file) === bucket)
				.sort((a, b) => fileScore(b) - fileScore(a) || a.path.localeCompare(b.path)),
			limit,
			selected: 0,
		}),
	);

	while (selected.length < maximum) {
		let added = false;
		for (const bucket of buckets) {
			const file = bucket.selected < bucket.limit ? bucket.files[bucket.selected] : undefined;
			if (!file) continue;
			selected.push(file);
			selectedPaths.add(file.path);
			bucket.selected += 1;
			added = true;
			if (selected.length === maximum) return selected;
		}
		if (!added) break;
	}

	const remaining = candidates
		.filter((file) => !selectedPaths.has(file.path))
		.sort((a, b) => fileScore(b) - fileScore(a) || a.path.localeCompare(b.path));
	return [...selected, ...remaining].slice(0, maximum);
}

export async function resolveRepositories(target: string, limit: number): Promise<Repository[]> {
	const parts = target.split("/").filter(Boolean);
	if (parts.length === 2) {
		return [toRepository(await github<GitHubRepository>(`/repos/${parts[0]}/${parts[1]}`))];
	}
	if (parts.length !== 1) throw new Error("Target must be a GitHub user or owner/repository.");
	const username = parts[0];
	if (!username) throw new Error("Target must be a GitHub user or owner/repository.");

	const repos = await listUserRepositories(username);
	return repos
		.filter((repo) => !repo.fork && !repo.archived && repo.size > 0)
		.sort((a, b) => representativeScore(b) - representativeScore(a))
		.slice(0, limit)
		.map(toRepository);
}

async function fetchText(repo: Repository, path: string): Promise<string> {
	const encodedPath = path
		.split("/")
		.map((part) => encodeURIComponent(part))
		.join("/");
	const url = `https://raw.githubusercontent.com/${repo.fullName}/${encodeURIComponent(repo.defaultBranch)}/${encodedPath}`;
	const response = await fetch(url, { headers: { "User-Agent": "code-taste" } });
	if (!response.ok) throw new Error(`Could not download ${repo.fullName}/${path}`);
	return response.text();
}

export async function fetchRepositoryChunks(
	repo: Repository,
	stats?: ChunkingStats,
): Promise<SemanticChunk[]> {
	const tree = await github<{ tree: RepositoryFile[]; truncated: boolean }>(
		`/repos/${repo.fullName}/git/trees/${encodeURIComponent(repo.defaultBranch)}?recursive=1`,
	);
	if (tree.truncated) {
		console.warn(
			`${repo.fullName}: GitHub tree listing was truncated; analyzing a partial file set only.`,
		);
	}

	const files = selectRepositoryFiles(tree.tree);

	const chunks: SemanticChunk[] = [];
	for (let index = 0; index < files.length; index += 8) {
		const batch = files.slice(index, index + 8);
		const results = await Promise.allSettled(
			batch.map(async (file) => ({
				file,
				chunks: await chunkFile(repo.fullName, file.path, await fetchText(repo, file.path), stats),
			})),
		);
		for (let offset = 0; offset < results.length; offset++) {
			const result = results[offset]!;
			const file = batch[offset]!;
			if (result.status === "fulfilled") {
				chunks.push(...result.value.chunks);
				continue;
			}
			const reason = result.reason;
			const message = reason instanceof Error ? reason.message : String(reason);
			console.warn(`Skipping ${repo.fullName}/${file.path}: ${message}`);
		}
	}
	return chunks;
}
