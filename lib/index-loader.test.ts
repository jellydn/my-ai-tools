import { afterEach, describe, expect, test } from "bun:test";
import { mkdtemp, rm, utimes, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { createIndexLoader } from "./index-loader.ts";
import type { Index } from "./retriever.ts";

const dirs: string[] = [];
const sample = (text: string): Index => ({ generatedAt: "2026-01-01T00:00:00Z", model: "test", chunks: [{ path: "a.md", text, embedding: [1] }] });

afterEach(async () => {
	await Promise.all(dirs.splice(0).map((path) => rm(path, { recursive: true, force: true })));
});

describe("index loader", () => {
	test("caches unchanged indexes and reloads changed files", async () => {
		const dir = await mkdtemp(join(tmpdir(), "index-loader-"));
		dirs.push(dir);
		const path = join(dir, "index.json");
		await writeFile(path, JSON.stringify(sample("first")));
		const loader = createIndexLoader(path);
		const first = await loader.load();
		expect(await loader.load()).toBe(first);
		await writeFile(path, JSON.stringify(sample("second")));
		await utimes(path, new Date(), new Date(Date.now() + 2000));
		expect((await loader.load()).chunks[0]?.text).toBe("second");
	});

	test("preserves missing-index errors", async () => {
		const loader = createIndexLoader(join(tmpdir(), "missing-index.json"));
		await expect(loader.load()).rejects.toMatchObject({ code: "ENOENT" });
	});
});
