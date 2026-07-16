import { readFile } from "node:fs/promises";
import { serve } from "@hono/node-server";
import { serveStatic } from "@hono/node-server/serve-static";
import type { Context, Next } from "hono";
import { Hono } from "hono";
import { stream } from "hono/streaming";
import { z } from "zod";
import { createOpenAIClient } from "./lib/openai-client.ts";
import { buildContextMessage, RAG_SYSTEM_PROMPT } from "./lib/rag-prompt.ts";
import { type RetrievedChunk, retrieve } from "./lib/retriever.ts";

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

setInterval(pruneRateLimitMap, 5 * 60 * 1000);

const app = new Hono();

if (!process.env.OPENAI_API_KEY) {
	console.error("OPENAI_API_KEY is not set. Copy .env.example to .env and add your key.");
	process.exit(1);
}

const openai = createOpenAIClient();

const documentTypeSchema = z.enum(["documentation", "source", "issue", "pull_request", "cli_help", "example_config"]);
const chatRequestSchema = z.object({
	message: z.string().min(1).max(4000),
	topK: z.union([z.literal(3), z.literal(5), z.literal(10), z.literal(20)]).default(5),
	types: z.array(documentTypeSchema).max(6).optional(),
});

app.use("/data/*", async (c) => c.text("Forbidden", 403));

app.post("/api/chat", rateLimitMiddleware, async (c) => {
	const startedAt = performance.now();
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

	const { message, topK, types } = parsed.data;
	let chunks: RetrievedChunk[];
	const retrievalStartedAt = performance.now();
	try {
		chunks = await retrieve(message, { topK, types });
	} catch (error) {
		console.error(
			JSON.stringify({
				event: "rag_request",
				questionLength: message.length,
				topK,
				filters: { types: types ?? [] },
				retrievedChunks: [],
				retrievalLatencyMs: Math.round(performance.now() - retrievalStartedAt),
				latencyMs: Math.round(performance.now() - startedAt),
				error: "retrieval_failed",
			}),
		);
		if (error && typeof error === "object" && "code" in error && (error as { code: unknown }).code === "ENOENT") {
			return c.json({ error: "Index not found. Run `bun run index` to build data/index.json." }, 503);
		}
		return c.json({ error: "Failed to retrieve context from the index." }, 500);
	}

	if (chunks.length === 0) {
		console.log(
			JSON.stringify({
				event: "rag_request",
				questionLength: message.length,
				topK,
				filters: { types: types ?? [] },
				retrievedChunks: [],
				retrievalLatencyMs: Math.round(performance.now() - retrievalStartedAt),
				promptTokens: 0,
				responseTokens: 0,
				latencyMs: Math.round(performance.now() - startedAt),
			}),
		);
		c.header("Content-Type", "text/plain; charset=utf-8");
		return stream(c, async (stream) => {
			await stream.write(`${JSON.stringify({ type: "text", content: "This is not documented in the repository." })}\n`);
			await stream.write(`${JSON.stringify({ type: "sources", sources: [] })}\n`);
		});
	}

	const CHAT_MODEL = process.env.OPENAI_MODEL ?? "gpt-4o-mini";
	let completion;
	try {
		completion = await openai.chat.completions.create({
			model: CHAT_MODEL,
			messages: [
				{ role: "system", content: RAG_SYSTEM_PROMPT },
				{ role: "user", content: buildContextMessage(message, chunks) },
			],
			stream: true,
			stream_options: { include_usage: true },
			temperature: 0.2,
		});
	} catch {
		console.error(
			JSON.stringify({
				event: "rag_request",
				questionLength: message.length,
				topK,
				filters: { types: types ?? [] },
				retrievedChunks: chunks.map((chunk) => ({
					path: chunk.path,
					type: chunk.metadata.type,
					score: Number(chunk.score.toFixed(4)),
				})),
				retrievalLatencyMs: Math.round(performance.now() - retrievalStartedAt),
				latencyMs: Math.round(performance.now() - startedAt),
				error: "generation_unavailable",
			}),
		);
		return c.json({ error: "The language model is unavailable. Please try again later." }, 502);
	}

	c.header("Content-Type", "text/plain; charset=utf-8");
	return stream(c, async (stream) => {
		let promptTokens: number | null = null;
		let responseTokens: number | null = null;
		let streamError = false;
		try {
			for await (const part of completion) {
				if (part.usage) {
					promptTokens = part.usage.prompt_tokens;
					responseTokens = part.usage.completion_tokens;
				}
				const content = part.choices[0]?.delta?.content;
				if (content) {
					await stream.write(`${JSON.stringify({ type: "text", content })}\n`);
				}
			}

			const sources = [
				...new Map(chunks.map((chunk) => [chunk.path, { path: chunk.path, url: chunk.metadata.url }])).values(),
			];
			await stream.write(`${JSON.stringify({ type: "sources", sources })}\n`);
		} catch {
			streamError = true;
			await stream.write(
				`${JSON.stringify({ type: "error", message: "Response generation failed. Please try again later." })}\n`,
			);
		} finally {
			console.log(
				JSON.stringify({
					event: "rag_request",
					questionLength: message.length,
					topK,
					filters: { types: types ?? [] },
					retrievedChunks: chunks.map((chunk) => ({
						path: chunk.path,
						type: chunk.metadata.type,
						author: chunk.metadata.author,
						score: Number(chunk.score.toFixed(4)),
					})),
					retrievalLatencyMs: Math.round(performance.now() - retrievalStartedAt),
					promptTokens,
					responseTokens,
					latencyMs: Math.round(performance.now() - startedAt),
					...(streamError ? { error: "generation_failed" } : {}),
				}),
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

serve(
	{
		fetch: app.fetch,
		port,
		hostname: "0.0.0.0",
	},
	(info) => {
		console.log(`Server running at http://${info.address}:${info.port}`);
	},
);
