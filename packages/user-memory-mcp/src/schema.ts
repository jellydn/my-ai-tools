import { z } from "zod";

export const preferenceValueSchema = z.object({
	value: z.string(),
	createdAt: z.string().datetime(),
	updatedAt: z.string().datetime(),
});

export const userMemorySchema = z.object({
	version: z.literal(1),
	preferences: z.record(z.string(), preferenceValueSchema),
});

export type PreferenceValue = z.infer<typeof preferenceValueSchema>;
export type UserMemory = z.infer<typeof userMemorySchema>;

/** Preference as returned to MCP callers (map key reattached). */
export type UserPreference = PreferenceValue & { key: string };

export const emptyUserMemory = (): UserMemory => ({
	version: 1,
	preferences: {},
});
