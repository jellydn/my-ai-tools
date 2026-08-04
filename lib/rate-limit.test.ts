import { describe, expect, test } from "bun:test";
import { Hono } from "hono";
import { createRateLimiter } from "./rate-limit.ts";

describe("rate limiter", () => {
	test("limits each forwarded client after the configured threshold", async () => {
		const app = new Hono();
		const limiter = createRateLimiter(60_000, 1);
		app.get("/", limiter.middleware, (c) => c.text("ok"));
		expect((await app.request("http://test/", { headers: { "x-forwarded-for": "192.0.2.1" } })).status).toBe(200);
		expect((await app.request("http://test/", { headers: { "x-forwarded-for": "192.0.2.1" } })).status).toBe(429);
		expect((await app.request("http://test/", { headers: { "x-forwarded-for": "192.0.2.2" } })).status).toBe(200);
	});
});
