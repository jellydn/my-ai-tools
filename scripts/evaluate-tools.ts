// Day 16 — Tools for Agents: File, Search, and API Tools CLI Evaluator
import { z } from "zod";

export type InspectionMetadata = {
	used: number;
	remaining: number;
	limit: number;
};

export type StepBudget = {
	limit: number;
	used: number;
	remaining: number;
	consume(toolName: string): InspectionMetadata;
};

export function createStepBudget(limit = 8): StepBudget {
	let used = 0;
	return {
		limit,
		get used() {
			return used;
		},
		get remaining() {
			return limit - used;
		},
		consume(toolName) {
			if (used >= limit) {
				throw new Error(
					`Inspection budget exhausted before ${toolName}; answer with evidence already collected. (used=${used}, remaining=0, limit=${limit})`,
				);
			}
			used += 1;
			return { used, remaining: limit - used, limit };
		},
	};
}

export function wrapWithBudget(
	error: unknown,
	tool: string,
	inspection: InspectionMetadata,
): Error {
	const message = error instanceof Error ? error.message : String(error);
	return new Error(
		`${tool} failed: ${message} (inspection: used=${inspection.used}, remaining=${inspection.remaining}, limit=${inspection.limit})`,
	);
}

export function createDebugLogger(enabled: boolean) {
	return {
		log(event: {
			tool: string;
			status: "success" | "error";
			inputSummary: string;
			count?: number;
			inspection: InspectionMetadata;
		}) {
			if (!enabled) return;
			const count = event.count === undefined ? "" : ` count=${event.count}`;
			console.log(
				`[repo-assistant debug] ${event.tool} ${event.status} input=${event.inputSummary}${count} used=${event.inspection.used} remaining=${event.inspection.remaining}/${event.inspection.limit}`,
			);
		},
	};
}

// ── Mock Repository Content ──────────────────────────────────────────
const REPOSITORY_FILES: Record<string, string> = {
	"src/config.ts": `// Server Configuration
export const port = 3000;
export const jwtSecret = process.env.JWT_SECRET || "default_secret_key";
export const maxConnections = 20;`,
	"src/auth.ts": `import { jwtSecret } from "./config";

export function authenticateUser(token: string) {
  if (!token) throw new Error("Missing auth token");
  return { id: "user_123", role: "admin" };
}

export function logout() {
  console.log("User logged out");
}`,
	"docs/api.md": `# API Documentation
- GET /health: Status check
- POST /auth/login: User authentication
- GET /users: List users`,
};

// ── Tool Definitions with Zod Schemas ────────────────────────────────

const listFilesSchema = z.object({
	path: z.string().default("."),
	maxDepth: z.number().int().min(1).max(10).default(2),
});

const readFileSchema = z.object({
	path: z.string().min(1, "Path cannot be empty"),
	startLine: z.number().int().min(1).default(1),
	endLine: z.number().int().min(1).optional(),
});

const searchCodeSchema = z.object({
	query: z.string().min(2, "Query must be at least 2 characters"),
	path: z.string().default("."),
});

// ── Tool Execution Handlers ──────────────────────────────────────────

const budget = createStepBudget(8);
const logger = createDebugLogger(true);

function executeListFiles(rawInput: unknown) {
	const inspection = budget.consume("list_files");
	try {
		const input = listFilesSchema.parse(rawInput);
		const matched = Object.keys(REPOSITORY_FILES).filter((p) =>
			input.path === "." ? true : p.startsWith(input.path),
		);
		const result = {
			path: input.path,
			entries: matched.map((p) => ({ path: p, type: "file", size: REPOSITORY_FILES[p].length })),
			inspection,
		};
		logger.log({
			tool: "list_files",
			status: "success",
			inputSummary: JSON.stringify(input),
			count: matched.length,
			inspection,
		});
		return result;
	} catch (err) {
		logger.log({
			tool: "list_files",
			status: "error",
			inputSummary: JSON.stringify(rawInput),
			inspection,
		});
		throw wrapWithBudget(err, "list_files", inspection);
	}
}

