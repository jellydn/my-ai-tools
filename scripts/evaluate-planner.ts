// Day 17 — Planning vs Execution: Plan-Execute-Replan-Reflect Evaluator

export type PlanTool = "list_files" | "read_file" | "search_code" | "answer";

export type PlanStep = {
	id: number;
	description: string;
	tool: PlanTool;
	input?: Record<string, string | number | boolean>;
};

export type Plan = {
	question: string;
	steps: PlanStep[];
	createdAt: number;
};

export type ExecutionStatus = "success" | "error" | "skipped" | "empty";

export type ExecutionResult = {
	stepId: number;
	status: ExecutionStatus;
	tool: PlanTool;
	summary: string;
};

export type PlanReflection = {
	totalSteps: number;
	executedSteps: number;
	successfulSteps: number;
	emptyResults: number;
	failedSteps: number;
	couldSimplify: boolean;
	simplificationNote: string;
};

// ── Mock Repository Environment ──────────────────────────────────────
const MOCK_FILES: Record<string, string> = {
	"src/config.ts": "export const jwtSecret = process.env.JWT_SECRET || 'secret';",
	"src/auth.ts": "import { jwtSecret } from './config';",
};

// ── Planner Module ───────────────────────────────────────────────────

function createPlan(question: string): Plan {
	const lower = question.toLowerCase();
	const steps: PlanStep[] = [];

	if (lower.includes("what is typescript")) {
		steps.push({ id: 1, description: "Answer conceptual question directly", tool: "answer" });
	} else if (lower.includes("jwt") || lower.includes("auth")) {
		steps.push({
			id: 1,
			description: "Search for 'jwtSecret' in codebase",
			tool: "search_code",
			input: { query: "jwtSecret" },
		});
		steps.push({
			id: 2,
			description: "Read config implementation",
			tool: "read_file",
			input: { path: "src/config.ts" },
		});
		steps.push({
			id: 3,
			description: "Read auth handler implementation",
			tool: "read_file",
			input: { path: "src/auth.ts" },
		});
		steps.push({ id: 4, description: "Summarize findings", tool: "answer" });
	} else {
		steps.push({
			id: 1,
			description: `Search for '${question}'`,
			tool: "search_code",
			input: { query: question },
		});
		steps.push({ id: 2, description: "Read matched file", tool: "read_file" });
		steps.push({ id: 3, description: "Summarize results", tool: "answer" });
	}

	return { question, steps, createdAt: Date.now() };
}

function shouldReplan(results: ExecutionResult[]): boolean {
	return results.some((r) => r.status === "empty");
}

function replan(oldPlan: Plan, results: ExecutionResult[]): Plan {
	const emptyStep = results.find((r) => r.status === "empty");
	console.log(
		`\n[DYNAMIC REPLANNING] Step ${emptyStep?.stepId} returned empty results. Revising plan...`,
	);

	const revisedSteps: PlanStep[] = [
		{
			id: 1,
			description: "Discover file structure in src/",
			tool: "list_files",
			input: { path: "src" },
		},
		{ id: 2, description: "Summarize negative discovery results", tool: "answer" },
	];

	return { question: oldPlan.question, steps: revisedSteps, createdAt: Date.now() };
}

