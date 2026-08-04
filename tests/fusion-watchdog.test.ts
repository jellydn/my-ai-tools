import { expect, test } from "bun:test";
import {
	checkWatchdog,
	createActivityWatchdog,
	EXECUTOR_INACTIVITY_TIMEOUT_MS,
	EXECUTOR_MAX_TIMEOUT_MS,
	ExecutorWaitError,
} from "../configs/amp/lib/fusion-watchdog";

// ─── Pure function tests: checkWatchdog ──────────────────────────────

test("checkWatchdog: continues when within all deadlines", () => {
	expect(checkWatchdog(60_000, 60_000, false)).toEqual({ action: "continue" });
});

test("checkWatchdog: continues with in-flight tools even if inactivity is high", () => {
	expect(checkWatchdog(60_000, EXECUTOR_INACTIVITY_TIMEOUT_MS + 1000, true)).toEqual({
		action: "continue",
	});
});

test("checkWatchdog: rejects max-wait when elapsed exceeds absolute cap", () => {
	const verdict = checkWatchdog(EXECUTOR_MAX_TIMEOUT_MS + 1, 0, true);
	expect(verdict.action).toBe("reject");
	if (verdict.action !== "reject") throw new Error("unreachable");
	expect(verdict.kind).toBe("max-wait");
	expect(verdict.message).toBe("Executor exceeded maximum wait of 60 minutes (total elapsed).");
});

test("checkWatchdog: rejects inactivity when no activity and no in-flight", () => {
	const verdict = checkWatchdog(60_000, EXECUTOR_INACTIVITY_TIMEOUT_MS + 1, false);
	expect(verdict.action).toBe("reject");
	if (verdict.action !== "reject") throw new Error("unreachable");
	expect(verdict.kind).toBe("inactivity");
	expect(verdict.message).toBe("Executor timed out after 10 minutes of inactivity.");
});

test("checkWatchdog: max-wait takes priority over inactivity", () => {
	const verdict = checkWatchdog(
		EXECUTOR_MAX_TIMEOUT_MS + 1,
		EXECUTOR_INACTIVITY_TIMEOUT_MS + 1,
		false,
	);
	expect(verdict.action).toBe("reject");
	if (verdict.action !== "reject") throw new Error("unreachable");
	expect(verdict.kind).toBe("max-wait");
});

test("checkWatchdog: inactivity not triggered when in-flight is true even if elapsed exceeds inactivity", () => {
	expect(checkWatchdog(30_000, EXECUTOR_INACTIVITY_TIMEOUT_MS + 1, true)).toEqual({
		action: "continue",
	});
});

// ─── Integration tests: createActivityWatchdog ────────────────────────

test("createActivityWatchdog: does not reject while activity is recent", async () => {
	const watchdog = createActivityWatchdog(
		() => 0,
		() => true,
		0,
		() => 5_000,
		5,
	);

	await Promise.race([watchdog.promise, new Promise((r) => setTimeout(r, 50))]);
	watchdog.cleanup();
});

test("createActivityWatchdog: rejects with inactivity when no activity and no in-flight", async () => {
	const watchdog = createActivityWatchdog(
		() => 0,
		() => false,
		0,
		() => EXECUTOR_INACTIVITY_TIMEOUT_MS + 1000,
		5,
	);

	try {
		await watchdog.promise;
		throw new Error("should have rejected");
	} catch (error) {
		expect(error).toBeInstanceOf(ExecutorWaitError);
		expect((error as ExecutorWaitError).kind).toBe("inactivity");
	}
	watchdog.cleanup();
});

test("createActivityWatchdog: rejects with max-wait when absolute cap exceeded", async () => {
	const watchdog = createActivityWatchdog(
		() => 0,
		() => true,
		0,
		() => EXECUTOR_MAX_TIMEOUT_MS + 1000,
		5,
	);

	try {
		await watchdog.promise;
		throw new Error("should have rejected");
	} catch (error) {
		expect(error).toBeInstanceOf(ExecutorWaitError);
		expect((error as ExecutorWaitError).kind).toBe("max-wait");
	}
	watchdog.cleanup();
});

test("createActivityWatchdog: in-flight prevents inactivity timeout", async () => {
	const watchdog = createActivityWatchdog(
		() => 0,
		() => true,
		0,
		() => EXECUTOR_INACTIVITY_TIMEOUT_MS + 1000,
		5,
	);

	await Promise.race([watchdog.promise, new Promise((r) => setTimeout(r, 50))]);
	watchdog.cleanup();
});

test("createActivityWatchdog: cleanup stops the timer", async () => {
	const watchdog = createActivityWatchdog(
		() => 0,
		() => false,
		0,
		() => EXECUTOR_INACTIVITY_TIMEOUT_MS + 1000,
		5,
	);

	watchdog.cleanup();

	await new Promise((r) => setTimeout(r, 30));
	let settled = false;
	watchdog.promise.catch(() => {
		settled = true;
	});
	await new Promise((r) => setTimeout(r, 20));
	expect(settled).toBe(false);
});