function executeReadFile(rawInput: unknown) {
	const inspection = budget.consume("read_file");
	try {
		const input = readFileSchema.parse(rawInput);
		const content = REPOSITORY_FILES[input.path];
		if (!content) {
			throw new Error(`File '${input.path}' not found in repository.`);
		}

		const lines = content.split("\n");
		const requestedEnd = input.endLine ?? input.startLine + 400 - 1;
		const endLine = Math.min(requestedEnd, lines.length);

		if (endLine < input.startLine) {
			throw new Error("endLine must be greater than or equal to startLine.");
		}

		const selected = lines
			.slice(input.startLine - 1, endLine)
			.map((line, idx) => `${input.startLine + idx}: ${line}`)
			.join("\n");

		const truncated = requestedEnd > endLine || endLine < lines.length;

		const result = {
			path: input.path,
			startLine: input.startLine,
			endLine,
			totalLines: lines.length,
			content: selected,
			truncated,
			inspection,
		};
		logger.log({
			tool: "read_file",
			status: "success",
			inputSummary: JSON.stringify(input),
			count: lines.length,
			inspection,
		});
		return result;
	} catch (err) {
		logger.log({
			tool: "read_file",
			status: "error",
			inputSummary: JSON.stringify(rawInput),
			inspection,
		});
		throw wrapWithBudget(err, "read_file", inspection);
	}
}

function executeSearchCode(rawInput: unknown) {
	const inspection = budget.consume("search_code");
	try {
		const input = searchCodeSchema.parse(rawInput);
		const matches: Array<{ path: string; line: number; excerpt: string }> = [];

		Object.entries(REPOSITORY_FILES).forEach(([path, content]) => {
			if (input.path !== "." && !path.startsWith(input.path)) return;

			const lines = content.split("\n");
			lines.forEach((line, idx) => {
				if (line.toLowerCase().includes(input.query.toLowerCase())) {
					matches.push({
						path,
						line: idx + 1,
						excerpt: line.trim(),
					});
				}
			});
		});

		const result = {
			query: input.query,
			path: input.path,
			matches,
			filesSearched: Object.keys(REPOSITORY_FILES).length,
			inspection,
		};
		logger.log({
			tool: "search_code",
			status: "success",
			inputSummary: JSON.stringify(input),
			count: matches.length,
			inspection,
		});
		return result;
	} catch (err) {
		logger.log({
			tool: "search_code",
			status: "error",
			inputSummary: JSON.stringify(rawInput),
			inspection,
		});
		throw wrapWithBudget(err, "search_code", inspection);
	}
}

// ── Tool Router Engine ──────────────────────────────────────────────

function runTool(name: string, rawInput: unknown) {
	console.log(`\n[TOOL CALL] Requesting tool '${name}' with input:`, JSON.stringify(rawInput));
	try {
		let result: unknown;
		if (name === "list_files") result = executeListFiles(rawInput);
		else if (name === "read_file") result = executeReadFile(rawInput);
		else if (name === "search_code") result = executeSearchCode(rawInput);
		else throw new Error(`Unknown tool '${name}'`);

		console.log(`[SCHEMA VALIDATION & EXECUTION] Passed ✓`);
		console.log(`[FEEDBACK OBSERVATION]:\n${JSON.stringify(result, null, 2)}`);
	} catch (err: any) {
		console.log(`[SCHEMA VALIDATION / EXECUTION ERROR] Failed ✗:\n${err.message}`);
	}
}

// ── Main Execution ───────────────────────────────────────────────────

function main() {
	console.log("====================================================");
	console.log("    Day 16 — Tools for Agents Evaluator (PR #7)");
	console.log("====================================================");

	// 1. Search Tool Execution
	runTool("search_code", { query: "jwtSecret" });

	// 2. Read File Tool Execution (Bounded line range)
	runTool("read_file", { path: "src/auth.ts", startLine: 1, endLine: 5 });

	// 3. List Files Tool Execution
	runTool("list_files", { path: "src" });

	// 4. Test Schema Validation Error with wrapWithBudget
	console.log("\n----------------------------------------------------");
	console.log("TESTING SCHEMA VALIDATION ERROR HANDLING (wrapWithBudget)");
	console.log("----------------------------------------------------");
	runTool("search_code", { query: "a" }); // fails minLength(2)
}

main();
