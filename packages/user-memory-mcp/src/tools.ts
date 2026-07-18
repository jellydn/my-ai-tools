import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import type { PreferenceStore } from "./store.js";

const textResult = (value: unknown) => ({
	content: [{ type: "text" as const, text: JSON.stringify(value, null, 2) }],
});

export function registerPreferenceTools(server: McpServer, store: PreferenceStore): void {
	server.registerTool(
		"memory_preference_set",
		{
			description:
				"Store a cross-project user preference only after the user explicitly states or confirms it. Never infer preferences.",
			inputSchema: {
				key: z.string().describe("Stable preference key, such as responseStyle or packageManager"),
				value: z.string().describe("The explicit preference value; secrets and credentials are rejected"),
				confirmed: z
					.literal(true)
					.describe("Must be true only when the user explicitly stated or confirmed this preference"),
			},
			annotations: { readOnlyHint: false, destructiveHint: false },
		},
		async ({ key, value, confirmed }) => textResult(await store.set(key, value, confirmed)),
	);

	server.registerTool(
		"memory_preference_get",
		{
			description: "Retrieve one explicitly stored user preference by its exact key.",
			inputSchema: { key: z.string() },
			annotations: { readOnlyHint: true },
		},
		async ({ key }) => textResult((await store.get(key)) ?? null),
	);

	server.registerTool(
		"memory_preference_list",
		{
			description: "List exactly which cross-project user preferences are currently stored.",
			annotations: { readOnlyHint: true },
		},
		async () => textResult(await store.list()),
	);

	server.registerTool(
		"memory_preference_delete",
		{
			description: "Delete one stored user preference by its exact key.",
			inputSchema: { key: z.string() },
			annotations: { readOnlyHint: false, destructiveHint: true },
		},
		async ({ key }) => textResult({ key, deleted: await store.delete(key) }),
	);

	server.registerTool(
		"memory_preference_reset",
		{
			description: "Delete all stored user preferences. Requires explicit confirmation for this destructive action.",
			inputSchema: {
				confirmed: z.literal(true).describe("Must be true only after the user confirms resetting all preferences"),
			},
			annotations: { readOnlyHint: false, destructiveHint: true },
		},
		async () => textResult({ deleted: await store.reset() }),
	);
}
