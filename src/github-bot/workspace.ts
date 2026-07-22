import { spawn } from "node:child_process";
import { chmod, mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import type { RepoConfig } from "./config.ts";
import { commandAllowed, scanSecrets } from "./security.ts";

export interface RunOptions {
	env?: NodeJS.ProcessEnv;
	signal?: AbortSignal;
	timeoutMs?: number;
	maxOutputBytes?: number;
	home?: string;
}
export async function runArgv(
	argv: string[],
	cwd: string,
	config: RepoConfig,
	branch?: string,
	options: RunOptions | NodeJS.ProcessEnv = {},
) {
	const suppliedOptions = options as RunOptions;
	if (suppliedOptions.signal?.aborted) throw Object.assign(new Error("Command cancelled"), { code: "CANCELLED" });
	const policy = commandAllowed(argv, cwd, config, branch);
	if (!policy.allowed) throw Object.assign(new Error(policy.reason), { code: "COMMAND_BLOCKED" });
	const opts: RunOptions =
		"env" in options || "signal" in options || "timeoutMs" in options || "home" in options
			? (options as RunOptions)
			: { env: options as NodeJS.ProcessEnv };
	const limit = opts.maxOutputBytes ?? 1_000_000;
	return new Promise<{ stdout: string; stderr: string }>((resolve, reject) => {
		const child = spawn(argv[0]!, argv.slice(1), {
			cwd,
			shell: false,
			detached: process.platform !== "win32",
			env: { PATH: process.env.PATH ?? "/usr/bin:/bin", HOME: opts.home ?? cwd, ...(opts.env ?? {}) },
		});
		let stdout = Buffer.alloc(0),
			stderr = Buffer.alloc(0),
			killedForOutput = false;
		const append = (old: Buffer, value: Buffer) => {
			const next = Buffer.concat([old, value]);
			if (next.length > limit) {
				killedForOutput = true;
				terminate(child.pid, child);
				return next.subarray(0, limit);
			}
			return next;
		};
		child.stdout.on("data", (x) => {
			stdout = append(stdout, x);
		});
		child.stderr.on("data", (x) => {
			stderr = append(stderr, x);
		});
		const abort = () => terminate(child.pid, child);
		opts.signal?.addEventListener("abort", abort, { once: true });
		const timer = setTimeout(abort, opts.timeoutMs ?? 10 * 60_000);
		timer.unref();
		child.once("error", reject);
		child.once("close", (code) => {
			clearTimeout(timer);
			opts.signal?.removeEventListener("abort", abort);
			if (opts.signal?.aborted) reject(Object.assign(new Error("Command cancelled"), { code: "CANCELLED" }));
			else if (killedForOutput)
				reject(Object.assign(new Error("Command output limit exceeded"), { code: "OUTPUT_LIMIT" }));
			else if (code !== 0) reject(Object.assign(new Error(stderr.toString().slice(0, 500)), { code: "COMMAND_FAILED" }));
			else resolve({ stdout: stdout.toString(), stderr: stderr.toString() });
		});
	});
}
function terminate(pid: number | undefined, child: ReturnType<typeof spawn>) {
	try {
		if (pid) process.kill(process.platform === "win32" ? pid : -pid, "SIGTERM");
		else child.kill("SIGTERM");
	} catch {
		child.kill("SIGTERM");
	}
	setTimeout(() => {
		if (child.exitCode === null)
			try {
				if (pid) process.kill(process.platform === "win32" ? pid : -pid, "SIGKILL");
				else child.kill("SIGKILL");
			} catch {
				child.kill("SIGKILL");
			}
	}, 1000).unref();
}

export async function createWorkspace(root: string) {
	await mkdir(root, { recursive: true });
	return mkdtemp(join(root, "job-"));
}
export async function cloneExact(
	workspace: string,
	owner: string,
	repo: string,
	ref: string,
	sha: string,
	token: string,
	config: RepoConfig,
	signal?: AbortSignal,
) {
	const authDir = await mkdtemp(join(dirname(workspace), ".auth-"));
	const askpass = join(authDir, "askpass");
	const home = join(authDir, "home");
	await mkdir(home);
	await writeFile(
		askpass,
		"#!/bin/sh\ncase \"$1\" in *Username*) printf '%s\\n' x-access-token;; *) printf '%s\\n' \"$GITHUB_TOKEN\";; esac\n",
		{ mode: 0o700 },
	);
	await chmod(askpass, 0o700);
	try {
		await runArgv(
			["git", "clone", "--no-checkout", "--filter=blob:none", "--", `https://github.com/${owner}/${repo}.git`, "."],
			workspace,
			config,
			undefined,
			{
				signal,
				env: { GIT_ASKPASS: askpass, GIT_TERMINAL_PROMPT: "0", GITHUB_TOKEN: token },
				home,
			},
		);
		await runArgv(["git", "fetch", "--depth=1", "origin", ref], workspace, config, undefined, {
			signal,
			env: { GIT_ASKPASS: askpass, GIT_TERMINAL_PROMPT: "0", GITHUB_TOKEN: token },
		});
		await runArgv(["git", "checkout", "--detach", sha], workspace, config, undefined, { signal });
		const actual = (await runArgv(["git", "rev-parse", "HEAD"], workspace, config, undefined, { signal })).stdout.trim();
		if (actual !== sha) throw Object.assign(new Error("Base SHA mismatch"), { code: "BASE_MISMATCH" });
		const remote = (await runArgv(["git", "remote", "get-url", "origin"], workspace, config)).stdout;
		if (remote.includes(token) || /https?:\/\/[^/@]+@/.test(remote))
			throw Object.assign(new Error("Credential persisted in remote"), { code: "TOKEN_PERSISTED" });
	} finally {
		await rm(authDir, { recursive: true, force: true });
	}
}
export async function pushBranch(
	workspace: string,
	owner: string,
	repo: string,
	branch: string,
	expectedHead: string,
	token: string,
	config: RepoConfig,
	signal?: AbortSignal,
) {
	const root = dirname(workspace);
	const authDir = await mkdtemp(join(root, ".publish-auth-"));
	const publishDir = await mkdtemp(join(root, ".publish-"));
	const bundle = join(authDir, "publication.bundle");
	const askpass = join(authDir, "askpass");
	await writeFile(
		askpass,
		"#!/bin/sh\ncase \"$1\" in *Username*) printf '%s\\n' x-access-token;; *) printf '%s\\n' \"$GITHUB_TOKEN\";; esac\n",
		{ mode: 0o700 },
	);
	try {
		await runArgv(["git", "bundle", "create", bundle, "HEAD"], workspace, config, undefined, { signal });
		await runArgv(["git", "clone", "--no-checkout", "--", bundle, "."], publishDir, config, undefined, { signal });
		await runArgv(["git", "remote", "set-url", "origin", `https://github.com/${owner}/${repo}.git`], publishDir, config);
		const publicationHead = (await runArgv(["git", "rev-parse", "HEAD"], publishDir, config)).stdout.trim();
		if (publicationHead !== expectedHead)
			throw Object.assign(new Error("Publication repository HEAD mismatch"), { code: "PUBLICATION_MISMATCH" });
		await runArgv(["git", "push", "origin", `HEAD:refs/heads/${branch}`], publishDir, config, branch, {
			signal,
			env: {
				GIT_ASKPASS: askpass,
				GIT_TERMINAL_PROMPT: "0",
				GITHUB_TOKEN: token,
				GIT_CONFIG_NOSYSTEM: "1",
				GIT_CONFIG_GLOBAL: "/dev/null",
			},
			home: authDir,
		});
		const remote = (await runArgv(["git", "remote", "get-url", "origin"], publishDir, config)).stdout;
		if (remote.includes(token) || /https?:\/\/[^/@]+@/.test(remote))
			throw Object.assign(new Error("Credential persisted in publication remote"), { code: "TOKEN_PERSISTED" });
	} finally {
		await rm(authDir, { recursive: true, force: true });
		await rm(publishDir, { recursive: true, force: true });
	}
}
export async function inspectDiff(workspace: string, config: RepoConfig, signal?: AbortSignal) {
	const status = (await runArgv(["git", "status", "--porcelain=v1", "-z"], workspace, config, undefined, { signal }))
		.stdout;
	const entries = status.split("\0").filter(Boolean);
	const paths: string[] = [];
	for (let i = 0; i < entries.length; i++) {
		const row = entries[i]!;
		const code = row.slice(0, 2);
		const path = row.slice(3);
		if (code.includes("R") || code.includes("C")) {
			paths.push(entries[++i]!, path);
		} else paths.push(path);
	}
	const names = [...new Set(paths)];
	if (!names.length) throw Object.assign(new Error("Empty diff"), { code: "EMPTY_DIFF" });
	const mandatoryProhibited = [".env", ".npmrc", ".git/config", ".git/credentials"];
	if (
		names.some(
			(x) =>
				x.startsWith("/") ||
				x.split("/").includes("..") ||
				[...mandatoryProhibited, ...config.security.prohibitedFiles].some((p) => x === p || x.endsWith(`/${p}`)),
		)
	)
		throw Object.assign(new Error("Prohibited path"), { code: "PROHIBITED_PATH" });
	if (config.implementation.protectWorkflows && names.some((x) => x.startsWith(".github/workflows/")))
		throw Object.assign(new Error("Workflow changes prohibited"), { code: "WORKFLOW_PROTECTED" });
	await runArgv(["git", "add", "--", ...names], workspace, config, undefined, { signal });
	const diff = (
		await runArgv(["git", "diff", "--cached", "--no-ext-diff", "--binary", "HEAD"], workspace, config, undefined, {
			signal,
			maxOutputBytes: config.implementation.maxDiffBytes + 1,
		})
	).stdout;
	if (
		names.length > config.implementation.maxFiles ||
		diff.split("\n").length > config.implementation.maxDiffLines ||
		Buffer.byteLength(diff) > config.implementation.maxDiffBytes
	)
		throw Object.assign(new Error("Diff limits exceeded"), { code: "DIFF_LIMIT" });
	if (scanSecrets(diff).length) throw Object.assign(new Error("Potential secret in diff"), { code: "SECRET_DETECTED" });
	const tree = (await runArgv(["git", "write-tree"], workspace, config, undefined, { signal })).stdout.trim();
	return { diff, names, tree };
}
export async function trustedInstructions(workspace: string) {
	const paths = ["AGENTS.md", "skills/code-review/SKILL.md", "skills/pr-review/SKILL.md"];
	const found: string[] = [];
	for (const path of paths)
		try {
			found.push(`## ${path}\n${await readFile(join(workspace, path), "utf8")}`);
		} catch {}
	return found.join("\n\n");
}
export async function cleanupWorkspace(path: string) {
	await rm(path, { recursive: true, force: true });
}
