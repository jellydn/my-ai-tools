import { relative, resolve } from "node:path";
import type { RepoConfig } from "./config.ts";

export function commandAllowed(
	argv: string[],
	workspace: string,
	config: RepoConfig,
	branch?: string,
): { allowed: boolean; reason?: string } {
	if (!argv.length || argv.some((arg) => arg.includes("\0"))) return { allowed: false, reason: "invalid argv" };
	const joined = argv.join(" ").toLowerCase();
	if (
		/\b(sudo|env|printenv)\b/.test(joined) ||
		(/curl|wget/.test(argv[0]!) && argv.some((x) => /^(sh|bash|zsh)$/.test(x)))
	)
		return { allowed: false, reason: "privilege, environment, or pipe-to-shell operation" };
	if (
		joined.includes(".ssh") ||
		joined.includes(".aws") ||
		joined.includes(".config/gh") ||
		joined.includes("credentials")
	)
		return { allowed: false, reason: "credential path" };
	if (argv[0] === "rm") {
		const targets = argv.slice(1).filter((x) => !x.startsWith("-"));
		if (targets.some((x) => relative(resolve(workspace), resolve(workspace, x)).startsWith("..")))
			return { allowed: false, reason: "rm outside workspace" };
	}
	if (argv[0] === "git") {
		if (["reset", "clean", "rebase"].includes(argv[1] ?? "") || argv.includes("--force") || argv.includes("-f"))
			return { allowed: false, reason: "destructive git" };
		if (["checkout", "restore"].includes(argv[1] ?? "") && argv.includes("."))
			return { allowed: false, reason: "bulk discard" };
		if (argv[1] === "config" && argv.some((x) => ["--global", "--system"].includes(x)))
			return { allowed: false, reason: "global git config" };
		if (argv[1] === "config" && !(argv.length === 4 && ["user.name", "user.email"].includes(argv[2] ?? "")))
			return { allowed: false, reason: "git config shape not allowed" };
		if (argv[1] === "push" && (!branch || argv.at(-1) !== `HEAD:refs/heads/${branch}`))
			return { allowed: false, reason: "unapproved push branch" };
		const safe = new Set([
			"clone",
			"config",
			"fetch",
			"checkout",
			"rev-parse",
			"remote",
			"status",
			"diff",
			"add",
			"commit",
			"push",
			"log",
			"show",
			"bundle",
			"write-tree",
		]);
		if (!safe.has(argv[1] ?? "")) return { allowed: false, reason: "git subcommand not allowed" };
	}
	const prefixes: string[][] = config.validation.commands.map((x) => x.trim().split(/\s+/));
	if (argv[0] === "git") return { allowed: true };
	return prefixes.some((prefix) => prefix.every((part, index) => argv[index] === part))
		? { allowed: true }
		: { allowed: false, reason: "command prefix not allowed" };
}
export function scanSecrets(text: string): string[] {
	const patterns = [
		/-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/g,
		/\bgh[pousr]_[A-Za-z0-9_]{20,}\b/g,
		/\bsk-[A-Za-z0-9_-]{20,}\b/g,
		/\bAKIA[0-9A-Z]{16}\b/g,
	];
	return patterns.flatMap((pattern) => text.match(pattern) ?? []);
}
export function redact(value: unknown): unknown {
	if (typeof value === "string")
		return value
			.replace(/(bearer\s+|token[=:]\s*)[^\s]+/gi, "$1[REDACTED]")
			.replace(/gh[pousr]_[A-Za-z0-9_]+/g, "[REDACTED]");
	if (Array.isArray(value)) return value.map(redact);
	if (value && typeof value === "object")
		return Object.fromEntries(
			Object.entries(value).map(([k, v]) => [k, /token|secret|key/i.test(k) ? "[REDACTED]" : redact(v)]),
		);
	return value;
}
export const jsonLogger = {
	info(event: string, data = {}) {
		console.log(JSON.stringify({ level: "info", event, ...(redact(data) as object) }));
	},
	error(event: string, data = {}) {
		console.error(JSON.stringify({ level: "error", event, ...(redact(data) as object) }));
	},
};
