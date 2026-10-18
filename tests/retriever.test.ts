import { expect, test } from "bun:test";

test("retrieve rejects incompatible indexes and preserves empty and ranked results", async () => {
	// Isolate module mocks from other suites sharing the Bun test process.
	const child = Bun.spawn(
		[
			process.execPath,
			"-e",
			`
import { expect, mock } from "bun:test";
let index = { model: "other-model", chunks: [] };
let calls = 0;
mock.module("./lib/index-loader.ts", () => ({
  createIndexLoader: () => ({ load: async () => index, clear() {} }),
}));
mock.module("./lib/openai-client.ts", () => ({
  getDefaultEmbeddingModel: () => "test-model",
  createOpenAIClient: () => ({ embeddings: { create: async () => {
    calls++;
    return { data: [{ embedding: [1, 0] }] };
  } } }),
}));
const { retrieve } = await import("./lib/retriever.ts");
const chunk = (path, embedding) => ({ path, text: path, embedding });
expect(await retrieve("query", 1)).toEqual([]);
expect(calls).toBe(0);
index.chunks = [chunk("a", [1, 0])];
await expect(retrieve("query", 1)).rejects.toThrow("Index uses embedding model");
expect(calls).toBe(0);
index.model = "test-model";
for (const embedding of [[1], [1, 0, 1]]) {
  index.chunks = [chunk("valid", [1, 0]), chunk("invalid", embedding)];
  await expect(retrieve("query", 1)).rejects.toThrow("Index embedding dimensions");
}
index.chunks = [chunk("orthogonal", [0, 1]), chunk("matching", [1, 0])];
expect(await retrieve("query", 1)).toEqual([{ path: "matching", text: "matching", score: 1 }]);
`,
		],
		{
			cwd: new URL("..", import.meta.url).pathname,
			env: { ...process.env, OPENAI_EMBEDDING_MODEL: "test-model" },
			stdout: "pipe",
			stderr: "pipe",
		},
	);
	const stderr = await new Response(child.stderr).text();
	expect(await child.exited, stderr).toBe(0);
});
