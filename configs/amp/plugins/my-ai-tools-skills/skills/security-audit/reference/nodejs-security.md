# Node.js Security Best Practices

Framework-specific security guidance for Node.js applications (Express, NestJS, Fastify) and dependency/supply-chain management. Node.js ships with **no security defaults** — every protection must be added explicitly.

## Universal Node.js concerns

### Event loop & DoS
- **ReDoS**: the single-threaded event loop means one slow regex stalls every request. Audit regexes for catastrophic backtracking; use `safe-regex`/`re2`; bound input length.
- **Blocking the loop**: avoid sync APIs (`fs.readFileSync`, `crypto.pbkdf2Sync`, `zlib.inflateSync`) in request paths. Offload CPU-bound work to worker threads.
- **HTTP server timeouts**: set `headersTimeout`, `requestTimeout`, `keepAliveTimeout`; limit `maxSockets`. Use a reverse proxy (nginx, CDN) for load balancing and IP throttling.
- **Request body size limits**: configure `express.json({ limit: '100kb' })` / Fastify `bodyLimit` to prevent memory-exhaustion DoS.

### Prototype pollution
- Never `Object.assign`/`merge`/`extend` user-controlled JSON onto objects. `JSON.parse('{"__proto__":{"polluted":true}}')` followed by a merge pollutes prototypes.
- Use `Object.create(null)` for lookup objects; strip `__proto__`, `constructor`, `prototype` keys; validate with zod/joi `stripUnknown`.
- Audit `deepmerge`, `lodash.set`, `lodash.merge` versions for known prototype-pollution CVEs.

### Unsafe APIs
- Avoid `eval`, `Function()`, `vm.runInNewContext` with any user input.
- `child_process.exec` shells the command — use `execFile`/`spawn` with argument arrays, never interpolated user input.
- `path.join`/`path.resolve` with user input enables traversal — normalize and verify the result stays within an allowed root.

### Cryptography
- Passwords: `bcrypt`, `argon2`, or `scrypt` — never `crypto.createHash('md5'|'sha1')`.
- Random: `crypto.randomUUID()`, `crypto.randomBytes()` — never `Math.random()` for tokens, IDs, or secrets.
- Secrets/keys: load from env or a vault; never hardcode. Use `crypto.timingSafeEqual` for constant-time comparisons (e.g. HMAC verification).

### Error handling
- Centralized error middleware; never leak stack traces or internal messages to clients.
- Fail **closed** (deny) on unexpected errors in authz middleware, not open (allow).
- Use `try/catch` around `await`; unhandled rejections crash the process (or silently drop in newer Node — handle them).

## Express

```js
const express = require("express");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");
const cors = require("cors");

const app = express();
app.use(helmet());                          // security headers: CSP, HSTS, X-Frame-Options, etc.
app.disable("x-powered-by");                // reduce fingerprinting
app.use(express.json({ limit: "100kb" }));  // body size limit

// CORS allow-list — never origin: '*' with credentials
app.use(cors({
  origin: ["https://app.example.com"],
  credentials: true,
  methods: ["GET", "POST", "PUT", "PATCH", "DELETE"],
}));

// Global rate limit
app.use(rateLimit({ windowMs: 15 * 60 * 1000, max: 100, standardHeaders: true, legacyHeaders: false }));

// Strict limit on auth
app.use("/api/auth", rateLimit({ windowMs: 15 * 60 * 1000, max: 10, skipSuccessfulRequests: true }));
```

Audit checklist (Express):
- [ ] `helmet()` applied early
- [ ] `express-rate-limit` global + stricter on `/auth`, `/password-reset`
- [ ] `cors` with explicit origin array (never `*` + `credentials: true`)
- [ ] Body size limits (`limit` on `express.json`/`urlencoded`)
- [ ] Cookie security: `httpOnly`, `secure`, `sameSite` flags; no default session name
- [ ] Input validation via `express-validator`/`zod` at every route
- [ ] Parameterized DB queries (Knex/Sequelize/Prisma) — no raw string SQL
- [ ] Custom 404 and error handlers replacing Express defaults

## NestJS

