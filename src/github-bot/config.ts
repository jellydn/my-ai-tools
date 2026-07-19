import { parse } from "yaml";
import { z } from "zod";
import { COMMANDS } from "./types.ts";

const commandFlags = Object.fromEntries(COMMANDS.map((x) => [x, z.boolean().default(true)])) as Record<
	(typeof COMMANDS)[number],
	z.ZodDefault<z.ZodBoolean>
>;
const access = z.enum(["read", "triage", "write"]);
const schema = z
	.object({
		version: z.literal(1).default(1),
		enabled: z.boolean().default(false),
		commands: z
			.object(commandFlags)
			.strict()
			.default(Object.fromEntries(COMMANDS.map((x) => [x, true])) as Record<(typeof COMMANDS)[number], boolean>),
		authorization: z
			.object({
				plan: access.default("triage"),
				review: access.default("triage"),
				implement: access.default("write"),
				"fix-ci": access.default("write"),
				"address-review": access.default("write"),
				cancel: access.default("write"),
				allowUsers: z.array(z.string().min(1)).max(100).default([]),
			})
			.strict()
			.default({
				plan: "triage",
				review: "triage",
				implement: "write",
				"fix-ci": "write",
				"address-review": "write",
				cancel: "write",
				allowUsers: [],
			}),
		agent: z
			.object({
				timeoutSeconds: z.number().int().positive().max(3600).default(900),
				maxTurns: z.number().int().positive().max(100).default(20),
			})
			.strict()
			.default({ timeoutSeconds: 900, maxTurns: 20 }),
		review: z
			.object({
				minConfidence: z.number().min(0).max(1).default(0.8),
				maxComments: z.number().int().positive().max(100).default(30),
				autoApprove: z.literal(false).default(false),
			})
			.strict()
			.default({ minConfidence: 0.8, maxComments: 30, autoApprove: false }),
		implementation: z
			.object({
				baseRef: z.string().min(1).optional(),
				branchPrefix: z
					.string()
					.regex(/^[A-Za-z0-9._/-]+$/)
					.default("my-ai-bot"),
				maxFiles: z.number().int().positive().max(200).default(50),
				maxDiffLines: z.number().int().positive().max(10000).default(2000),
				maxDiffBytes: z.number().int().positive().max(5_000_000).default(500_000),
				protectWorkflows: z.literal(true).default(true),
				maxRetries: z.number().int().min(0).max(3).default(1),
			})
			.strict()
			.default({
				branchPrefix: "my-ai-bot",
				maxFiles: 50,
				maxDiffLines: 2000,
				maxDiffBytes: 500_000,
				protectWorkflows: true,
				maxRetries: 1,
			}),
		validation: z
			.object({ commands: z.array(z.string().min(1)).max(10).default([]) })
			.strict()
			.default({ commands: [] }),
		security: z
			.object({
				prohibitedFiles: z.array(z.string()).default([".env", ".npmrc"]),
				allowActionsBot: z.boolean().default(false),
			})
			.strict()
			.default({ prohibitedFiles: [".env", ".npmrc"], allowActionsBot: false }),
	})
	.strict();
export type RepoConfig = z.infer<typeof schema>;
export const defaultRepoConfig = schema.parse({});
export function parseValidationCommand(command: string): string[] {
	if (/[;&|`$<>\n\r\\]/.test(command))
		throw Object.assign(new Error("Unsafe validation command"), { code: "INVALID_CONFIG" });
	const argv = command.trim().split(/\s+/);
	const allowed = [
		["bun", "test"],
		["bun", "run"],
		["npm", "test"],
		["npm", "run"],
		["pnpm", "test"],
		["pnpm", "run"],
		["bash", "-n"],
	];
	if (!allowed.some((p) => p.every((v, i) => argv[i] === v)))
		throw Object.assign(new Error("Validation command is not allowlisted"), { code: "INVALID_CONFIG" });
	return argv;
}
export function parseRepoConfig(value: string): RepoConfig {
	try {
		const result = schema.parse(parse(value) ?? {});
		result.validation.commands.forEach(parseValidationCommand);
		return result;
	} catch (cause) {
		throw Object.assign(new Error("Malformed repository configuration", { cause }), { code: "INVALID_CONFIG" });
	}
}
export interface BotConfig {
	appId: string;
	privateKey: string;
	webhookSecret: string;
	dataDir: string;
	workspaceRoot: string;
	concurrency: number;
	botLogin: string;
	allowActionsBot: boolean;
	baseUrl?: string;
	logLevel: string;
}
export function botConfigFromEnv(env: NodeJS.ProcessEnv): BotConfig | undefined {
	if (!env.GITHUB_APP_ID || !env.GITHUB_APP_PRIVATE_KEY || !env.GITHUB_APP_WEBHOOK_SECRET) return undefined;
	const concurrency = Number(env.BOT_WORKER_CONCURRENCY ?? env.BOT_REPO_CONCURRENCY ?? "2");
	if (!Number.isFinite(concurrency) || concurrency <= 0 || !Number.isInteger(concurrency))
		throw new Error("BOT_WORKER_CONCURRENCY must be a finite positive integer");
	return {
		appId: env.GITHUB_APP_ID,
		privateKey: env.GITHUB_APP_PRIVATE_KEY.replace(/\\n/g, "\n"),
		webhookSecret: env.GITHUB_APP_WEBHOOK_SECRET,
		dataDir: env.BOT_DATA_DIR ?? "./data/github-bot",
		workspaceRoot: env.BOT_WORKSPACE_ROOT ?? "/tmp/my-ai-bot",
		concurrency,
		botLogin: env.GITHUB_BOT_LOGIN ?? "my-ai-bot[bot]",
		allowActionsBot: env.BOT_ALLOW_ACTIONS_BOT === "true",
		baseUrl: env.BOT_BASE_URL,
		logLevel: env.BOT_LOG_LEVEL ?? "info",
	};
}