test("createActivityWatchdog: ExecutorWaitError has correct kind for inactivity", async () => {
	const watchdog = createActivityWatchdog(
		() => 0,
		() => false,
		0,
		() => EXECUTOR_INACTIVITY_TIMEOUT_MS + 1,
		5,
	);

	try {
		await watchdog.promise;
		throw new Error("should have rejected");
	} catch (error) {
		expect(error).toBeInstanceOf(ExecutorWaitError);
		expect((error as ExecutorWaitError).kind).toBe("inactivity");
		expect((error as ExecutorWaitError).name).toBe("ExecutorWaitError");
	}
	watchdog.cleanup();
});

test("createActivityWatchdog: ExecutorWaitError has correct kind for max-wait", async () => {
	const watchdog = createActivityWatchdog(
		() => 0,
		() => true,
		0,
		() => EXECUTOR_MAX_TIMEOUT_MS + 1,
		5,
	);

	try {
		await watchdog.promise;
		throw new Error("should have rejected");
	} catch (error) {
		expect(error).toBeInstanceOf(ExecutorWaitError);
		expect((error as ExecutorWaitError).kind).toBe("max-wait");
	}
	watchdog.cleanup();
});

// ─── Promise.race simulation: completion wins over watchdog ───────────

test("Promise.race: immediate resolution wins over watchdog", async () => {
	const startTime = Date.now();
	const watchdog = createActivityWatchdog(
		() => startTime,
		() => false,
		startTime,
	);

	const immediateResponse = Promise.resolve({ content: [{ type: "text", text: "done" }] });

	const result = await Promise.race([immediateResponse, watchdog.promise]);

	watchdog.cleanup();
	expect((result as { content: { type: string; text: string }[] }).content[0].text).toBe("done");
});

// ─── Watchdog self-cleanup on reject ─────────────────────────────────

test("createActivityWatchdog: self-clears interval on reject (no timer leak)", async () => {
	let tickCount = 0;
	const startTime = 0;

	// Track ticks via the getLastActivity callback, which fires on every
	// interval evaluation. After rejection, the interval should self-clear
	// and tickCount must stop increasing.
	const watchdog = createActivityWatchdog(
		() => {
			tickCount++;
			return 0;
		},
		() => false,
		startTime,
		() => EXECUTOR_INACTIVITY_TIMEOUT_MS + 1000,
		5, // 5ms interval
	);

	// Wait for rejection
	try {
		await watchdog.promise;
		throw new Error("should have rejected");
	} catch (error) {
		expect(error).toBeInstanceOf(ExecutorWaitError);
	}

	// Record the tick count at rejection, then wait several interval
	// periods. If the interval did not self-clear, tickCount would
	// keep increasing.
	const ticksAtRejection = tickCount;
	await new Promise((r) => setTimeout(r, 30));
	expect(tickCount).toBe(ticksAtRejection);

	// cleanup() after self-clear should be a no-op (no throw).
	watchdog.cleanup();
});

test("createActivityWatchdog: cleanup is idempotent after self-clear", async () => {
	const watchdog = createActivityWatchdog(
		() => 0,
		() => false,
		0,
		() => EXECUTOR_INACTIVITY_TIMEOUT_MS + 1,
		5,
	);

	try {
		await watchdog.promise;
	} catch {
		// expected
	}

	// Multiple cleanup calls should be safe
	watchdog.cleanup();
	watchdog.cleanup();
	watchdog.cleanup();
});

// ─── In-flight Set semantics ─────────────────────────────────────────

test("checkWatchdog: multiple in-flight calls all prevent inactivity timeout", () => {
	// Simulates: tool.call fired twice (2 in-flight), neither has a result yet.
	// Even with high inactivity elapsed, in-flight=true prevents timeout.
	const verdict = checkWatchdog(
		EXECUTOR_INACTIVITY_TIMEOUT_MS + 5000,
		EXECUTOR_INACTIVITY_TIMEOUT_MS + 5000,
		true,
	);
	expect(verdict).toEqual({ action: "continue" });
});

test("checkWatchdog: in-flight=false after all results arrive triggers inactivity", () => {
	// Simulates: all tool results arrived, then no activity for 10+ min.
	const verdict = checkWatchdog(
		EXECUTOR_INACTIVITY_TIMEOUT_MS + 5000,
		EXECUTOR_INACTIVITY_TIMEOUT_MS + 1,
		false,
	);
	expect(verdict.action).toBe("reject");
	if (verdict.action !== "reject") throw new Error("unreachable");
	expect(verdict.kind).toBe("inactivity");
});
