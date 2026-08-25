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
