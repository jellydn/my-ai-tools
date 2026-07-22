import type { Hono } from "hono";
import { type Access, isAuthorized, parseCommand } from "./commands.ts";
import { type BotConfig, defaultRepoConfig, parseRepoConfig } from "./config.ts";
import { installationClient, verifyWebhook } from "./github.ts";
import { JsonJobStore } from "./store.ts";
import { BotWorker } from "./worker.ts";

interface Payload {
	action?: string;
	installation?: { id: number };
	sender?: { login: string; type?: string };
	comment?: { body: string };
	issue?: { number: number };
	repository?: { name: string; owner: { login: string } };
}
export function shouldIgnoreSender(
	login: string,
	type: string | undefined,
	botLogin: string,
	allowActionsBot: boolean,
) {
	return login === botLogin || (type === "Bot" && !(allowActionsBot && login === "github-actions[bot]"));
}
export async function installGitHubBot(app: Hono, config: BotConfig, fetcher: typeof fetch = fetch) {
	const store = new JsonJobStore(config.dataDir);
	await store.init();
	const worker = new BotWorker(config, store, undefined, fetcher);
	worker.start();
	let accepting = true;
	app.post("/api/github/webhooks", async (c) => {
		if (!accepting) return c.json({ error: "SHUTTING_DOWN" }, 503);
		const raw = new Uint8Array(await c.req.arrayBuffer());
		if (!verifyWebhook(raw, c.req.header("x-hub-signature-256"), config.webhookSecret))
			return c.json({ error: "INVALID_SIGNATURE" }, 401);
		const deliveryId = c.req.header("x-github-delivery");
		if (!deliveryId) return c.json({ error: "MISSING_DELIVERY" }, 400);
		if (!(await store.reserveDelivery(deliveryId))) return c.json({ duplicate: true }, 202);
		try {
			if (c.req.header("x-github-event") !== "issue_comment") return c.json({ ignored: true }, 202);
			let payload: Payload;
			try {
				payload = JSON.parse(new TextDecoder().decode(raw));
			} catch {
				return c.json({ error: "INVALID_PAYLOAD" }, 400);
			}
			if (
				payload.action !== "created" ||
				!payload.installation ||
				!payload.sender ||
				!payload.issue ||
				!payload.repository ||
				!payload.comment
			)
				return c.json({ ignored: true }, 202);
			if (shouldIgnoreSender(payload.sender.login, payload.sender.type, config.botLogin, config.allowActionsBot))
				return c.json({ ignored: true }, 202);
			const parsed = parseCommand(payload.comment.body);
			if (!parsed) return c.json({ ignored: true }, 202);
			const owner = payload.repository.owner.login;
			const repo = payload.repository.name;
			const { client } = await installationClient(config, payload.installation.id, fetcher);
			const snapshot = await client.repositorySnapshot(owner, repo);
			const rawConfig = await client.contentAt(owner, repo, ".github/my-ai-bot.yml", snapshot.sha);
			const repoConfig = rawConfig === undefined ? defaultRepoConfig : parseRepoConfig(rawConfig);
			if (!repoConfig.enabled || !repoConfig.commands[parsed.command]) return c.json({ error: "COMMAND_DISABLED" }, 403);
			const permission = await client.permission(owner, repo, payload.sender.login);
			const configuredAccess =
				parsed.command === "help" || parsed.command === "status"
					? undefined
					: (repoConfig.authorization[parsed.command] as Access);
			if (
				!isAuthorized(
					permission.permission,
					parsed.command,
					payload.sender.login,
					repoConfig.authorization.allowUsers,
					configuredAccess,
				)
			)
				return c.json({ error: "UNAUTHORIZED_ACTOR" }, 403);
			if (parsed.command === "status" || parsed.command === "cancel") {
				const target = store.newest(owner, repo, payload.issue.number);
				if (!target) return c.json({ error: "JOB_NOT_FOUND" }, 404);
				if (parsed.command === "cancel") {
					await store.requestCancel(target.id);
					worker.cancel(target.id);
					await worker.reportStatus(store.get(target.id) ?? target, "Cancellation requested.");
				} else await worker.reportStatus(target);
				await store.finishDelivery(deliveryId, { status: "accepted", jobId: target.id });
				return c.json({ jobId: target.id, state: store.get(target.id)?.state }, 202);
			}
			const baseRef = repoConfig.implementation.baseRef ?? snapshot.defaultBranch;
			const baseSha = baseRef === snapshot.defaultBranch ? snapshot.sha : await client.refSha(owner, repo, baseRef);
			const result = await store.enqueue({
				deliveryId,
				owner,
				repo,
				installationId: payload.installation.id,
				issue: payload.issue.number,
				actor: payload.sender.login,
				command: parsed.command,
				args: parsed.args,
				config: repoConfig,
				baseRef,
				baseSha,
			});
			return c.json({ jobId: result.job.id, duplicate: result.duplicate }, 202);
		} catch {
			await store.releaseDelivery(deliveryId);
			return c.json({ error: "WEBHOOK_PROCESSING_FAILED" }, 500);
		}
	});
	return {
		store,
		worker,
		ready: () => accepting,
		shutdown: async () => {
			accepting = false;
			await worker.stop();
		},
	};
}
