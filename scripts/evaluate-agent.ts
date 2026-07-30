// Day 15 — Agent Basics: Observe-Act-Reflect Loop CLI Evaluator

type ToolCall = {
	name: "list_files" | "read_file" | "search_code";
	args: Record<string, string>;
};

type StepBudget = {
	max: number;
	used: number;
	remaining: number;
	consume(toolName: string): { max: number; used: number; remaining: number };
};

function createStepBudget(max: number): StepBudget {
	let used = 0;
	return {
		max,
		get used() {
			return used;
		},
		get remaining() {
			return max - used;
		},
		consume(toolName: string) {
			if (used >= max) {
				throw new Error(
					`Inspection budget exhausted before ${toolName}; answer with the evidence already collected.`,
				);
			}
			used += 1;
			return { max, used, remaining: max - used };
		},
	};
}

// ── Mock Repository Tools ───────────────────────────────────────────

const MOCK_FILES: Record<string, string> = {
	"src/index.ts": "import { router } from './router.ts';\nrouter.init();",
	"src/router.ts": "export const router = { init: () => console.log('Router initialized') };",
	"src/auth/handler.ts":
		"export function handleAuth(req: Request) { return { status: 200, user: 'alice' }; }",
	"docs/architecture.md":
		"# Architecture\nThe system uses a Hono router with JWT authentication handlers.",
};

function listFiles(budget: StepBudget, dir = "."): string {
	const b = budget.consume("list_files");
	const files = Object.keys(MOCK_FILES).filter((f) => f.startsWith(dir === "." ? "" : dir));
	return `[list_files] Found ${files.length} files. Remaining budget: ${b.remaining}\nFiles: ${files.join(", ")}`;
}

function readFile(budget: StepBudget, path: string): string {
	const b = budget.consume("read_file");
	const content = MOCK_FILES[path];
	if (!content) {
		return `[read_file] Error: File '${path}' not found. Remaining budget: ${b.remaining}`;
	}
	return `[read_file] File '${path}' contents:\n${content}\n(Remaining budget: ${b.remaining})`;
}

function searchCode(budget: StepBudget, query: string): string {
	const b = budget.consume("search_code");
	const matches: string[] = [];
	Object.entries(MOCK_FILES).forEach(([path, content]) => {
		if (content.toLowerCase().includes(query.toLowerCase())) {
			matches.push(`${path}: match found`);
		}
	});
	return `[search_code] Query '${query}' returned ${matches.length} matches. Remaining budget: ${b.remaining}\n${matches.join("\n") || "No matches."}`;
}

// ── Agent Decision Engine (Observe -> Act -> Reflect) ─────────────────

type AgentAction = { type: "tool"; call: ToolCall } | { type: "answer"; text: string };

function decideAction(userRequest: string, step: number, history: string[]): AgentAction {
	// Decision heuristic reflecting an LLM function caller
	const lowerReq = userRequest.toLowerCase();

	// Simple query requiring no tools
	if (lowerReq.includes("what is typescript")) {
		return {
			type: "answer",
			text: "TypeScript is a strongly typed programming language that builds on JavaScript.",
		};
	}

	// Multi-step investigation scenario
	if (lowerReq.includes("auth") || lowerReq.includes("authentication")) {
		if (step === 1) {
			return {
				type: "tool",
				call: { name: "search_code", args: { query: "auth" } },
			};
		}
		if (step === 2 && history.some((h) => h.includes("src/auth/handler.ts"))) {
			return {
				type: "tool",
				call: { name: "read_file", args: { path: "src/auth/handler.ts" } },
			};
		}
		return {
			type: "answer",
			text: "Based on repository analysis of src/auth/handler.ts, authentication is handled by `handleAuth` which returns a 200 status with user details.",
		};
	}

	// Exhaustion scenario (searching for nonexistent item)
	return {
		type: "tool",
		call: { name: "search_code", args: { query: `nonexistent_query_${step}` } },
	};
}

function runAgentLoop(userRequest: string, maxSteps = 3) {
	console.log("----------------------------------------------------");
	console.log(`GOAL: "${userRequest}" (Max Step Budget: ${maxSteps})`);
	console.log("----------------------------------------------------");

	const budget = createStepBudget(maxSteps);
	const history: string[] = [];
	let step = 1;
	let finished = false;

	while (!finished) {
		console.log(`\n--- [TURN ${step}] ---`);
		console.log(`1. OBSERVE: Budget remaining ${budget.remaining}/${budget.max}.`);

		let action: AgentAction;
		try {
			action = decideAction(userRequest, step, history);
		} catch (e: any) {
			console.log(`   REFLECT: Exception during decision: ${e.message}`);
			break;
		}

		if (action.type === "answer") {
			console.log(`2. ACT: Decided to answer directly (No tool call).`);
			console.log(`3. REFLECT: Final Answer Delivered:\n   "${action.text}"`);
			finished = true;
			break;
		}

		// Tool Call Action
		const { name, args } = action.call;
		console.log(`2. ACT: Executing tool '${name}' with args ${JSON.stringify(args)}.`);

		let result = "";
		try {
			if (name === "list_files") result = listFiles(budget, args.dir);
			else if (name === "read_file") result = readFile(budget, args.path);
			else if (name === "search_code") result = searchCode(budget, args.query);
		} catch (err: any) {
			console.log(`   [SAFETY BOUND INTERCEPT] ${err.message}`);
			console.log(`3. REFLECT: Budget exhausted! Agent loop forced to terminate safely.`);
			console.log(
				`   Final Answer: "Budget exhausted after ${budget.max} steps before finishing complete search."`,
			);
			finished = true;
			break;
		}

		history.push(result);
		console.log(`3. REFLECT: Received tool observation:\n   ${result.split("\n")[0]}`);

		step++;
		if (step > 10) {
			console.log("   [SAFETY BOUND INTERCEPT] Hard turn limit reached. Terminating.");
			finished = true;
		}
	}
	console.log("");
}

// ── Main ───────────────────────────────────────────────────────────────

function main() {
	console.log("====================================================");
	console.log("    Day 15 — Agent Basics: Observe-Act-Reflect Loop");
	console.log("====================================================\n");

	// Scenario 1: Direct Answer (0 tool calls needed)
	runAgentLoop("What is TypeScript?", 3);

	// Scenario 2: Multi-step tool loop with clean completion
	runAgentLoop("Where is authentication handled in the repo?", 5);

	// Scenario 3: Bounded execution stopping safely on budget exhaustion
	runAgentLoop("Find the legacy GraphQL schema file", 2);
}

main();