```ts
// main.ts
import { NestFactory } from "@nestjs/core";
import helmet from "helmet";
import { ValidationPipe } from "@nestjs/common";

const app = await NestFactory.create(AppModule);
app.use(helmet());
app.useGlobalPipes(new ValidationPipe({
  whitelist: true,            // strip non-DTO properties
  forbidNonWhitelisted: true, // reject unknown properties
  transform: true,
}));
app.enableCors({ origin: ["https://app.example.com"], credentials: true });
app.use((req, res, next) => { /* rate limit via @nestjs/throttler instead */ next(); });
await app.listen(3000);
```

Audit checklist (NestJS):
- [ ] `ValidationPipe` with `whitelist` + `forbidNonWhitelisted` globally
- [ ] `@UseGuards(AuthGuard)` on protected routes; `@Roles()` + `RolesGuard` for authz
- [ ] `ClassSerializerInterceptor` to strip `@Exclude()`-d sensitive fields from responses
- [ ] `@nestjs/throttler` for rate limiting
- [ ] `helmet` middleware; CORS with allow-list
- [ ] No secrets in config files committed to repo — use `@nestjs/config` with env validation
- [ ] DTOs on every input boundary; no raw `req.body` access

## Fastify

```ts
import Fastify from "fastify";
import helmet from "@fastify/helmet";
import rateLimit from "@fastify/rate-limit";
import cors from "@fastify/cors";

const app = Fastify({ logger: true, bodyLimit: 100_000 });
await app.register(helmet);
await app.register(rateLimit, { max: 100, timeWindow: "15 minutes" });
await app.register(cors, {
  origin: ["https://app.example.com"],
  credentials: true,
});

// Schema validation built into route declarations
app.post("/users", {
  schema: {
    body: {
      type: "object",
      required: ["email", "password"],
      properties: {
        email: { type: "string", format: "email" },
        password: { type: "string", minLength: 12 },
      },
      additionalProperties: false,
    },
  },
  handler: async (req, reply) => { /* ... */ },
});
```

Audit checklist (Fastify):
- [ ] `@fastify/helmet`, `@fastify/rate-limit`, `@fastify/cors` with origin allow-list
- [ ] JSON schema validation on every route (`body`, `querystring`, `params`, `headers`) with `additionalProperties: false`
- [ ] `bodyLimit` set to a sane cap
- [ ] `@fastify/under-pressure` for event-loop/memory pressure shedding
- [ ] `@fastify/cookie` with `secure`/`httpOnly`/`sameSite` for session cookies
- [ ] No `reply.send(user)` leaking sensitive fields — use serialization schemas

## Dependency & supply-chain management

- **Pin versions**: exact versions in `package.json` (not `^`/`~`); commit the lockfile (`package-lock.json`/`pnpm-lock.yaml`).
- **CI install**: `npm ci` (fails on lockfile drift) instead of `npm install`.
- **Audit**: `npm audit --audit-level=high` in CI; `npx snyk test` or Socket.dev for deeper analysis.
- **Scripts**: disable install scripts with `npm config set ignore-scripts true` / `--ignore-scripts` to block malicious postinstall.
- **Lockfile poisoning**: verify lockfile integrity; don't accept unreviewed lockfile changes in PRs.
- **Typosquatting**: verify package names exactly; prefer scoped packages; review new dependencies.
- **EOL runtimes**: stay on an active LTS line and verify support status against the official Node.js release schedule: https://nodejs.org/en/about/previous-releases. Running EOL means unpatched CVEs.
- **Reachability**: a CVE in a transitive dep is only critical if the vulnerable code path is reachable — use `npm audit` + Snyk/Socket reachability or `vet` to prioritize.
- **Non-root container**: run the Node process as a non-root user; read-only FS where possible; drop Linux capabilities.
- **Node.js permission model**: `--permission` flag restricts fs/net/child-process access — useful to contain compromised deps (still experimental; one layer among several).

## References
- Node.js security best practices — https://nodejs.org/learn/getting-started/security-best-practices
- Node.js threat model — https://github.com/nodejs/node/security/policy
- Express production security — https://expressjs.com/en/advanced/best-practice-security.html
- Node.js Best Practices repo — https://github.com/goldbergyoni/nodebestpractices
- Helmet — https://helmetjs.github.io/
- Snyk Node.js guide — https://snyk.io/articles/nodejs-security-best-practice/
