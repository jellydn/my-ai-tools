import type { PluginAPI } from "@ampcode/plugin";

export const description =
	"Exposes every my-ai-tools workflow as an Amp skill, including code review, planning, documentation, testing, and security workflows.";

const SKILLS = [
	"accountable-engineering",
	"adr",
	"babysit-pr",
	"blindspot-pass",
	"capability-experiments",
	"code-quality-review",
	"code-review",
	"codemap",
	"commit-atomic",
	"context-discovery",
	"doc-search",
	"docs-update",
	"draft-pull-request",
	"git-context",
	"handoffs",
	"implementation-logger",
	"llm-wiki",
	"orchestrating-fusion",
	"pickup",
	"plannotator-setup-goal",
	"portless-local",
	"pr-review",
	"prd",
	"qmd-knowledge",
	"quiz-me",
	"ralph",
	"security-audit",
	"slop",
	"spec-interview",
	"tdd",
	"tmux",
	"visual-pr",
] as const;

export default async function myAiToolsSkills(amp: PluginAPI) {
	for (const skill of SKILLS) {
		await amp.registerSkill({ path: `skills/${skill}` });
	}
}
