// Day 13 — Stateful Chat with Persistent Preference Memory
//
// Demonstrates short-term (conversation) and long-term (file-based) memory.
// Preferences are stored in a local JSON file and injected into the system
// prompt on every turn. An audit log records mutations without storing values.

import { readFileSync, writeFileSync, mkdirSync, appendFileSync, existsSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";

// ── Types ────────────────────────────────────────────────────────────────

type UserPreference = {
	key: string;
	value: string;
	source: "explicit";
	createdAt: string;
	updatedAt: string;
};

type UserMemory = {
	version: 1;
	preferences: UserPreference[];
};

type AuditEntry = {
	operation: "set" | "delete" | "reset";
	key?: string;
	timestamp: string;
};

type ConversationMessage = {
	role: "system" | "user" | "assistant";
	content: string;
};

// ── Secret Detection ────────────────────────────────────────────────────

const SECRET_KEY_PARTS = [
	"apikey",
	"accesskey",
	"authtoken",
	"cookie",
	"credential",
	"password",
	"passphrase",
	"privatekey",
	"secret",
	"sessiontoken",
	"token",
];

const SECRET_VALUE_PATTERNS = [
	/-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/i,
	/\b(?:sk|pk|rk)-(?:live|test|or-v1|proj)-[A-Za-z0-9_-]{8,}\b/,
	/\bBearer\s+[A-Za-z0-9._~+/-]+=*\b/i,
];

function isSecret(key: string, value: string): boolean {
	const normalizedKey = key.toLowerCase().replaceAll(/[^a-z0-9]/g, "");
	if (SECRET_KEY_PARTS.some((part) => normalizedKey.includes(part))) return true;
	if (SECRET_VALUE_PATTERNS.some((pattern) => pattern.test(value))) return true;
	return false;
}

// ── Preference Store (mirrors packages/user-memory-mcp/src/store.ts) ──

class PreferenceStore {
	private readonly memoryPath: string;
	private readonly auditPath: string;

	constructor(directory: string) {
		mkdirSync(directory, { recursive: true });
		this.memoryPath = join(directory, "preferences.json");
		this.auditPath = join(directory, "audit.jsonl");
	}

	private readMemory(): UserMemory {
		try {
			return JSON.parse(readFileSync(this.memoryPath, "utf8")) as UserMemory;
		} catch {
			return { version: 1, preferences: [] };
		}
	}

	private writeMemory(memory: UserMemory): void {
		writeFileSync(this.memoryPath, `${JSON.stringify(memory, null, 2)}\n`, "utf8");
	}

	private appendAudit(entry: AuditEntry): void {
		appendFileSync(this.auditPath, `${JSON.stringify(entry)}\n`, "utf8");
	}

	set(key: string, value: string, explicit: boolean): UserPreference {
		if (!explicit) {
			throw new Error(
				"Preferences may only be stored after the user explicitly states or confirms them.",
			);
		}
		if (isSecret(key, value)) {
			throw new Error(
				"Secrets, credentials, API keys, tokens, and passwords cannot be stored as preferences.",
			);
		}

		const memory = this.readMemory();
		const now = new Date().toISOString();
		const existing = memory.preferences.find((p) => p.key === key);

		const pref: UserPreference = existing
			? { ...existing, value, updatedAt: now }
			: { key, value, source: "explicit", createdAt: now, updatedAt: now };

		if (existing) {
			memory.preferences[memory.preferences.indexOf(existing)] = pref;
		} else {
			memory.preferences.push(pref);
		}

		this.writeMemory(memory);
		this.appendAudit({ operation: "set", key, timestamp: now });
		return pref;
	}

	get(key: string): UserPreference | undefined {
		return this.readMemory().preferences.find((p) => p.key === key);
	}

	list(): UserPreference[] {
		return [...this.readMemory().preferences].sort((a, b) => a.key.localeCompare(b.key));
	}

	delete(key: string): boolean {
		const memory = this.readMemory();
		const remaining = memory.preferences.filter((p) => p.key !== key);
		if (remaining.length === memory.preferences.length) return false;
		memory.preferences = remaining;
		const now = new Date().toISOString();
		this.writeMemory(memory);
		this.appendAudit({ operation: "delete", key, timestamp: now });
		return true;
	}

	reset(): number {
		const memory = this.readMemory();
		const count = memory.preferences.length;
		this.writeMemory({ version: 1, preferences: [] });
		this.appendAudit({ operation: "reset", timestamp: new Date().toISOString() });
		return count;
	}

	getAuditLog(): string {
		try {
			return readFileSync(this.auditPath, "utf8").trim();
		} catch {
			return "(no audit entries)";
		}
	}
}

// ── Stateful Chat Engine ────────────────────────────────────────────────

function buildSystemPrompt(preferences: UserPreference[]): string {
	const base = "You are a helpful coding assistant.";
	if (preferences.length === 0) {
		return `${base} No user preferences are stored.`;
	}
	const prefLines = preferences.map((p) => `  - ${p.key}: ${p.value}`).join("\n");
	return `${base}\n\nUser preferences (apply these to all responses):\n${prefLines}`;
}

function simulateResponse(query: string, preferences: UserPreference[]): string {
	const stylePref = preferences.find((p) => p.key === "responseStyle");
	const langPref = preferences.find((p) => p.key === "language");

	let response = `Here is the answer to "${query}".`;

	if (stylePref?.value === "concise") {
		response = `[concise] ${query} → Done.`;
	} else if (stylePref?.value === "detailed") {
		response = `[detailed] Regarding "${query}": Let me provide a thorough explanation with examples, edge cases, and references...`;
	}

	if (langPref) {
		response += ` (Responding with ${langPref.value} conventions.)`;
	}

	return response;
}

// ── Main ────────────────────────────────────────────────────────────────

function main() {
	const storeDir = join(tmpdir(), `memory-chat-demo-${Date.now()}`);
	const store = new PreferenceStore(storeDir);

	// Short-term memory: conversation messages
	const conversation: ConversationMessage[] = [];

	console.log("====================================================");
	console.log("    Day 13 — Stateful Chat with Memory");
	console.log("====================================================\n");
	console.log(`Memory store: ${storeDir}\n`);

	// ── Turn 1: Set a preference ────────────────────────────────────────
	console.log("----------------------------------------------------");
	console.log("TURN 1: User sets a preference");
	console.log("----------------------------------------------------");
	console.log('User: "I prefer concise responses."');

	const pref = store.set("responseStyle", "concise", true);
	console.log(
		`\n[Long-term memory] Stored: ${pref.key} = "${pref.value}" (source: ${pref.source})`,
	);

	conversation.push({ role: "user", content: "I prefer concise responses." });
	conversation.push({
		role: "assistant",
		content: "Noted! I've saved your preference for concise responses.",
	});

	console.log('Assistant: "Noted! I\'ve saved your preference for concise responses."\n');

	// ── Turn 2: Ask a question (preference is applied) ──────────────────
	console.log("----------------------------------------------------");
	console.log("TURN 2: User asks a question (preference applied)");
	console.log("----------------------------------------------------");

	const currentPrefs = store.list();
	const systemPrompt = buildSystemPrompt(currentPrefs);
	console.log(`[System prompt]:\n${systemPrompt}\n`);

	const query = "How do I create a TypeScript project?";
	console.log(`User: "${query}"`);

	const response = simulateResponse(query, currentPrefs);
	conversation.push({ role: "user", content: query });
	conversation.push({ role: "assistant", content: response });

	console.log(`Assistant: "${response}"\n`);
	console.log(`[Short-term memory] ${conversation.length} messages in conversation.\n`);

	// ── Turn 3: Try storing a secret (rejected) ─────────────────────────
	console.log("----------------------------------------------------");
	console.log("TURN 3: Attempt to store a secret (safety gate)");
	console.log("----------------------------------------------------");
	console.log('User: "Store my API key: sk-or-v1-abcdefghijklmnop"');

	try {
		store.set("openaiApiKey", "sk-or-v1-abcdefghijklmnop", true);
	} catch (error: any) {
		console.log(`\n[BLOCKED] ${error.message}\n`);
	}

	// ── Turn 4: Reset all preferences ───────────────────────────────────
	console.log("----------------------------------------------------");
	console.log("TURN 4: User resets all preferences");
	console.log("----------------------------------------------------");
	console.log('User: "Reset all my preferences."');

	const deleted = store.reset();
	console.log(`\n[Long-term memory] Reset: ${deleted} preference(s) deleted.`);

	const emptyPrompt = buildSystemPrompt(store.list());
	console.log(`[System prompt after reset]:\n${emptyPrompt}\n`);

	const responseAfterReset = simulateResponse(query, store.list());
	console.log(`Assistant (same question, no preferences): "${responseAfterReset}"\n`);

	// ── Audit Log ───────────────────────────────────────────────────────
	console.log("----------------------------------------------------");
	console.log("AUDIT LOG (value-free)");
	console.log("----------------------------------------------------");
	console.log(store.getAuditLog());
}

main();
