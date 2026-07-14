import type { SemanticChunk } from "./chunker.ts";
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

type TreeEntry = {
	path: string;
	type: "blob" | "tree";
	size?: number;
};

const EXCLUDED_PATHS =
	/(^|\/)(node_modules|dist|build|coverage|vendor|\.next|\.git|fixtures?|snapshots?|generated)(\/|$)/;
const SUPPORTED_FILE = /\.(?:ts|tsx|md)$/i;
const MAX_FILE_SIZE = 100_000;
const MAX_FILES_PER_REPOSITORY = 100;

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
			response.headers.get("x-ratelimit-remaining") === "0" ? " Set GITHUB_TOKEN for a higher limit." : "";
		throw new Error(`GitHub request failed (${response.status} ${response.statusText}).${rateLimit}`);
	}
	return (await response.json()) as T;
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
	return language * 3 + Math.log10(repo.stargazers_count + 1) + recency + Math.min(repo.size / 10_000, 1);
}

export async function resolveRepositories(target: string, limit: number): Promise<Repository[]> {
	const parts = target.split("/").filter(Boolean);
	if (parts.length === 2) {
		return [toRepository(await github<GitHubRepository>(`/repos/${parts[0]}/${parts[1]}`))];
	}
	if (parts.length !== 1) throw new Error("Target must be a GitHub user or owner/repository.");

	const repos = await github<GitHubRepository[]>(`/users/${parts[0]}/repos?per_page=100&sort=pushed`);
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

export async function fetchRepositoryChunks(repo: Repository): Promise<SemanticChunk[]> {
	const tree = await github<{ tree: TreeEntry[]; truncated: boolean }>(
		`/repos/${repo.fullName}/git/trees/${encodeURIComponent(repo.defaultBranch)}?recursive=1`,
	);
	if (tree.truncated) throw new Error(`${repo.fullName} has too many files for the GitHub tree API.`);

	const files = tree.tree
		.filter(
			(entry) =>
				entry.type === "blob" &&
				SUPPORTED_FILE.test(entry.path) &&
				!EXCLUDED_PATHS.test(entry.path) &&
				(entry.size ?? 0) <= MAX_FILE_SIZE,
		)
		.sort((a, b) => {
			const readmeDifference = Number(/^README\.md$/i.test(b.path)) - Number(/^README\.md$/i.test(a.path));
			return readmeDifference || (a.size ?? 0) - (b.size ?? 0);
		})
		.slice(0, MAX_FILES_PER_REPOSITORY);

	const chunks: SemanticChunk[] = [];
	for (let index = 0; index < files.length; index += 8) {
		const batch = files.slice(index, index + 8);
		const results = await Promise.all(
			batch.map(async (file) => chunkFile(repo.fullName, file.path, await fetchText(repo, file.path))),
		);
		chunks.push(...results.flat());
	}
	return chunks;
}
