import { createHmac, createSign, timingSafeEqual } from "node:crypto";

const encode = (value: string | object) =>
	Buffer.from(typeof value === "string" ? value : JSON.stringify(value)).toString("base64url");
export function createAppJwt(appId: string, privateKey: string, now = Date.now()): string {
	const payload = `${encode({ alg: "RS256", typ: "JWT" })}.${encode({ iat: Math.floor(now / 1000) - 60, exp: Math.floor(now / 1000) + 540, iss: appId })}`;
	const signer = createSign("RSA-SHA256");
	signer.update(payload);
	return `${payload}.${signer.sign(privateKey, "base64url")}`;
}
export function verifyWebhook(raw: Uint8Array, signature: string | undefined, secret: string): boolean {
	if (!signature || !/^sha256=[0-9a-f]{64}$/i.test(signature)) return false;
	const expected = Buffer.from(createHmac("sha256", secret).update(raw).digest("hex"), "hex");
	let supplied: Buffer;
	try {
		supplied = Buffer.from(signature.slice(7), "hex");
	} catch {
		return false;
	}
	return supplied.length === expected.length && timingSafeEqual(supplied, expected);
}
export class GitHubClient {
	constructor(
		private token: string,
		private fetcher: typeof fetch = fetch,
		private base = "https://api.github.com",
	) {}
	async request<T>(method: string, path: string, body?: unknown, signal?: AbortSignal): Promise<T> {
		const response = await this.fetcher(`${this.base}${path}`, {
			method,
			headers: {
				accept: "application/vnd.github+json",
				authorization: `Bearer ${this.token}`,
				"content-type": "application/json",
				"user-agent": "my-ai-bot",
			},
			body: body === undefined ? undefined : JSON.stringify(body),
			signal,
		});
		if (!response.ok)
			throw Object.assign(new Error(`GitHub API ${response.status}`), {
				code: "GITHUB_API_ERROR",
				status: response.status,
			});
		return response.status === 204 ? (undefined as T) : ((await response.json()) as T);
	}
	async paginate<T>(path: string, signal?: AbortSignal): Promise<T[]> {
		const all: T[] = [];
		for (let page = 1; ; page++) {
			const separator = path.includes("?") ? "&" : "?";
			const batch = await this.request<T[]>("GET", `${path}${separator}per_page=100&page=${page}`, undefined, signal);
			all.push(...batch);
			if (batch.length < 100) return all;
		}
	}
	async repositorySnapshot(owner: string, repo: string, signal?: AbortSignal) {
		const repository = await this.request<{ default_branch: string }>(
			"GET",
			`/repos/${owner}/${repo}`,
			undefined,
			signal,
		);
		const ref = await this.request<{ object: { sha: string } }>(
			"GET",
			`/repos/${owner}/${repo}/git/ref/heads/${encodeURIComponent(repository.default_branch)}`,
			undefined,
			signal,
		);
		return { defaultBranch: repository.default_branch, sha: ref.object.sha };
	}
	async refSha(owner: string, repo: string, ref: string, signal?: AbortSignal) {
		const value = await this.request<{ object: { sha: string } }>(
			"GET",
			`/repos/${owner}/${repo}/git/ref/heads/${encodeURIComponent(ref)}`,
			undefined,
			signal,
		);
		return value.object.sha;
	}
	async contentAt(
		owner: string,
		repo: string,
		path: string,
		ref: string,
		signal?: AbortSignal,
	): Promise<string | undefined> {
		try {
			const value = await this.request<{ content: string; encoding: string }>(
				"GET",
				`/repos/${owner}/${repo}/contents/${path}?ref=${encodeURIComponent(ref)}`,
				undefined,
				signal,
			);
			if (value.encoding !== "base64")
				throw Object.assign(new Error("Unsupported content encoding"), { code: "INVALID_CONFIG" });
			return Buffer.from(value.content.replace(/\n/g, ""), "base64").toString("utf8");
		} catch (error) {
			if ((error as { status?: number }).status === 404) return undefined;
			throw error;
		}
	}
	installationToken(id: number, permissions?: Record<string, "read" | "write">, signal?: AbortSignal) {
		return this.request<{ token: string; expires_at: string }>(
			"POST",
			`/app/installations/${id}/access_tokens`,
			permissions ? { permissions } : undefined,
			signal,
		);
	}
	permission(owner: string, repo: string, actor: string) {
		return this.request<{ permission: string }>("GET", `/repos/${owner}/${repo}/collaborators/${actor}/permission`);
	}
}
export async function installationClient(
	config: { appId: string; privateKey: string },
	id: number,
	fetcher: typeof fetch = fetch,
	permissions?: Record<string, "read" | "write">,
	signal?: AbortSignal,
) {
	const app = new GitHubClient(createAppJwt(config.appId, config.privateKey), fetcher);
	const { token, expires_at } = await app.installationToken(id, permissions, signal);
	return { client: new GitHubClient(token, fetcher), token, expiresAt: expires_at };
}
