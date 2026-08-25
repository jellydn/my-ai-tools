import type { Job } from "./types.ts";

export interface WorkerLifecycleOptions {
	claim: () => Promise<Job | undefined>;
	execute: (job: Job, signal: AbortSignal) => Promise<void>;
	cancelAgent: (id: string) => Promise<void> | void;
	intervalMs?: number;
}

/** Owns worker scheduling and cancellation without knowing how a job executes. */
export class WorkerLifecycle {
	private timer?: ReturnType<typeof setInterval>;
	private stopping = false;
	private controllers = new Map<string, AbortController>();

	constructor(private options: WorkerLifecycleOptions) {}

	start() {
		if (this.timer || this.stopping) return;
		this.timer = setInterval(() => void this.tick().catch(() => undefined), this.options.intervalMs ?? 500);
		this.timer.unref();
		void this.tick().catch(() => undefined);
	}

	async stop() {
		this.stopping = true;
		if (this.timer) {
			clearInterval(this.timer);
			this.timer = undefined;
		}
		for (const id of this.controllers.keys()) this.cancel(id);
		while (this.controllers.size) await new Promise((resolve) => setTimeout(resolve, 20));
	}

	cancel(id: string) {
		this.controllers.get(id)?.abort();
		void this.options.cancelAgent(id);
	}

	async tick() {
		if (this.stopping) return;
		const job = await this.options.claim();
		if (!job) return;
		const controller = new AbortController();
		this.controllers.set(job.id, controller);
		void this.options
			.execute(job, controller.signal)
			.catch(() => undefined)
			.finally(() => this.controllers.delete(job.id));
	}
}
