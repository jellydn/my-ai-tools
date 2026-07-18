import { randomUUID } from "node:crypto";
import { appendFile, chmod, mkdir, readFile, rename, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import lockfile from "proper-lockfile";
import { emptyUserMemory, type UserMemory, type UserPreference, userMemorySchema } from "./schema.js";

const KEY_PATTERN = /^[A-Za-z][A-Za-z0-9._-]{0,99}$/;
const MAX_VALUE_LENGTH = 1_000;

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
	/\b(?:github_pat_|gh[pousr]_|glpat-|xox[baprs]-)[A-Za-z0-9_-]{8,}\b/,
	/\bAKIA[0-9A-Z]{16}\b/,
	/\bBearer\s+[A-Za-z0-9._~+/-]+=*\b/i,
	/\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b/,
	/\b[a-z][a-z0-9+.-]*:\/\/[^\s/:]+:[^\s/@]+@/i,
	/\b(?:api[_-]?key|access[_-]?token|password|secret)\s*[:=]\s*\S+/i,
];

type AuditOperation = "set" | "delete" | "reset";

type AuditEntry = {
	operation: AuditOperation;
	key?: string;
	timestamp: string;
};

export type PreferenceStoreOptions = {
	directory?: string;
	now?: () => Date;
};

export class PreferenceStore {
	readonly directory: string;
	readonly memoryPath: string;
	readonly auditPath: string;
	readonly lockPath: string;

	private readonly now: () => Date;

	constructor(options: PreferenceStoreOptions = {}) {
		this.directory = options.directory ?? process.env.USER_MEMORY_HOME ?? join(homedir(), ".ai-tools", "user-memory");
		this.memoryPath = join(this.directory, "preferences.json");
		this.auditPath = join(this.directory, "audit.jsonl");
		this.lockPath = join(this.directory, ".lock");
		this.now = options.now ?? (() => new Date());
	}

	async set(key: string, value: string, explicit: boolean): Promise<UserPreference> {
		if (!explicit) {
			throw new Error("Preferences may only be stored after the user explicitly states or confirms them.");
		}
		this.validatePreference(key, value);

		return this.withLock(async () => {
			const memory = await this.readMemory();
			const timestamp = this.now().toISOString();
			const existing = memory.preferences.find((preference) => preference.key === key);
			const preference: UserPreference = existing
				? { ...existing, value, updatedAt: timestamp }
				: { key, value, source: "explicit", createdAt: timestamp, updatedAt: timestamp };

			if (existing) {
				memory.preferences[memory.preferences.indexOf(existing)] = preference;
			} else {
				memory.preferences.push(preference);
			}

			await this.writeMemory(memory);
			await this.appendAuditBestEffort({ operation: "set", key, timestamp });
			return preference;
		});
	}

	async get(key: string): Promise<UserPreference | undefined> {
		const memory = await this.readMemory();
		return memory.preferences.find((preference) => preference.key === key);
	}

	async list(): Promise<UserPreference[]> {
		const memory = await this.readMemory();
		return [...memory.preferences].sort((left, right) => left.key.localeCompare(right.key));
	}

	async delete(key: string): Promise<boolean> {
		return this.withLock(async () => {
			const memory = await this.readMemory();
			const remaining = memory.preferences.filter((preference) => preference.key !== key);
			if (remaining.length === memory.preferences.length) {
				return false;
			}

			memory.preferences = remaining;
			const timestamp = this.now().toISOString();
			await this.writeMemory(memory);
			await this.appendAuditBestEffort({ operation: "delete", key, timestamp });
			return true;
		});
	}

	async reset(): Promise<number> {
		return this.withLock(async () => {
			const memory = await this.readMemory();
			const deleted = memory.preferences.length;
			const timestamp = this.now().toISOString();
			await this.writeMemory(emptyUserMemory());
			await this.appendAuditBestEffort({ operation: "reset", timestamp });
			return deleted;
		});
	}

	private validatePreference(key: string, value: string): void {
		if (!KEY_PATTERN.test(key)) {
			throw new Error(
				"Preference keys must start with a letter and contain at most 100 letters, numbers, dots, dashes, or underscores.",
			);
		}
		if (value.length === 0 || value.length > MAX_VALUE_LENGTH) {
			throw new Error(`Preference values must contain between 1 and ${MAX_VALUE_LENGTH} characters.`);
		}

		const normalizedKey = key.toLowerCase().replaceAll(/[^a-z0-9]/g, "");
		if (
			SECRET_KEY_PARTS.some((part) => normalizedKey.includes(part)) ||
			SECRET_VALUE_PATTERNS.some((pattern) => pattern.test(value))
		) {
			throw new Error("Secrets, credentials, API keys, tokens, and passwords cannot be stored as preferences.");
		}
	}

	private async ensureDirectory(): Promise<void> {
		await mkdir(this.directory, { recursive: true, mode: 0o700 });
		await chmod(this.directory, 0o700);
	}

	private async readMemory(): Promise<UserMemory> {
		try {
			const contents = await readFile(this.memoryPath, "utf8");
			return userMemorySchema.parse(JSON.parse(contents));
		} catch (error) {
			if ((error as NodeJS.ErrnoException).code === "ENOENT") {
				return emptyUserMemory();
			}
			throw error;
		}
	}

	private async writeMemory(memory: UserMemory): Promise<void> {
		await this.ensureDirectory();
		const temporaryPath = `${this.memoryPath}.${process.pid}.${randomUUID()}.tmp`;
		await writeFile(temporaryPath, `${JSON.stringify(memory, null, 2)}\n`, { encoding: "utf8", mode: 0o600 });
		await rename(temporaryPath, this.memoryPath);
		await chmod(this.memoryPath, 0o600);
	}

	private async appendAuditBestEffort(entry: AuditEntry): Promise<void> {
		try {
			await this.ensureDirectory();
			await appendFile(this.auditPath, `${JSON.stringify(entry)}\n`, { encoding: "utf8", mode: 0o600 });
			await chmod(this.auditPath, 0o600);
		} catch (error) {
			console.error("user-memory: preference was saved, but its audit entry could not be written", error);
		}
	}

	private async withLock<T>(operation: () => Promise<T>): Promise<T> {
		await this.ensureDirectory();
		const release = await lockfile.lock(this.directory, {
			lockfilePath: this.lockPath,
			realpath: false,
			retries: { retries: 80, factor: 1, minTimeout: 25, maxTimeout: 25 },
			stale: 10_000,
			update: 2_000,
		});

		try {
			return await operation();
		} finally {
			await release();
		}
	}
}
