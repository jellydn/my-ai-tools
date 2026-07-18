import assert from "node:assert/strict";
import { mkdtemp, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { afterEach, test } from "node:test";
import { PreferenceStore } from "../src/store.js";

const temporaryDirectories: string[] = [];

async function makeStore(now?: () => Date): Promise<{ directory: string; store: PreferenceStore }> {
	const directory = await mkdtemp(join(tmpdir(), "user-memory-mcp-"));
	temporaryDirectories.push(directory);
	return { directory, store: new PreferenceStore({ directory, now }) };
}

afterEach(async () => {
	await Promise.all(temporaryDirectories.splice(0).map((directory) => rm(directory, { recursive: true, force: true })));
});

test("stores, retrieves, and updates a preference across store instances", async () => {
	const timestamps = [new Date("2026-07-18T10:00:00.000Z"), new Date("2026-07-18T11:00:00.000Z")];
	const { directory, store } = await makeStore(() => timestamps.shift() ?? new Date("2026-07-18T12:00:00.000Z"));

	const created = await store.set("responseStyle", "concise", true);
	assert.equal(created.source, "explicit");
	assert.equal((await new PreferenceStore({ directory }).get("responseStyle"))?.value, "concise");

	const updated = await store.set("responseStyle", "detailed", true);
	assert.equal(updated.value, "detailed");
	assert.equal(updated.createdAt, created.createdAt);
	assert.notEqual(updated.updatedAt, created.updatedAt);
});

test("lists exactly the stored preferences in deterministic order", async () => {
	const { store } = await makeStore();
	await store.set("testRunner", "vitest", true);
	await store.set("packageManager", "pnpm", true);

	assert.deepEqual(
		(await store.list()).map(({ key, value }) => ({ key, value })),
		[
			{ key: "packageManager", value: "pnpm" },
			{ key: "testRunner", value: "vitest" },
		],
	);
});

test("deletes one preference and resets all preferences", async () => {
	const { store } = await makeStore();
	await store.set("responseStyle", "concise", true);
	await store.set("packageManager", "pnpm", true);

	assert.equal(await store.delete("responseStyle"), true);
	assert.equal(await store.delete("responseStyle"), false);
	assert.equal((await store.list()).length, 1);
	assert.equal(await store.reset(), 1);
	assert.deepEqual(await store.list(), []);
});

test("rejects implicit or inferred preferences", async () => {
	const { store } = await makeStore();
	await assert.rejects(store.set("responseStyle", "concise", false), /explicitly states or confirms/);
	assert.deepEqual(await store.list(), []);
});

test("rejects secrets in preference keys and values", async () => {
	const { store } = await makeStore();
	await assert.rejects(store.set("openaiApiKey", "not-even-a-real-key", true), /cannot be stored/);
	await assert.rejects(store.set("preferredHeader", "Bearer abcdefghijklmnopqrstuvwxyz", true), /cannot be stored/);
	await assert.rejects(store.set("credentialExample", "sk-or-v1-abcdefghijklmnop", true), /cannot be stored/);
	assert.deepEqual(await store.list(), []);
});

test("writes value-free audit entries for mutations", async () => {
	const { directory, store } = await makeStore();
	await store.set("responseStyle", "concise", true);
	await store.delete("responseStyle");
	await store.reset();

	const audit = (await readFile(join(directory, "audit.jsonl"), "utf8"))
		.trim()
		.split("\n")
		.map((line) => JSON.parse(line));
	assert.deepEqual(
		audit.map(({ operation, key }) => ({ operation, key })),
		[
			{ operation: "set", key: "responseStyle" },
			{ operation: "delete", key: "responseStyle" },
			{ operation: "reset", key: undefined },
		],
	);
	assert.equal(JSON.stringify(audit).includes("concise"), false);
});

test("serializes concurrent writers without losing preferences", async () => {
	const { directory } = await makeStore();
	await Promise.all(
		Array.from({ length: 20 }, (_, index) =>
			new PreferenceStore({ directory }).set(`preference${index}`, `value${index}`, true),
		),
	);

	const preferences = await new PreferenceStore({ directory }).list();
	assert.equal(preferences.length, 20);
	assert.deepEqual(
		new Set(preferences.map(({ key }) => key)),
		new Set(Array.from({ length: 20 }, (_, index) => `preference${index}`)),
	);
});
