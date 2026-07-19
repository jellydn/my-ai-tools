import { type BotCommand, COMMANDS } from "./types.ts";
export interface ParsedCommand {
	command: BotCommand;
	args: string;
}
export function parseCommand(body: string): ParsedCommand | undefined {
	const match = body.match(/^\s*(?:@my-ai-bot|\/my-ai-bot)\s+([\w-]+)(?:\s+([^\0]*))?\s*$/i);
	if (!match) return undefined;
	const command = match[1]!.toLowerCase() as BotCommand;
	if (!COMMANDS.includes(command)) return undefined;
	const args = (match[2] ?? "").trim();
	if (command === "review" && args && args !== "security") return undefined;
	return { command, args };
}
export type Access = "read" | "triage" | "write";
export const commandAccess = (command: BotCommand): Access =>
	(["help", "status"].includes(command) ? "read" : ["plan", "review"].includes(command) ? "triage" : "write") as Access;
const ranks: Record<string, number> = { none: 0, read: 1, triage: 2, write: 3, maintain: 4, admin: 5 };
export function isAuthorized(
	permission: string,
	command: BotCommand = "implement",
	actor?: string,
	allowUsers: string[] = [],
	configuredAccess?: Access,
): boolean {
	const mandatory = commandAccess(command);
	const required = configuredAccess && ranks[configuredAccess]! > ranks[mandatory]! ? configuredAccess : mandatory;
	return (
		(ranks[permission] ?? 0) >= ranks[required]! && (!allowUsers.length || Boolean(actor && allowUsers.includes(actor)))
	);
}
