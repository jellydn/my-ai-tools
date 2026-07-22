import { mkdir, readFile, rename, writeFile } from "node:fs/promises";
import { join } from "node:path";
import type { Job, JobState } from "./types.ts";

interface Delivery {
	status: "reserved" | "accepted" | "rejected";
	jobId?: string;
	code?: string;
}
interface Snapshot {
	jobs: Record<string, Job>;
	deliveries: Record<string, Delivery | string>;
}
const terminal = new Set<JobState>(["completed", "failed", "cancelled"]);
const active = new Set<JobState>(["preparing", "analyzing", "implementing", "validating", "publishing"]);
const legal: Record<JobState, JobState[]> = {
	queued: ["preparing", "cancelled", "failed"],
	preparing: ["analyzing", "implementing", "completed", "failed", "cancelled"],
	analyzing: ["implementing", "publishing", "completed", "failed", "cancelled"],
	implementing: ["validating", "failed", "cancelled"],
	validating: ["publishing", "completed", "failed", "cancelled"],
	publishing: ["completed", "failed", "cancelled"],
	completed: [],
	failed: [],
	cancelled: [],
};
export class JsonJobStore {
	private data: Snapshot = { jobs: {}, deliveries: {} };
	private chain = Promise.resolve();
	constructor(
		private dir: string,
		private clock = () => new Date(),
		private ids: () => string = () => crypto.randomUUID(),
	) {}
	async init() {
		await mkdir(this.dir, { recursive: true });
		try {
			this.data = JSON.parse(await readFile(join(this.dir, "jobs.json"), "utf8"));
		} catch (e) {
			if ((e as NodeJS.ErrnoException).code !== "ENOENT") throw e;
		}
		let changed = false;
		const at = this.clock().toISOString();
		for (const job of Object.values(this.data.jobs))
			if (active.has(job.state)) {
				job.state = job.cancelRequested ? "cancelled" : "queued";
				job.updatedAt = at;
				job.history.push({
					state: job.state,
					at,
					message: job.cancelRequested ? "Cancellation recovered after worker restart" : "Recovered after worker restart",
				});
				changed = true;
			}
		for (const [id, delivery] of Object.entries(this.data.deliveries))
			if (typeof delivery !== "string" && delivery.status === "reserved") {
				delete this.data.deliveries[id];
				changed = true;
			}
		if (changed) await this.persist();
	}
	private async persist() {
		const temp = join(this.dir, `jobs.${process.pid}.tmp`);
		await writeFile(temp, JSON.stringify(this.data, null, 2), { mode: 0o600 });
		await rename(temp, join(this.dir, "jobs.json"));
	}
	private mutate<T>(fn: () => T | Promise<T>): Promise<T> {
		const result = this.chain.then(async () => {
			const value = await fn();
			await this.persist();
			return value;
		});
		this.chain = result.then(
			() => undefined,
			() => undefined,
		);
		return result;
	}
	async reserveDelivery(id: string): Promise<boolean> {
		return this.mutate(() => {
			if (this.data.deliveries[id]) return false;
			this.data.deliveries[id] = { status: "reserved" };
			return true;
		});
	}
	async finishDelivery(id: string, result: Omit<Delivery, "status"> & { status: Delivery["status"] }) {
		return this.mutate(() => {
			this.data.deliveries[id] = result;
		});
	}
	async releaseDelivery(id: string) {
		return this.mutate(() => {
			const delivery = this.data.deliveries[id];
			if (typeof delivery !== "string" && delivery?.status === "reserved") delete this.data.deliveries[id];
		});
	}
	async enqueue(
		input: Omit<Job, "id" | "createdAt" | "updatedAt" | "state" | "history" | "publication" | "retryCount">,
	): Promise<{ job: Job; duplicate: boolean }> {
		return this.mutate(() => {
			const old = this.data.deliveries[input.deliveryId];
			const oldId = typeof old === "string" ? old : old?.jobId;
			if (oldId) return { job: this.data.jobs[oldId]!, duplicate: true };
			const at = this.clock().toISOString();
			const job: Job = {
				...input,
				id: this.ids(),
				state: "queued",
				createdAt: at,
				updatedAt: at,
				history: [{ state: "queued", at }],
				publication: {},
				retryCount: 0,
			};
			this.data.jobs[job.id] = job;
			this.data.deliveries[input.deliveryId] = { status: "accepted", jobId: job.id };
			return { job, duplicate: false };
		});
	}
	get(id: string) {
		return this.data.jobs[id];
	}
	list() {
		return Object.values(this.data.jobs);
	}
	async patch(id: string, patch: Partial<Job>, message?: string) {
		return this.mutate(() => {
			const job = this.data.jobs[id];
			if (!job) throw Object.assign(new Error("Job not found"), { code: "JOB_NOT_FOUND" });
			const at = this.clock().toISOString();
			Object.assign(job, patch, { updatedAt: at });
			if (message) job.history.push({ state: job.state, at, message });
			return job;
		});
	}
	newest(owner: string, repo: string, issue: number) {
		return this.list()
			.filter((j) => j.owner === owner && j.repo === repo && j.issue === issue)
			.sort((a, b) => b.createdAt.localeCompare(a.createdAt))[0];
	}
	async transition(id: string, state: JobState, patch: Partial<Job> = {}, message?: string, expected?: JobState) {
		return this.mutate(() => {
			const job = this.data.jobs[id];
			if (!job) throw Object.assign(new Error("Job not found"), { code: "JOB_NOT_FOUND" });
			if (expected && job.state !== expected) throw Object.assign(new Error("State conflict"), { code: "STATE_CONFLICT" });
			if (terminal.has(job.state) || !legal[job.state].includes(state))
				throw Object.assign(new Error(`Illegal transition ${job.state} -> ${state}`), { code: "ILLEGAL_TRANSITION" });
			const at = this.clock().toISOString();
			Object.assign(job, patch, { state, updatedAt: at });
			job.history.push({ state, at, message });
			return job;
		});
	}
	async requestCancel(id: string) {
		const job = this.get(id);
		if (!job || terminal.has(job.state)) return job;
		if (job.state === "queued") return this.transition(id, "cancelled", { cancelRequested: true });
		return this.mutate(() => {
			const current = this.data.jobs[id]!;
			current.cancelRequested = true;
			current.updatedAt = this.clock().toISOString();
			return current;
		});
	}
	async claim(concurrency: number) {
		return this.mutate(() => {
			const running = this.list().filter((j) => active.has(j.state));
			if (running.length >= concurrency) return undefined;
			const locks = new Set(running.map((j) => `${j.owner}/${j.repo}#${j.issue}`));
			const job = this.list().find(
				(j) => !j.cancelRequested && j.state === "queued" && !locks.has(`${j.owner}/${j.repo}#${j.issue}`),
			);
			if (!job) return undefined;
			const at = this.clock().toISOString();
			job.state = "preparing";
			job.updatedAt = at;
			job.history.push({ state: "preparing", at });
			return job;
		});
	}
}
