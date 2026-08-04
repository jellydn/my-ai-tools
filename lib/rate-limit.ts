import type { MiddlewareHandler } from "hono";

export interface RateLimiter {
	middleware: MiddlewareHandler;
	prune(): void;
}

export function createRateLimiter(windowMs: number, maxRequests: number): RateLimiter {
	const requestTimestamps = new Map<string, number[]>();

	return {
		middleware: async (c, next) => {
			const forwarded = c.req.header("x-forwarded-for");
			const clientIp = c.req.header("fly-client-ip") || (forwarded ? forwarded.split(",")[0]?.trim() : undefined);
			const key = clientIp ?? "unknown";
			const now = Date.now();
			const timestamps = requestTimestamps.get(key) ?? [];
			const recent = timestamps.filter((timestamp) => now - timestamp < windowMs);

			if (recent.length >= maxRequests) return c.json({ error: "Rate limit exceeded. Try again later." }, 429);
			recent.push(now);
			requestTimestamps.set(key, recent);
			return next();
		},
		prune() {
			const now = Date.now();
			for (const [key, timestamps] of requestTimestamps.entries()) {
				const recent = timestamps.filter((timestamp) => now - timestamp < windowMs);
				if (recent.length === 0) requestTimestamps.delete(key);
				else requestTimestamps.set(key, recent);
			}
		},
	};
}
