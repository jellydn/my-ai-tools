#!/usr/bin/env node

import { realpathSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { PreferenceStore, type PreferenceStoreOptions } from "./store.js";
import { registerPreferenceTools } from "./tools.js";

export function createServer(options: PreferenceStoreOptions = {}): McpServer {
	const server = new McpServer({ name: "user-memory", version: "0.1.0" });
	registerPreferenceTools(server, new PreferenceStore(options));
	return server;
}

export async function main(): Promise<void> {
	const server = createServer();
	await server.connect(new StdioServerTransport());
}

if (process.argv[1] && fileURLToPath(import.meta.url) === realpathSync(process.argv[1])) {
	main().catch((error: unknown) => {
		console.error("user-memory MCP server failed:", error);
		process.exitCode = 1;
	});
}
