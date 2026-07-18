import { z } from "zod";

export const userPreferenceSchema = z.object({
	key: z.string(),
	value: z.string(),
	source: z.literal("explicit"),
	createdAt: z.string().datetime(),
	updatedAt: z.string().datetime(),
});

export const userMemorySchema = z.object({
	version: z.literal(1),
	preferences: z.array(userPreferenceSchema),
});

export type UserPreference = z.infer<typeof userPreferenceSchema>;
export type UserMemory = z.infer<typeof userMemorySchema>;

export const emptyUserMemory = (): UserMemory => ({
	version: 1,
	preferences: [],
});
