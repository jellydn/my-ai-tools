import { readFile } from "node:fs/promises";
import { serve } from "@hono/node-server";
import { serveStatic } from "@hono/node-server/serve-static";
import type { Context, Next } from "hono";
import { Hono } from "hono";
import { stream } from "hono/streaming";
import { z } from "zod";
import { createOpenAIClient } from "./lib/openai-client.ts";
import { type RetrievedChunk, retrieve } from "./lib/retriever.ts";
import { installGitHubBot } from "./src/github-bot/app.ts";
import { botConfigFromEnv } from "./src/github-bot/config.ts";

const [indexHtml, installSh, installPs1] = await Promise.all([
	readFile("index.html", "utf-8"),
	readFile("install.sh", "utf-8"),
	readFile("install.ps1", "utf-8"),
]);

const RATE_LIMIT_WINDOW_MS = 60 * 1000;
const RATE_LIMIT_MAX = 30;
const requestTimestamps = new Map<string, number[]>();

function rateLimitMiddleware(c: Context, next: Next) {
	const forwarded = c.req.header("x-forwarded-for");
	const clientIp = c.req.header("fly-client-ip") || (forwarded ? forwarded.split(",")[0]?.trim() : undefined);
	const key = clientIp ?? "unknown";
	const now = Date.now();
	const timestamps = requestTimestamps.get(key) ?? [];
	const recent = timestamps.filter((timestamp) => now - timestamp < RATE_LIMIT_WINDOW_MS);

	if (recent.length >= RATE_LIMIT_MAX) {
		return c.json({ error: "Rate limit exceeded. Try again later." }, 429);
	}

	recent.push(now);
	requestTimestamps.set(key, recent);
	return next();
}

function pruneRateLimitMap() {
	const now = Date.now();
	for (const [key, timestamps] of requestTimestamps.entries()) {
		const recent = timestamps.filter((timestamp) => now - timestamp < RATE_LIMIT_WINDOW_MS);
		if (recent.length === 0) {
			requestTimestamps.delete(key);
		} else {
			requestTimestamps.set(key, recent);
		}
	}
}

const pruneTimer = setInterval(pruneRateLimitMap, 5 * 60 * 1000);
pruneTimer.unref();

const app = new Hono();

const openai = process.env.OPENAI_API_KEY ? createOpenAIClient() : undefined;
const botConfig = botConfigFromEnv(process.env);
const bot = botConfig ? await installGitHubBot(app, botConfig) : undefined;

app.get("/healthz", (c) => c.json({ status: "ok" }));
app.get("/readyz", (c) =>
	c.json(
		{ status: bot?.ready() === false ? "not-ready" : "ready", bot: Boolean(bot) },
		bot?.ready() === false ? 503 : 200,
	),
);

const chatRequestSchema = z.object({
	message: z.string().min(1).max(4000),
});

function buildSystemPrompt(chunks: { path: string; text: string }[]): string {
	const context = chunks.map((chunk) => `--- ${chunk.path} ---\n${chunk.text}`).join("\n\n");

	return `You are the my-ai-tools repository assistant.

Answer only from the retrieved repository excerpts below.
Do not invent commands, supported tools, or configuration.
If the retrieved context is insufficient, say exactly: "This is not documented in the repository."
Include the relevant source file paths in your answer.
Keep answers concise and grounded.

Retrieved repository excerpts:
${context}`;
}

app.use("/data/*", async (c) => c.text("Forbidden", 403));

app.post("/api/chat", rateLimitMiddleware, async (c) => {
	if (!openai) return c.json({ error: "Chat is not configured." }, 503);
	let body: unknown;
	try {
		body = await c.req.json();
	} catch {
		return c.json({ error: "Invalid request body" }, 400);
	}
	const parsed = chatRequestSchema.safeParse(body);
	if (!parsed.success) {
		return c.json({ error: "Invalid request body" }, 400);
	}

	const { message } = parsed.data;
	let chunks: RetrievedChunk[];
	try {
		chunks = await retrieve(message, 5);
	} catch (error) {
		if (error && typeof error === "object" && "code" in error && (error as { code: unknown }).code === "ENOENT") {
			return c.json({ error: "Index not found. Run `bun run index` to build data/index.json." }, 503);
		}
		return c.json({ error: "Failed to retrieve context from the index." }, 500);
	}

	if (chunks.length === 0) {
		c.header("Content-Type", "text/plain; charset=utf-8");
		return stream(c, async (stream) => {
			await stream.write(`${JSON.stringify({ type: "text", content: "This is not documented in the repository." })}\n`);
			await stream.write(`${JSON.stringify({ type: "sources", paths: [] })}\n`);
		});
	}

	const CHAT_MODEL = process.env.OPENAI_MODEL ?? "gpt-4o-mini";
	const systemPrompt = buildSystemPrompt(chunks);
	let completion;
	try {
		completion = await openai.chat.completions.create({
			model: CHAT_MODEL,
			messages: [
				{ role: "system", content: systemPrompt },
				{ role: "user", content: message },
			],
			stream: true,
			temperature: 0.2,
		});
	} catch {
		return c.json({ error: "The language model is unavailable. Please try again later." }, 502);
	}

	c.header("Content-Type", "text/plain; charset=utf-8");
	return stream(c, async (stream) => {
		try {
			for await (const part of completion) {
				const content = part.choices[0]?.delta?.content;
				if (content) {
					await stream.write(`${JSON.stringify({ type: "text", content })}\n`);
				}
			}

			const sourcePaths = [...new Set(chunks.map((chunk) => chunk.path))];
			await stream.write(`${JSON.stringify({ type: "sources", paths: sourcePaths })}\n`);
		} catch {
			await stream.write(
				`${JSON.stringify({ type: "error", message: "Response generation failed. Please try again later." })}\n`,
			);
		}
	});
});

app.use(
	"/public/*",
	serveStatic({
		root: "./public",
		rewriteRequestPath: (path) => {
			const prefix = "/public";
			if (path.startsWith(prefix)) {
				return path.slice(prefix.length) || "/";
			}
			return path;
		},
	}),
);

app.get("/", (c) => c.html(indexHtml));
app.get("/index.html", (c) => c.redirect("/"));
app.get("/install.sh", (c) => c.text(installSh));
app.get("/install.ps1", (c) => c.text(installPs1));

const port = Number.parseInt(process.env.PORT ?? "3000", 10);

const server = serve(
	{
		fetch: app.fetch,
		port,
		hostname: "0.0.0.0",
	},
	(info) => {
		console.log(`Server running at http://${info.address}:${info.port}`);
	},
);

let shuttingDown = false;
async function shutdown() {
	if (shuttingDown) return;
	shuttingDown = true;
	const forcedExit = setTimeout(() => process.exit(1), 10_000);
	forcedExit.unref();
	clearInterval(pruneTimer);
	server.close();
	await bot?.shutdown();
	clearTimeout(forcedExit);
	process.exit(0);
}
process.once("SIGTERM", () => void shutdown());
process.once("SIGINT", () => void shutdown());
