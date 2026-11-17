import type { RepoConfig } from "./config.ts";

export const COMMANDS = [
	"help",
	"status",
	"plan",
	"implement",
	"review",
	"fix-ci",
	"address-review",
	"cancel",
] as const;
export type BotCommand = (typeof COMMANDS)[number];
export type JobState =
	| "queued"
	| "preparing"
	| "analyzing"
	| "implementing"
	| "validating"
	| "publishing"
	| "completed"
	| "failed"
	| "cancelled";
export interface JobEvent {
	state: JobState;
	at: string;
	message?: string;
}
export interface Publication {
	branchPushed?: boolean;
	pullRequestId?: number;
	pullRequestUrl?: string;
	pullRequestTitle?: string;
	pullRequestBody?: string;
	reviewId?: number;
	completionCommentId?: number;
	headSha?: string;
	addressedCommentIds?: number[];
}
export interface Job {
	id: string;
	deliveryId: string;
	owner: string;
	repo: string;
	installationId: number;
	issue: number;
	actor: string;
	command: BotCommand;
	args: string;
	state: JobState;
	createdAt: string;
	updatedAt: string;
	history: JobEvent[];
	config: RepoConfig;
	baseRef: string;
	baseSha: string;
	pullRequestNumber?: number;
	headSha?: string;
	branch?: string;
	commentId?: number;
	publication: Publication;
	errorCode?: string;
	cancelRequested?: boolean;
	retryCount: number;
}
export interface CodingAgent {
	name: string;
	run(input: AgentRunInput): Promise<AgentRunResult>;
	cancel(runId: string): Promise<void> | void;
}
export interface AgentRunInput {
	jobId: string;
	mode: "plan" | "implement" | "review" | "address-review" | "fix-ci";
	instructions: string;
	trustedPolicy: string;
	untrusted: Record<string, unknown>;
	timeout: number;
	maxTurns: number;
	workspace?: string;
	signal?: AbortSignal;
}
export interface AgentRunResult {
	summary: string;
	plan?: string[];
	findings?: ReviewFinding[];
	changedFiles?: string[];
	actionable?: boolean;
	addressedCommentIds?: number[];
}
export interface ReviewFinding {
	path: string;
	line: number;
	body: string;
	priority: "P0" | "P1" | "P2" | "P3";
	confidence: number;
}
export interface Logger {
	info(event: string, data?: Record<string, unknown>): void;
	error(event: string, data?: Record<string, unknown>): void;
}
export interface Metrics {
	increment(name: string, labels?: Record<string, string>): void;
	observe(name: string, value: number): void;
}
export const nullMetrics: Metrics = { increment() {}, observe() {} };
