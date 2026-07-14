#!/usr/bin/env bun

import { writeFile } from "node:fs/promises";
import { parseArgs } from "node:util";
import {
	fetchRepositoryChunks,
	parseRepositoryLanguage,
	parseRepositorySort,
	resolveRepositories,
} from "../lib/code-taste/github.ts";
import { buildProfile, loadProfile, profileToMarkdown, saveProfile } from "../lib/code-taste/profile.ts";

const HELP = `GitHub Coding Taste Generator

Usage:
  code-taste analyze <github-user|owner/repository> [--repos 3] [--max-chunks 40] [--sort representative] [--language TypeScript]
  code-taste export [--format markdown|json] [--output CODING_TASTE.md]

Environment:
  OPENAI_API_KEY          Required (OpenAI or OpenRouter sk-or-v1-...)
  OPENAI_BASE_URL         Optional; e.g. https://openrouter.ai/api/v1 for OpenRouter
  OPENAI_MODEL            Analysis model (default: gpt-4o-mini)
  OPENAI_EMBEDDING_MODEL  Embedding model (default: text-embedding-3-small)
  GITHUB_TOKEN            Optional; increases GitHub API rate limits

  --sort                  representative (default), stars, updated, size, name
  --language              Primary GitHub language (e.g. TypeScript, JavaScript, Python; aliases ts, js, py)

  See docs/code-taste-openrouter.md for OpenRouter setup (.env.example has sample values).
`;

function positiveInteger(value: string | undefined, fallback: number, option: string): number {
	if (value === undefined) return fallback;
	const parsed = Number(value);
	if (!Number.isInteger(parsed) || parsed < 1) throw new Error(`${option} must be a positive integer.`);
	return parsed;
}

async function analyze(args: string[]): Promise<void> {
	const parsed = parseArgs({
		args,
		allowPositionals: true,
		options: {
			repos: { type: "string" },
			"max-chunks": { type: "string" },
			sort: { type: "string" },
			language: { type: "string" },
		},
	});
	const target = parsed.positionals[0];
	if (!target) throw new Error("Missing GitHub user or owner/repository.");
	const repositoryLimit = positiveInteger(parsed.values.repos, 3, "--repos");
	const maximumChunks = positiveInteger(parsed.values["max-chunks"], 40, "--max-chunks");
	const repositorySort = parseRepositorySort(parsed.values.sort);
	const repositoryLanguage = parseRepositoryLanguage(parsed.values.language);

	const filterNote = repositoryLanguage ? `, language: ${repositoryLanguage}` : "";
	console.log(`Selecting up to ${repositoryLimit} repositories for ${target} (sort: ${repositorySort}${filterNote})...`);
	const repositories = await resolveRepositories(target, repositoryLimit, repositorySort, repositoryLanguage);
	if (repositories.length === 0) throw new Error("No representative public repositories found.");
	console.log(`Selected: ${repositories.map((repo) => repo.fullName).join(", ")}`);
	console.log(`Analyzing ${repositories.map((repo) => repo.fullName).join(", ")}...`);

	const chunks = [];
	let oversizedUnits = 0;
	for (const repository of repositories) {
		const stats = { oversizedUnits: 0 };
		try {
			const repositoryChunks = await fetchRepositoryChunks(repository, stats);
			const skipped = stats.oversizedUnits > 0 ? `, ${stats.oversizedUnits} oversized units skipped` : "";
			console.log(`  ${repository.fullName}: ${repositoryChunks.length} semantic chunks${skipped}`);
			oversizedUnits += stats.oversizedUnits;
			chunks.push(...repositoryChunks);
		} catch (error) {
			const message = error instanceof Error ? error.message : String(error);
			console.warn(`Skipping ${repository.fullName}: ${message}`);
		}
	}
	if (chunks.length === 0) throw new Error("No TypeScript, TSX, or Markdown chunks found.");
	if (oversizedUnits > 0) {
		console.warn(`Skipped ${oversizedUnits} oversized semantic units; large-unit fallback is not yet supported.`);
	}

	console.log(`Embedding ${chunks.length} chunks and analyzing up to ${maximumChunks} representative chunks...`);
	const profile = await buildProfile(target, repositories, chunks, maximumChunks);
	await saveProfile(profile);
	await writeFile("CODING_TASTE.md", profileToMarkdown(profile), "utf-8");
	console.log(`Generated ${profile.preferences.length} preferences in CODING_TASTE.md.`);
}

async function exportProfile(args: string[]): Promise<void> {
	const parsed = parseArgs({
		args,
		options: {
			format: { type: "string", default: "markdown" },
			output: { type: "string" },
		},
	});
	const profile = await loadProfile();
	const format = parsed.values.format;
	if (format !== "markdown" && format !== "json") throw new Error("--format must be markdown or json.");
	const output = parsed.values.output ?? (format === "markdown" ? "CODING_TASTE.md" : "CODING_TASTE.json");
	const content = format === "markdown" ? profileToMarkdown(profile) : `${JSON.stringify(profile, null, 2)}\n`;
	await writeFile(output, content, "utf-8");
	console.log(`Exported ${output}.`);
}

async function main(): Promise<void> {
	const [command, ...args] = process.argv.slice(2);
	if (!command || command === "--help" || command === "-h") {
		console.log(HELP);
		return;
	}
	if (command === "analyze") return analyze(args);
	if (command === "export") return exportProfile(args);
	throw new Error(`Unknown command: ${command}\n\n${HELP}`);
}

main().catch((error) => {
	if (error instanceof Error && error.name === "ZodError") {
		console.error(
			"code-taste: model returned JSON that failed validation. Try a stronger OPENAI_MODEL or increase --max-chunks.",
		);
	} else {
		console.error(`code-taste: ${error instanceof Error ? error.message : String(error)}`);
	}
	process.exitCode = 1;
});
