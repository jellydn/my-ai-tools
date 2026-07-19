import { CodexAgent } from "./agent.ts";
import type { BotConfig } from "./config.ts";
import { parseValidationCommand } from "./config.ts";
import { type GitHubClient, installationClient } from "./github.ts";
import { type PullFile, validateFindings } from "./review.ts";
import { jsonLogger } from "./security.ts";
import { JsonJobStore } from "./store.ts";
import type { AgentRunResult, CodingAgent, Job } from "./types.ts";
import {
	cleanupWorkspace,
	cloneExact,
	createWorkspace,
	inspectDiff,
	pushBranch,
	runArgv,
	trustedInstructions,
} from "./workspace.ts";

const marker = (job: Job) => `<!-- my-ai-bot:job:${job.id} -->`;
const steps = ["preparing", "analyzing", "implementing", "validating", "publishing", "completed"];
const progress = (job: Job, detail = "") =>
	`${marker(job)}\n### my-ai-bot: ${job.state}\n- Command: \`${job.command}${job.args ? ` ${job.args}` : ""}\`\n- Actor / started: @${job.actor} / ${job.createdAt}\n- Progress: ${steps.map((x) => `${steps.indexOf(x) <= steps.indexOf(job.state) ? "✅" : "⬜"} ${x}`).join(" · ")}\n- Branch / PR: ${job.branch ? `\`${job.branch}\`` : "—"} / ${job.publication.pullRequestUrl ?? "—"}${detail ? `\n\n${detail}` : ""}`;
type ClientFactory = (job: Job, signal?: AbortSignal) => Promise<{ client: GitHubClient; token: string }>;
function boundedSignal(timeoutMs: number, parent?: AbortSignal) {
	const controller = new AbortController();
	const abort = () => controller.abort();
	parent?.addEventListener("abort", abort, { once: true });
	const timeout = setTimeout(abort, timeoutMs);
	timeout.unref();
	return {
		signal: controller.signal,
		cleanup: () => {
			clearTimeout(timeout);
			parent?.removeEventListener("abort", abort);
		},
	};
}
export class BotWorker {
	private timer?: ReturnType<typeof setInterval>;
	private stopping = false;
	private controllers = new Map<string, AbortController>();
	constructor(
		private config: BotConfig,
		private store: JsonJobStore,
		private agent: CodingAgent = new CodexAgent(),
		private fetcher: typeof fetch = fetch,
		private clients: ClientFactory = (job, signal) =>
			installationClient(
				config,
				job.installationId,
				fetcher,
				job.command === "review"
					? { contents: "read", issues: "write", pull_requests: "write", actions: "read", checks: "read" }
					: job.command === "plan" || job.command === "help" || job.command === "status"
						? { contents: "read", issues: "write", pull_requests: "read", actions: "read", checks: "read" }
						: { contents: "write", issues: "write", pull_requests: "write", actions: "read", checks: "read" },
				signal,
			),
	) {}
	start() {
		this.timer = setInterval(() => void this.tick(), 500);
		this.timer.unref();
		void this.tick();
	}
	async stop() {
		this.stopping = true;
		if (this.timer) clearInterval(this.timer);
		for (const id of this.controllers.keys()) this.cancel(id);
		while (this.controllers.size) await new Promise((r) => setTimeout(r, 20));
	}
	cancel(id: string) {
		this.controllers.get(id)?.abort();
		void this.agent.cancel(id);
	}
	async reportStatus(job: Job, detail = "Current job status.") {
		const bounded = boundedSignal(10_000);
		try {
			const { client } = await this.clients(job, bounded.signal);
			await this.update(job, client, detail, bounded.signal);
		} finally {
			bounded.cleanup();
		}
	}
	private async comment(job: Job, client: GitHubClient, body: string, signal?: AbortSignal) {
		if (job.commentId)
			await client.request("PATCH", `/repos/${job.owner}/${job.repo}/issues/comments/${job.commentId}`, { body }, signal);
		else {
			const existing = (
				await client.paginate<{ id: number; body?: string }>(
					`/repos/${job.owner}/${job.repo}/issues/${job.issue}/comments`,
					signal,
				)
			).find((comment) => comment.body?.includes(marker(job)));
			if (existing) {
				job = await this.store.patch(job.id, { commentId: existing.id }, "Progress comment reconciled");
				await client.request("PATCH", `/repos/${job.owner}/${job.repo}/issues/comments/${existing.id}`, { body }, signal);
				return job;
			}
			const result = await client.request<{ id: number }>(
				"POST",
				`/repos/${job.owner}/${job.repo}/issues/${job.issue}/comments`,
				{ body },
				signal,
			);
			job = await this.store.patch(job.id, { commentId: result.id }, "Progress comment created");
		}
		return job;
	}
	private async update(job: Job, client: GitHubClient, detail = "", signal?: AbortSignal) {
		const current = this.store.get(job.id) ?? job;
		return this.comment(current, client, progress(current, detail), signal);
	}
	async tick() {
		if (this.stopping) return;
		const job = await this.store.claim(this.config.concurrency);
		if (!job) return;
		const controller = new AbortController();
		this.controllers.set(job.id, controller);
		void this.execute(job, controller.signal).finally(() => this.controllers.delete(job.id));
	}
	private async agentRun(
		job: Job,
		mode: Job["command"] & ("plan" | "implement" | "review" | "address-review" | "fix-ci"),
		instructions: string,
		policy: string,
		untrusted: Record<string, unknown>,
		workspace: string | undefined,
		signal: AbortSignal,
	) {
		return this.agent.run({
			jobId: job.id,
			mode,
			instructions,
			trustedPolicy: policy,
			untrusted,
			workspace,
			timeout: job.config.agent.timeoutSeconds * 1000,
			maxTurns: job.config.agent.maxTurns,
			signal,
		});
	}
	private async issueData(job: Job, client: GitHubClient, signal: AbortSignal) {
		return {
			issue: await client.request<Record<string, unknown>>(
				"GET",
				`/repos/${job.owner}/${job.repo}/issues/${job.issue}`,
				undefined,
				signal,
			),
			comments: await client.paginate(`/repos/${job.owner}/${job.repo}/issues/${job.issue}/comments`, signal),
		};
	}
	private async plan(job: Job, client: GitHubClient, token: string, signal: AbortSignal) {
		const workspace = await createWorkspace(this.config.workspaceRoot);
		try {
			await cloneExact(workspace, job.owner, job.repo, job.baseRef, job.baseSha, token, job.config, signal);
			const data = await this.issueData(job, client, signal);
			const result = await this.agentRun(
				job,
				"plan",
				await trustedInstructions(workspace),
				"Inspect this exact base read-only; never execute repository code. Return a grounded plan whose summary contains exactly these headings: Summary, Current behavior, Proposed changes, Files likely affected, Testing strategy, Risks and open questions, Acceptance criteria.",
				{ ...data, request: job.args, baseSha: job.baseSha },
				workspace,
				signal,
			);
			const headings = [
				"Summary",
				"Current behavior",
				"Proposed changes",
				"Files likely affected",
				"Testing strategy",
				"Risks and open questions",
				"Acceptance criteria",
			];
			if (!headings.every((h) => new RegExp(`(^|\\n)#{1,6} ${h}`, "i").test(result.summary)))
				throw Object.assign(new Error("Plan omitted required headings"), { code: "AGENT_OUTPUT_INVALID" });
			return result.summary;
		} finally {
			await cleanupWorkspace(workspace);
		}
	}
	private async review(job: Job, client: GitHubClient, signal: AbortSignal) {
		const pr = await client.request<any>("GET", `/repos/${job.owner}/${job.repo}/pulls/${job.issue}`, undefined, signal);
		const head = pr.head.sha;
		const existingReview = (
			await client.paginate<{ id: number; body?: string; commit_id?: string }>(
				`/repos/${job.owner}/${job.repo}/pulls/${job.issue}/reviews`,
				signal,
			)
		).find((review) => review.body?.includes(marker(job)) && review.commit_id === head);
		if (existingReview) {
			await this.store.patch(
				job.id,
				{ headSha: head, pullRequestNumber: job.issue, publication: { ...job.publication, reviewId: existingReview.id } },
				"Review reconciled",
			);
			return existingReview.body ?? "Existing review reconciled.";
		}
		const [commits, files, data] = await Promise.all([
			client.paginate(`/repos/${job.owner}/${job.repo}/pulls/${job.issue}/commits`, signal),
			client.paginate<PullFile>(`/repos/${job.owner}/${job.repo}/pulls/${job.issue}/files`, signal),
			this.issueData(job, client, signal),
		]);
		const security = /(^|\s)security(\s|$)/i.test(job.args);
		const result = await this.agentRun(
			job,
			"review",
			"",
			`Review the complete immutable API snapshot only. Never checkout or execute PR code.${security ? " Apply stricter security-review policy: prioritize auth, injection, secret and trust-boundary defects." : ""}`,
			{ pr, commits, files, ...data, request: job.args },
			undefined,
			signal,
		);
		const checked = validateFindings(result.findings ?? [], files, job.config.review.minConfidence);
		const findings = [...checked.inline, ...checked.fallback].slice(0, job.config.review.maxComments);
		const inline = new Set(checked.inline.slice(0, job.config.review.maxComments));
		const fallback = findings.filter((x) => !inline.has(x));
		client = (await this.clients(job, signal)).client;
		const latest = await client.request<any>(
			"GET",
			`/repos/${job.owner}/${job.repo}/pulls/${job.issue}`,
			undefined,
			signal,
		);
		if (latest.head.sha !== head) throw Object.assign(new Error("PR head changed during review"), { code: "STALE_HEAD" });
		const verdict = findings.some((x) => x.priority === "P0" || x.priority === "P1")
			? "Changes requested (advisory COMMENT review)"
			: "No blocking findings";
		const findingSummary = findings.length
			? findings.map((x) => `- [${x.priority}] ${x.body}${x.path ? ` (\`${x.path}:${x.line}\`)` : ""}`).join("\n")
			: "- No findings above the configured confidence threshold.";
		const body = `${marker(job)}\n## Review summary\n${result.summary}\n\n### Findings\n${findingSummary}\n\n### Validation\n- Reviewed ${files.length} files and ${commits.length} commits at \`${head}\`\n- Published ${inline.size} inline finding(s); ${fallback.length} finding(s) required summary fallback\n- Limitation: repository code and tests were not executed\n\n### Verdict\n${verdict}${fallback.length ? `\n\n### Inline fallback details\n${fallback.map((x) => `- [${x.priority}] \`${x.path}:${x.line}\`: ${x.body}`).join("\n")}` : ""}`;
		const posted = await client.request<{ id: number }>(
			"POST",
			`/repos/${job.owner}/${job.repo}/pulls/${job.issue}/reviews`,
			{
				commit_id: head,
				event: "COMMENT",
				body,
				comments: findings
					.filter((x) => inline.has(x))
					.map((x) => ({ path: x.path, line: x.line, side: "RIGHT", body: `**${x.priority}** ${x.body}` })),
			},
			signal,
		);
		await this.store.patch(
			job.id,
			{ headSha: head, pullRequestNumber: job.issue, publication: { ...job.publication, reviewId: posted.id } },
			"Review published",
		);
		return body;
	}
	private priorPublication(job: Job) {
		return this.store
			.list()
			.filter(
				(x) =>
					x.id !== job.id &&
					x.owner === job.owner &&
					x.repo === job.repo &&
					x.command === "implement" &&
					x.state === "completed" &&
					x.publication.pullRequestId === job.issue &&
					x.publication.branchPushed &&
					x.branch?.startsWith(`${job.config.implementation.branchPrefix}/`),
			)
			.sort((a, b) => b.updatedAt.localeCompare(a.updatedAt))[0];
	}
	private async replyToAddressed(job: Job, client: GitHubClient, signal: AbortSignal) {
		const ids = job.publication.addressedCommentIds ?? [];
		if (!ids.length || !job.publication.pullRequestId) return;
		const comments = await client.paginate<{ body?: string; in_reply_to_id?: number }>(
			`/repos/${job.owner}/${job.repo}/pulls/${job.publication.pullRequestId}/comments`,
			signal,
		);
		for (const id of ids) {
			if (comments.some((comment) => comment.in_reply_to_id === id && comment.body?.includes(marker(job)))) continue;
			await client.request(
				"POST",
				`/repos/${job.owner}/${job.repo}/pulls/comments/${id}/replies`,
				{
					body: `${marker(job)}\nAddressed by \`${job.publication.headSha}\`. Validation: ${job.config.validation.commands.join(", ") || "policy checks only"}.`,
				},
				signal,
			);
		}
	}
	private async reconcilePrepared(
		job: Job,
		client: GitHubClient,
		signal: AbortSignal,
		createPr: boolean,
	): Promise<string | undefined> {
		if (!job.branch || !job.publication.headSha) return undefined;
		let remoteHead: string;
		try {
			remoteHead = await client.refSha(job.owner, job.repo, job.branch, signal);
		} catch (error) {
			if ((error as { status?: number }).status === 404) return undefined;
			throw error;
		}
		if (remoteHead !== job.publication.headSha)
			throw Object.assign(new Error("Published branch differs from prepared commit"), {
				code: "PUBLICATION_MISMATCH",
			});
		job = await this.store.patch(
			job.id,
			{ publication: { ...job.publication, branchPushed: true } },
			"Published branch reconciled",
		);
		if (createPr) {
			let pr = (
				await client.request<any[]>(
					"GET",
					`/repos/${job.owner}/${job.repo}/pulls?state=open&head=${encodeURIComponent(`${job.owner}:${job.branch}`)}`,
					undefined,
					signal,
				)
			)[0];
			if (!pr) {
				if (!job.publication.pullRequestTitle || !job.publication.pullRequestBody)
					throw Object.assign(new Error("Prepared pull request metadata is missing"), { code: "PUBLICATION_MISMATCH" });
				pr = await client.request<any>(
					"POST",
					`/repos/${job.owner}/${job.repo}/pulls`,
					{
						title: job.publication.pullRequestTitle,
						head: job.branch,
						base: job.baseRef,
						body: job.publication.pullRequestBody,
						draft: true,
					},
					signal,
				);
			}
			await this.store.patch(
				job.id,
				{
					pullRequestNumber: pr.number,
					publication: { ...job.publication, branchPushed: true, pullRequestId: pr.number, pullRequestUrl: pr.html_url },
				},
				"Draft pull request reconciled",
			);
			return `Recovered draft PR ${pr.html_url}.`;
		}
		await this.replyToAddressed(job, client, signal);
		return `Recovered published commit \`${remoteHead}\`.`;
	}
	private async validateAndPublish(
		job: Job,
		client: GitHubClient,
		token: string,
		workspace: string,
		branch: string,
		result: AgentRunResult,
		signal: AbortSignal,
		createPr: boolean,
	) {
		if (signal.aborted || this.store.get(job.id)?.cancelRequested)
			throw Object.assign(new Error("Job cancelled"), { code: "CANCELLED" });
		const head = (
			await runArgv(["git", "rev-parse", "HEAD"], workspace, job.config, undefined, { signal })
		).stdout.trim();
		if (head !== (job.headSha ?? job.baseSha))
			throw Object.assign(new Error("Agent changed Git history"), { code: "HISTORY_CHANGED" });
		await this.store.transition(job.id, "validating");
		const validations: string[] = [];
		const validationHome = await createWorkspace(this.config.workspaceRoot);
		try {
			for (const command of job.config.validation.commands) {
				const argv = parseValidationCommand(command);
				await runArgv(argv, workspace, job.config, undefined, {
					signal,
					timeoutMs: job.config.agent.timeoutSeconds * 1000,
					maxOutputBytes: 100_000,
					home: validationHome,
				});
				validations.push(`✅ \`${command}\``);
			}
		} finally {
			await cleanupWorkspace(validationHome);
		}
		const inspected = await inspectDiff(workspace, job.config, signal);
		await runArgv(
			["git", "commit", "--no-verify", "-m", `fix: address issue #${job.issue}`],
			workspace,
			job.config,
			undefined,
			{
				signal,
				env: {
					GIT_CONFIG_COUNT: "2",
					GIT_CONFIG_KEY_0: "core.hooksPath",
					GIT_CONFIG_VALUE_0: "/dev/null",
					GIT_CONFIG_KEY_1: "commit.gpgSign",
					GIT_CONFIG_VALUE_1: "false",
				},
			},
		);
		const committedTree = (await runArgv(["git", "rev-parse", "HEAD^{tree}"], workspace, job.config)).stdout.trim();
		if (committedTree !== inspected.tree)
			throw Object.assign(new Error("Committed tree differs from inspected tree"), { code: "TREE_MISMATCH" });
		const newHead = (await runArgv(["git", "rev-parse", "HEAD"], workspace, job.config)).stdout.trim();
		const pullRequestTitle = createPr ? `fix: ${result.summary.slice(0, 60)}` : undefined;
		const pullRequestBody = createPr
			? `## Summary\n${result.summary}\n\n## Changes\n${inspected.names.map((x) => `- \`${x}\``).join("\n")}\n\n## Validation\n${validations.join("\n") || "Not run (none configured)."}\n\n## Risks or limitations\nReview generated changes and validation coverage.\n\nCloses #${job.issue}\n\nGenerated by my-ai-bot.\n${marker(job)}`
			: undefined;
		const publishing = await this.store.transition(job.id, "publishing", {
			branch,
			publication: {
				...this.store.get(job.id)!.publication,
				branchPushed: false,
				headSha: newHead,
				pullRequestId: createPr ? undefined : this.store.get(job.id)?.pullRequestNumber,
				pullRequestTitle,
				pullRequestBody,
				addressedCommentIds: result.addressedCommentIds,
			},
		});
		if (signal.aborted || this.store.get(job.id)?.cancelRequested)
			throw Object.assign(new Error("Job cancelled"), { code: "CANCELLED" });
		const publicationAuth = await this.clients(job, signal);
		client = publicationAuth.client;
		token = publicationAuth.token;
		await pushBranch(workspace, job.owner, job.repo, branch, newHead, token, job.config, signal);
		await this.store.patch(
			job.id,
			{ publication: { ...publishing.publication, branchPushed: true, headSha: newHead } },
			"Branch pushed",
		);
		let url = publishing.publication.pullRequestUrl;
		if (createPr) {
			let pr = (
				await client.request<any[]>(
					"GET",
					`/repos/${job.owner}/${job.repo}/pulls?state=open&head=${encodeURIComponent(`${job.owner}:${branch}`)}`,
					undefined,
					signal,
				)
			)[0];
			if (!pr)
				pr = await client.request<any>(
					"POST",
					`/repos/${job.owner}/${job.repo}/pulls`,
					{ title: pullRequestTitle, head: branch, base: job.baseRef, body: pullRequestBody, draft: true },
					signal,
				);
			await this.store.patch(
				job.id,
				{
					pullRequestNumber: pr.number,
					publication: { ...this.store.get(job.id)!.publication, pullRequestId: pr.number, pullRequestUrl: pr.html_url },
				},
				"Draft pull request published",
			);
			url = pr.html_url;
		}
		return `${result.summary}\n\nChanged ${inspected.names.length} file(s). ${url ?? `Pushed \`${branch}\``}`;
	}
	private async implement(job: Job, client: GitHubClient, token: string, signal: AbortSignal) {
		const slug =
			job.args
				.toLowerCase()
				.replace(/[^a-z0-9]+/g, "-")
				.replace(/^-|-$/g, "")
				.slice(0, 30) || "implementation";
		const branch = `${job.config.implementation.branchPrefix}/issue-${job.issue}-${slug}-${job.id.slice(0, 8)}`;
		const recovered = await this.reconcilePrepared(this.store.get(job.id) ?? job, client, signal, true);
		if (recovered) return recovered;
		const existingPr = (
			await client.request<any[]>(
				"GET",
				`/repos/${job.owner}/${job.repo}/pulls?state=open&head=${encodeURIComponent(`${job.owner}:${branch}`)}`,
				undefined,
				signal,
			)
		)[0];
		if (existingPr) {
			await this.store.patch(
				job.id,
				{
					branch,
					pullRequestNumber: existingPr.number,
					publication: {
						...job.publication,
						branchPushed: true,
						pullRequestId: existingPr.number,
						pullRequestUrl: existingPr.html_url,
					},
				},
				"Draft pull request reconciled",
			);
			return `Recovered draft PR ${existingPr.html_url}.`;
		}
		const workspace = await createWorkspace(this.config.workspaceRoot);
		try {
			await cloneExact(workspace, job.owner, job.repo, job.baseRef, job.baseSha, token, job.config, signal);
			await runArgv(["git", "checkout", "-b", branch], workspace, job.config, undefined, { signal });
			await runArgv(["git", "config", "user.name", "my-ai-bot[bot]"], workspace, job.config);
			await runArgv(["git", "config", "user.email", "my-ai-bot[bot]@users.noreply.github.com"], workspace, job.config);
			const data = await this.issueData(job, client, signal);
			await this.store.transition(job.id, "implementing", { branch }, undefined, "analyzing");
			const result = await this.agentRun(
				job,
				"implement",
				await trustedInstructions(workspace),
				"Modify only this workspace to implement the issue. Do not commit, alter Git history, workflows, credentials, or prohibited files.",
				{ ...data, request: job.args, baseSha: job.baseSha },
				workspace,
				signal,
			);
			return await this.validateAndPublish(job, client, token, workspace, branch, result, signal, true);
		} finally {
			await cleanupWorkspace(workspace);
		}
	}
	private async followup(job: Job, client: GitHubClient, token: string, signal: AbortSignal) {
		const prior = this.priorPublication(job);
		if (!prior?.branch || !prior.publication.pullRequestId)
			throw Object.assign(new Error("No completed bot implementation publication"), { code: "BOT_PR_REQUIRED" });
		const pr = await client.request<any>(
			"GET",
			`/repos/${job.owner}/${job.repo}/pulls/${prior.publication.pullRequestId}`,
			undefined,
			signal,
		);
		if (
			pr.head.repo.full_name !== `${job.owner}/${job.repo}` ||
			pr.head.ref !== prior.branch ||
			!pr.head.ref.startsWith(`${job.config.implementation.branchPrefix}/`)
		)
			throw Object.assign(new Error("Current PR is not the stored bot branch"), { code: "BOT_PR_REQUIRED" });
		if (job.command === "fix-ci" && job.retryCount >= job.config.implementation.maxRetries)
			throw Object.assign(new Error("CI retry limit reached"), { code: "RETRY_LIMIT" });
		const recovered = await this.reconcilePrepared(this.store.get(job.id) ?? job, client, signal, false);
		if (recovered) return recovered;
		const workspace = await createWorkspace(this.config.workspaceRoot);
		try {
			await cloneExact(workspace, job.owner, job.repo, prior.branch, pr.head.sha, token, job.config, signal);
			await runArgv(["git", "checkout", "-b", prior.branch], workspace, job.config, undefined, { signal });
			await runArgv(["git", "config", "user.name", "my-ai-bot[bot]"], workspace, job.config);
			await runArgv(["git", "config", "user.email", "my-ai-bot[bot]@users.noreply.github.com"], workspace, job.config);
			let feedback: unknown;
			if (job.command === "address-review")
				feedback = {
					reviewComments: await client.paginate(`/repos/${job.owner}/${job.repo}/pulls/${pr.number}/comments`, signal),
					reviews: await client.paginate(`/repos/${job.owner}/${job.repo}/pulls/${pr.number}/reviews`, signal),
				};
			else {
				const checks = await client.request<any>(
					"GET",
					`/repos/${job.owner}/${job.repo}/commits/${pr.head.sha}/check-runs`,
					undefined,
					signal,
				);
				const runs = await client.request<any>(
					"GET",
					`/repos/${job.owner}/${job.repo}/actions/runs?head_sha=${pr.head.sha}`,
					undefined,
					signal,
				);
				feedback = {
					checks: (checks.check_runs ?? [])
						.filter((x: any) => x.conclusion && x.conclusion !== "success")
						.map((x: any) => ({ name: x.name, status: x.status, conclusion: x.conclusion, details_url: x.details_url })),
					runs: (runs.workflow_runs ?? [])
						.filter((x: any) => x.conclusion && x.conclusion !== "success")
						.map((x: any) => ({ id: x.id, name: x.name, conclusion: x.conclusion, html_url: x.html_url })),
				};
				await this.store.patch(job.id, { retryCount: job.retryCount + 1 }, "CI fix attempt");
			}
			await this.store.transition(
				job.id,
				"implementing",
				{ branch: prior.branch, headSha: pr.head.sha, pullRequestNumber: pr.number },
				undefined,
				"analyzing",
			);
			const result = await this.agentRun(
				job,
				job.command === "address-review" ? "address-review" : "fix-ci",
				await trustedInstructions(workspace),
				"Classify feedback conservatively. Set actionable=false and make no edits when ambiguous. If actionable, edit only the workspace and return addressedCommentIds containing only review comment IDs actually addressed; never commit or alter Git history.",
				{ pr: { number: pr.number, head: pr.head, base: pr.base }, feedback, request: job.args },
				workspace,
				signal,
			);
			if (!result.actionable) {
				await this.store.transition(job.id, "validating", {}, "No actionable feedback", "implementing");
				return result.summary;
			}
			const summary = await this.validateAndPublish(job, client, token, workspace, prior.branch, result, signal, false);
			if (job.command === "address-review") {
				client = (await this.clients(job, signal)).client;
				await this.replyToAddressed(this.store.get(job.id)!, client, signal);
			}
			return summary;
		} finally {
			await cleanupWorkspace(workspace);
		}
	}
	private async execute(job: Job, signal: AbortSignal) {
		const started = Date.now();
		let client: GitHubClient | undefined;
		try {
			if (signal.aborted || this.store.get(job.id)?.cancelRequested)
				throw Object.assign(new Error("Job cancelled"), { code: "CANCELLED" });
			const auth = await this.clients(job, signal);
			client = auth.client;
			job = await this.update(job, client, "", signal);
			if (job.command === "help") {
				const done = await this.store.transition(job.id, "completed", {}, undefined, "preparing");
				await this.update(
					done,
					client,
					"Commands: help, status, plan, implement, review [security], fix-ci, address-review, cancel.",
					signal,
				);
				return;
			}
			if (job.command === "status" || job.command === "cancel")
				throw Object.assign(new Error("Control command cannot be queued"), { code: "INVALID_COMMAND" });
			await this.store.transition(job.id, "analyzing", {}, undefined, "preparing");
			let detail: string;
			if (job.command === "plan") detail = await this.plan(job, client, auth.token, signal);
			else if (job.command === "review") detail = await this.review(job, client, signal);
			else if (job.command === "implement") detail = await this.implement(job, client, auth.token, signal);
			else detail = await this.followup(job, client, auth.token, signal);
			const current = this.store.get(job.id)!;
			const done = await this.store.transition(job.id, "completed", {}, undefined, current.state);
			client = (await this.clients(done, signal)).client;
			await this.update(done, client, detail, signal);
			jsonLogger.info("job_completed", { jobId: job.id, durationMs: Date.now() - started });
		} catch (error) {
			const code = signal.aborted ? "CANCELLED" : ((error as { code?: string }).code ?? "INTERNAL_ERROR");
			const current = this.store.get(job.id);
			if (current && !["completed", "failed", "cancelled"].includes(current.state)) {
				const failed = await this.store.transition(job.id, signal.aborted ? "cancelled" : "failed", { errorCode: code });
				const bounded = boundedSignal(10_000);
				try {
					client = (await this.clients(failed, bounded.signal)).client;
					await this.update(failed, client, `Error code: \`${code}\``, bounded.signal);
				} catch {
				} finally {
					bounded.cleanup();
				}
			}
			jsonLogger.error("job_failed", { jobId: job.id, code, durationMs: Date.now() - started });
		}
	}
}
