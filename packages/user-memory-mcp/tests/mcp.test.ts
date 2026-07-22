import assert from "node:assert/strict";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { afterEach, test } from "node:test";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { InMemoryTransport } from "@modelcontextprotocol/sdk/inMemory.js";
import { createServer } from "../src/server.js";

const temporaryDirectories: string[] = [];

afterEach(async () => {
	await Promise.all(
		temporaryDirectories
			.splice(0)
			.map((directory) => rm(directory, { recursive: true, force: true })),
	);
});

async function connect(directory: string) {
	const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
	const server = createServer({ directory });
	const client = new Client({ name: "user-memory-test", version: "1.0.0" });
	await Promise.all([server.connect(serverTransport), client.connect(clientTransport)]);
	return { client, server };
}

function textContent(result: Awaited<ReturnType<Client["callTool"]>>): unknown {
	const block = result.content[0];
	assert.equal(block?.type, "text");
	return JSON.parse(block.text);
}

test("advertises the five preference tools", async () => {
	const directory = await mkdtemp(join(tmpdir(), "user-memory-mcp-protocol-"));
	temporaryDirectories.push(directory);
	const { client, server } = await connect(directory);

	const tools = await client.listTools();
	assert.deepEqual(tools.tools.map(({ name }) => name).sort(), [
		"memory_preference_delete",
		"memory_preference_get",
		"memory_preference_list",
		"memory_preference_reset",
		"memory_preference_set",
	]);

	await client.close();
	await server.close();
});

test("persists an explicit preference across independent MCP sessions", async () => {
	const directory = await mkdtemp(join(tmpdir(), "user-memory-mcp-protocol-"));
	temporaryDirectories.push(directory);
	const first = await connect(directory);

	await first.client.callTool({
		name: "memory_preference_set",
		arguments: { key: "responseStyle", value: "concise", confirmed: true },
	});
	await first.client.close();
	await first.server.close();

	const second = await connect(directory);
	const result = await second.client.callTool({
		name: "memory_preference_get",
		arguments: { key: "responseStyle" },
	});
	const preference = textContent(result) as Record<string, unknown>;
	assert.deepEqual(
		{ key: preference.key, value: preference.value },
		{
			key: "responseStyle",
			value: "concise",
		},
	);
	assert.match(String(preference.createdAt), /^\d{4}-\d{2}-\d{2}T/);
	assert.match(String(preference.updatedAt), /^\d{4}-\d{2}-\d{2}T/);
	assert.equal("source" in preference, false);

	await second.client.close();
	await second.server.close();
});

test("rejects a set call without explicit confirmation at the MCP boundary", async () => {
	const directory = await mkdtemp(join(tmpdir(), "user-memory-mcp-protocol-"));
	temporaryDirectories.push(directory);
	const { client, server } = await connect(directory);

	const result = await client.callTool({
		name: "memory_preference_set",
		arguments: { key: "responseStyle", value: "concise", confirmed: false },
	});
	assert.equal(result.isError, true);
	assert.match(JSON.stringify(result.content), /validation|true/i);

	await client.close();
	await server.close();
});
