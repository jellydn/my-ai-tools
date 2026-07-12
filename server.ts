import { Hono } from "hono";
import { serveStatic } from "hono/bun";
import { stream } from "hono/streaming";
import OpenAI from "openai";
import { z } from "zod";
import { type RetrievedChunk, retrieve } from "./lib/retriever.ts";

const app = new Hono();

const openai = new OpenAI({
	apiKey: process.env.OPENAI_API_KEY,
});

if (!process.env.OPENAI_API_KEY) {
	console.error("OPENAI_API_KEY is not set. Copy .env.example to .env and add your key.");
	process.exit(1);
}

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

app.post("/api/chat", async (c) => {
	const body = await c.req.json();
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
		return c.json({
			answer: "This is not documented in the repository.",
			sources: [],
		});
	}

	const CHAT_MODEL = process.env.OPENAI_MODEL ?? "gpt-4o-mini";
	const systemPrompt = buildSystemPrompt(chunks);
	const completion = await openai.chat.completions.create({
		model: CHAT_MODEL,
		messages: [
			{ role: "system", content: systemPrompt },
			{ role: "user", content: message },
		],
		stream: true,
		temperature: 0.2,
	});

	c.header("Content-Type", "text/plain; charset=utf-8");
	return stream(c, async (stream) => {
		for await (const part of completion) {
			const content = part.choices[0]?.delta?.content;
			if (content) {
				await stream.write(`${JSON.stringify({ type: "text", content })}\n`);
			}
		}

		const sourcePaths = [...new Set(chunks.map((chunk) => chunk.path))];
		await stream.write(`${JSON.stringify({ type: "sources", paths: sourcePaths })}\n`);
	});
});

app.get("/", async (c) => {
	const file = Bun.file("index.html");
	return c.html(await file.text());
});

app.use("/*", serveStatic({ root: "./" }));

const port = Number.parseInt(process.env.PORT ?? "3000", 10);

console.log(`Server running at http://localhost:${port}`);

export default {
	port,
	fetch: app.fetch,
};