function executePlan(plan: Plan): { results: ExecutionResult[]; finalAnswer?: string } {
	console.log(`\n[PLAN CREATED] Goal: "${plan.question}"`);
	plan.steps.forEach((s) => console.log(`  Step ${s.id}: ${s.description} (${s.tool})`));

	const results: ExecutionResult[] = [];
	let finalAnswer: string | undefined;

	for (const step of plan.steps) {
		if (step.tool === "answer") {
			results.push({
				stepId: step.id,
				status: "success",
				tool: "answer",
				summary: "Answer delivered.",
			});
			finalAnswer = `Summary answer for '${plan.question}' based on evidence.`;
			console.log(`  Step ${step.id} [ACT]: Executed 'answer' -> Done.`);
			break;
		}

		if (step.tool === "search_code") {
			const query = String(step.input?.query ?? "");
			const matches = Object.keys(MOCK_FILES).filter((p) => MOCK_FILES[p].includes(query));
			if (matches.length === 0) {
				results.push({
					stepId: step.id,
					status: "empty",
					tool: "search_code",
					summary: `No matches for '${query}'`,
				});
				console.log(`  Step ${step.id} [ACT]: search_code('${query}') -> Status: EMPTY`);
				break; // Stop and trigger replanning
			}
			results.push({
				stepId: step.id,
				status: "success",
				tool: "search_code",
				summary: `Found matches in ${matches.join(", ")}`,
			});
			console.log(
				`  Step ${step.id} [ACT]: search_code('${query}') -> Matches: ${matches.join(", ")}`,
			);
		} else if (step.tool === "read_file") {
			const path = String(step.input?.path ?? "");
			const content = MOCK_FILES[path];
			if (!content) {
				results.push({
					stepId: step.id,
					status: "error",
					tool: "read_file",
					summary: `File ${path} not found`,
				});
				console.log(`  Step ${step.id} [ACT]: read_file('${path}') -> Status: ERROR`);
			} else {
				results.push({
					stepId: step.id,
					status: "success",
					tool: "read_file",
					summary: `Read ${content.length} bytes`,
				});
				console.log(
					`  Step ${step.id} [ACT]: read_file('${path}') -> Success (${content.length} bytes)`,
				);
			}
		} else if (step.tool === "list_files") {
			results.push({
				stepId: step.id,
				status: "success",
				tool: "list_files",
				summary: "Listed files in src/",
			});
			console.log(
				`  Step ${step.id} [ACT]: list_files('src') -> Listed ${Object.keys(MOCK_FILES).length} files`,
			);
		}
	}

	return { results, finalAnswer };
}

function reflectOnPlan(plan: Plan, results: ExecutionResult[]): PlanReflection {
	const executed = results.length;
	const success = results.filter((r) => r.status === "success").length;
	const empty = results.filter((r) => r.status === "empty").length;
	const failed = results.filter((r) => r.status === "error").length;
	const skipped = plan.steps.length - executed;

	const couldSimplify = plan.steps.length > 3 && success === plan.steps.length;

	return {
		totalSteps: plan.steps.length,
		executedSteps: executed,
		successfulSteps: success,
		emptyResults: empty,
		failedSteps: failed,
		skippedSteps: skipped,
		couldSimplify,
		simplificationNote: couldSimplify
			? "Steps 2 and 3 could be merged."
			: "Plan step count was optimal.",
	};
}

// ── Main Execution ───────────────────────────────────────────────────

function main() {
	console.log("====================================================");
	console.log("    Day 17 — Planning vs Execution Evaluator (PR #9)");
	console.log("====================================================");

	// Scenario 1: Multi-step Plan Execution
	const plan1 = createPlan("How is JWT authentication configured?");
	const exec1 = executePlan(plan1);
	const refl1 = reflectOnPlan(plan1, exec1.results);
	console.log("\n[PLAN REFLECTION]:", JSON.stringify(refl1, null, 2));

	// Scenario 2: Dynamic Replanning on Empty Search Results
	console.log("\n----------------------------------------------------");
	console.log("SCENARIO 2: Dynamic Replanning on Empty Search");
	console.log("----------------------------------------------------");
	const plan2 = createPlan("GraphQLSchema");
	let exec2 = executePlan(plan2);

	if (shouldReplan(exec2.results)) {
		const revisedPlan = replan(plan2, exec2.results);
		exec2 = executePlan(revisedPlan);
		const refl2 = reflectOnPlan(revisedPlan, exec2.results);
		console.log("\n[REVISED PLAN REFLECTION]:", JSON.stringify(refl2, null, 2));
	}

	// Scenario 3: Conceptual Direct Question (1 step plan)
	console.log("\n----------------------------------------------------");
	console.log("SCENARIO 3: Direct Answer Plan (0 tools)");
	console.log("----------------------------------------------------");
	const plan3 = createPlan("What is TypeScript?");
	const exec3 = executePlan(plan3);
	const refl3 = reflectOnPlan(plan3, exec3.results);
	console.log("\n[PLAN REFLECTION]:", JSON.stringify(refl3, null, 2));
}

main();
