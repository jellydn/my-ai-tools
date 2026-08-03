// Activity watchdog for the Fusion executor wait loop.
//
// This module is dependency-free (no @ampcode/plugin import) so it can be
// imported and unit-tested in isolation with bun test.

/** How often the watchdog checks inactivity and max-wait deadlines. */
export const EXECUTOR_WATCHDOG_INTERVAL_MS = 2 * 60 * 1000; // 2 minutes

/** Declare a genuine timeout after this much continuous inactivity (no tool
 *  calls or results) when no tool calls are in-flight. */
export const EXECUTOR_INACTIVITY_TIMEOUT_MS = 10 * 60 * 1000; // 10 minutes

/** Absolute cap: never wait longer than this, even if the executor is active. */
export const EXECUTOR_MAX_TIMEOUT_MS = 60 * 60 * 1000; // 60 minutes

export type WatchdogKind = "inactivity" | "max-wait";

/** Typed error so the catch block can classify without string matching. */
export class ExecutorWaitError extends Error {
	constructor(
		message: string,
		public readonly kind: WatchdogKind,
	) {
		super(message);
		this.name = "ExecutorWaitError";
	}
}

/** Verdict from a single watchdog tick. */
export type WatchdogVerdict = { action: "continue" } | { action: "reject"; kind: WatchdogKind; message: string };

/**
 * Pure watchdog check — no timers, no side effects.
 *
 * @param elapsed          Milliseconds since the executor started.
 * @param lastActivityElapsed Milliseconds since the last tool activity.
 * @param hasInFlight      Whether any tool calls are currently executing.
 * @returns Whether to continue waiting or reject with a typed error.
 */
export function checkWatchdog(elapsed: number, lastActivityElapsed: number, hasInFlight: boolean): WatchdogVerdict {
	if (elapsed >= EXECUTOR_MAX_TIMEOUT_MS) {
		return {
			action: "reject",
			kind: "max-wait",
			message: `Executor exceeded maximum wait of ${EXECUTOR_MAX_TIMEOUT_MS / 60000} minutes (total elapsed).`,
		};
	}

	if (!hasInFlight && lastActivityElapsed >= EXECUTOR_INACTIVITY_TIMEOUT_MS) {
		return {
			action: "reject",
			kind: "inactivity",
			message: `Executor timed out after ${EXECUTOR_INACTIVITY_TIMEOUT_MS / 60000} minutes of inactivity.`,
		};
	}

	return { action: "continue" };
}

export interface WatchdogControls {
	/** A promise that rejects (never resolves) when a deadline is exceeded. */
	promise: Promise<never>;
	/** Stop the watchdog timer. Safe to call multiple times. */
	cleanup: () => void;
}

/**
 * Create an activity watchdog that periodically checks whether the executor
 * is still making progress.
 *
 * The returned promise rejects with {@link ExecutorWaitError} when:
 * - The executor has had no tool activity for {@link EXECUTOR_INACTIVITY_TIMEOUT_MS}
 *   and no tool calls are in-flight, OR
 * - The total elapsed time exceeds {@link EXECUTOR_MAX_TIMEOUT_MS}.
 *
 * Always call {@link WatchdogControls.cleanup} when the race settles
 * (success, failure, or cancellation) to clear the interval timer.
 *
 * @param getLastActivity  Returns the timestamp of the most recent tool activity.
 * @param hasInFlight      Returns whether any tool calls are currently executing.
 * @param startTime        The timestamp the executor started waiting.
 * @param now              Injected clock for testing (defaults to Date.now).
 * @param intervalMs       Injected interval for testing (defaults to EXECUTOR_WATCHDOG_INTERVAL_MS).
 */
export function createActivityWatchdog(
	getLastActivity: () => number,
	hasInFlight: () => boolean,
	startTime: number,
	now: () => number = Date.now,
	intervalMs: number = EXECUTOR_WATCHDOG_INTERVAL_MS,
): WatchdogControls {
	let timer: ReturnType<typeof setInterval> | null = null;

	// Declared before the promise so the interval callback can self-clear
	// on reject without waiting for an external caller to invoke cleanup.
	const cleanup = () => {
		if (timer !== null) {
			clearInterval(timer);
			timer = null;
		}
	};

	const promise = new Promise<never>((_, reject) => {
		timer = setInterval(() => {
			const currentTime = now();
			const elapsed = currentTime - startTime;
			const lastActivityElapsed = currentTime - getLastActivity();

			const verdict = checkWatchdog(elapsed, lastActivityElapsed, hasInFlight());
			if (verdict.action === "reject") {
				// Self-clear the interval immediately so the timer stops firing
				// after the promise has already rejected. This makes the module
				// safe to reuse even if a caller forgets to call cleanup().
				cleanup();
				reject(new ExecutorWaitError(verdict.message, verdict.kind));
			}
		}, intervalMs);
	});

	return { promise, cleanup };
}
