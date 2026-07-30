// Day 12 — Prompt Templates Registry CLI Utility
import { z } from "zod";

export interface PromptMessages {
	system: string;
	user: string;
}

export interface PromptVariable {
	name: string;
	type: string;
	required: boolean;
	description: string;
}

export interface PromptTemplate<TVariables> {
	id: string;
	version: string;
	description: string;
	variables: PromptVariable[];
	render: (variables: TVariables) => PromptMessages;
}

// ----------------------------------------------------
// 1. Classify Prompt Template Definition
// ----------------------------------------------------
const classifySchema = z.object({
	content: z.string().min(1, "content is required for classification"),
});
type ClassifyVars = z.infer<typeof classifySchema>;

const classifyPrompt: PromptTemplate<ClassifyVars> = {
	id: "classify-input",
	version: "1.0.0",
	description: "Classify input category for workflow routing.",
	variables: [
		{ name: "content", type: "string", required: true, description: "Content to classify" },
	],
	render: (vars) => {
		// Validate variables at runtime using Zod
		const parsed = classifySchema.parse(vars);
		return {
			system:
				"You are a content routing classifier. Return JSON mapping input to article, meeting, git-diff, email, code, or unknown.",
			user: `Classify this content:\n\n---\n${parsed.content}\n---`,
		};
	},
};

// ----------------------------------------------------
// 2. Summarize Prompt Template Definition
// ----------------------------------------------------
const summarizeSchema = z.object({
	content: z.string().min(1, "content is required for summarization"),
	mode: z.enum(["tldr", "technical"]),
	audience: z.string().optional(),
	maxLength: z.number().int().positive().optional(),
});
type SummarizeVars = z.infer<typeof summarizeSchema>;

const summarizePrompt: PromptTemplate<SummarizeVars> = {
	id: "summarize-content",
	version: "1.0.0",
	description: "Summarize content for a target mode and audience.",
	variables: [
		{ name: "content", type: "string", required: true, description: "Content to summarize" },
		{ name: "mode", type: "tldr | technical", required: true, description: "Style of summary" },
		{ name: "audience", type: "string", required: false, description: "Intended reader" },
		{ name: "maxLength", type: "integer", required: false, description: "Max word count limit" },
	],
	render: (vars) => {
		const parsed = summarizeSchema.parse(vars);
		const constraints: string[] = [];
		if (parsed.audience) constraints.push(`Audience: ${parsed.audience}`);
		if (parsed.maxLength) constraints.push(`Limit summary to ${parsed.maxLength} words.`);

		return {
			system: `You are a summarization assistant. Style: ${parsed.mode}. Output structured JSON only.`,
			user: `Summarize this text:\n---\n${parsed.content}\n---${constraints.length > 0 ? `\n\nConstraints:\n- ${constraints.join("\n- ")}` : ""}`,
		};
	},
};

// ----------------------------------------------------
// 3. Extract Meeting Template Definition
// ----------------------------------------------------
const extractSchema = z.object({
	transcript: z.string().min(1, "transcript is required for extraction"),
});
type ExtractVars = z.infer<typeof extractSchema>;

const extractMeetingPrompt: PromptTemplate<ExtractVars> = {
	id: "extract-meeting",
	version: "1.0.0",
	description: "Extract action items and summaries from meeting transcripts.",
	variables: [
		{
			name: "transcript",
			type: "string",
			required: true,
			description: "Meeting notes or transcript",
		},
	],
	render: (vars) => {
		const parsed = extractSchema.parse(vars);
		return {
			system:
				"You are a meeting assistant. Extract summary, actions (owner, task, due), and blockers as JSON.",
			user: `Transcript:\n"""\n${parsed.transcript}\n"""`,
		};
	},
};

// Central Prompt Registry Mapping
const REGISTRY: Record<string, PromptTemplate<any>> = {
	[classifyPrompt.id]: classifyPrompt,
	[summarizePrompt.id]: summarizePrompt,
	[extractMeetingPrompt.id]: extractMeetingPrompt,
};

function main() {
	console.log("====================================================");
	console.log("    Day 12 — Prompt Templates & Validation");
	console.log("====================================================\n");

	console.log("Registered Prompts:");
	Object.values(REGISTRY).forEach((p) => {
		console.log(`  - [${p.id} v${p.version}] — ${p.description}`);
	});
	console.log("");

	// Demo 1: Render Classify Template
	console.log("----------------------------------------------------");
	console.log("DEMO 1: Rendering Classify Prompt");
	console.log("----------------------------------------------------");
	const classifyOutput = classifyPrompt.render({
		content: "diff --git a/server.ts b/server.ts",
	});
	console.log(`[System]: ${classifyOutput.system}`);
	console.log(`[User]:   ${classifyOutput.user}\n`);

	// Demo 2: Render Summarize Template with Constraints
	console.log("----------------------------------------------------");
	console.log("DEMO 2: Rendering Summarize Prompt");
	console.log("----------------------------------------------------");
	const summarizeOutput = summarizePrompt.render({
		content: "Bun's faster test runner allows parallel suite execution.",
		mode: "technical",
		audience: "TypeScript Developers",
		maxLength: 50,
	});
	console.log(`[System]: ${summarizeOutput.system}`);
	console.log(`[User]:\n${summarizeOutput.user}\n`);

	// Demo 3: Render Extract Meeting Template
	console.log("----------------------------------------------------");
	console.log("DEMO 3: Rendering Extract Meeting Prompt");
	console.log("----------------------------------------------------");
	const extractOutput = extractMeetingPrompt.render({
		transcript: "Alex: I will ship the DB migrations on Friday.",
	});
	console.log(`[System]: ${extractOutput.system}`);
	console.log(`[User]:\n${extractOutput.user}\n`);

	// Demo 4: Runtime Input Validation Failure
	console.log("----------------------------------------------------");
	console.log("DEMO 4: Validation Failure Prevention (Runtime Check)");
	console.log("----------------------------------------------------");
	try {
		console.log("Attempting to render Summarize with empty content...");
		summarizePrompt.render({
			content: "", // Trigger zod validation error
			mode: "tldr",
		});
	} catch (error: any) {
		console.log(`\n[Validation Blocked]:\n  ZodError: ${error.message}`);
	}
}

main();
