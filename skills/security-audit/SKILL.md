---
name: security-audit
description: "Use when reviewing code for security vulnerabilities, hardening an application, or deriving security requirements from OWASP/ASVS guidance."
license: MIT
compatibility: cline, claude, opencode, amp, codex, gemini, cursor, pi
hint: Use when auditing code for security vulnerabilities or hardening an application
user-invocable: true
metadata:
  audience: all
  workflow: security
---

# Security Audit

Perform a structured security audit of code, configuration, and architecture. Identify vulnerabilities, rank them by severity, and recommend concrete fixes grounded in OWASP standards, framework-specific best practices, and DevSecOps controls.

This is a **read-only analysis**. Do not modify code — audit, then report.

## Usage

```bash
/security-audit [scope]
```

- With no argument, audit the current branch's diff against the default branch.
- With a path or module name, audit that scope.
- Use `full` to audit the whole repository for systemic issues.

## Knowledge Base

The audit draws on five reference areas. Load the relevant reference file when a finding needs grounding or when you need detailed requirements for a topic:

| Area | Reference | When to load |
| --- | --- | --- |
| OWASP Top 10 | `reference/owasp-top-10.md` | Classifying a finding against the major vulnerability categories (2021 + 2025) |
| OWASP ASVS | `reference/owasp-asvs.md` | Deriving concrete security requirements or building a verification checklist |
| OWASP Cheat Sheet Series | `reference/owasp-cheat-sheets.md` | Needing practical implementation guidance (auth, JWT, file upload, CSRF, password storage) |
| Node.js Security | `reference/nodejs-security.md` | Auditing Express, NestJS, Fastify, or Node.js dependency/supply-chain issues |
| DevSecOps | `reference/devsecops.md` | Reviewing CI/CD pipeline security, dependency/container/secret/SAST/DAST scanning |

Use progressive disclosure: keep the reference files unloaded until a finding maps to them. Load only the file the current finding needs.

## Audit Process

### 1. Scope and gather context

```bash
# Detect the default branch
BASE_BRANCH=$(git remote show origin 2>/dev/null | grep 'HEAD branch' | awk '{print $NF}' || echo main)

# Diff under audit
git diff "$BASE_BRANCH"...HEAD --stat
git diff "$BASE_BRANCH"...HEAD

# Dependency surface
cat package.json 2>/dev/null | jq '.dependencies, .devDependencies'
npm audit --json 2>/dev/null | jq '.metadata.vulnerabilities' 2>/dev/null

# Configuration surface
find . -maxdepth 2 \( -name '*.yml' -o -name '*.yaml' -o -name 'Dockerfile*' -o -name '.env*' \) -not -path './node_modules/*'
```

For a full audit, also enumerate: auth/session code, input handlers, file upload paths, database query construction, crypto usage, CI/CD workflow files, and container definitions.

Completion criteria:
- Default branch and diff under audit are identified.
- Dependency and configuration surfaces are enumerated for the selected scope.
- For `full` audits, the additional security-critical code paths are listed.

### 2. Run the checklist

Walk every changed or in-scope file against this checklist. Each item maps to an OWASP Top 10 category — use `reference/owasp-top-10.md` for the full category definitions and examples.

#### Input validation & injection (A03:2021 Injection, A05:2025 Injection; A02:2021 Cryptographic Failures, A04:2025 Cryptographic Failures)
- [ ] All external input (body, query, params, headers, cookies) is validated with an allow-list schema (zod, joi, ajv, class-validator)
- [ ] SQL/NoSQL queries use parameterized queries or ORM builders — no string concatenation
- [ ] OS command execution avoids `exec`/`spawn` with user input; uses argument arrays
- [ ] Output encoding is applied contextually (HTML, JS, URL, CSS) to prevent XSS
- [ ] Template engines use auto-escaping; `dangerouslySetInnerHTML`/`v-html`/`|raw` justified and sanitized
- [ ] Path traversal prevented — user input never reaches file path construction unsanitized
- [ ] SSRF prevented — outbound URLs validated against an allow-list, internal IPs blocked

#### Authentication & session (A07:2021 Identification and Authentication Failures, A07:2025 Authentication Failures)
- [ ] Passwords hashed with bcrypt/argon2/scrypt — never MD5/SHA1/plain text
- [ ] MFA available; credential recovery does not leak account existence
- [ ] Session IDs are high-entropy, rotated on login, invalidated on logout
- [ ] JWTs (if used) verified for signature, expiry, audience; secrets strong and rotated — see `reference/owasp-cheat-sheets.md`
- [ ] Brute-force protection (rate limiting, lockout) on auth endpoints
- [ ] No default or weak credentials

#### Authorization & access control (A01:2021 Broken Access Control, A01:2025 Broken Access Control)
- [ ] Deny by default; explicit allow on every protected resource
- [ ] Object-level (IDOR) checks — user cannot access other users' records by ID
- [ ] Role checks at the right layer (middleware/guard), not scattered in handlers
- [ ] No privilege escalation paths; admin functions gated
- [ ] CORS configured with an explicit origin allow-list — never `*` with credentials

#### Data protection & cryptography (A02:2021 Cryptographic Failures, A04:2025 Cryptographic Failures; A08:2021/2025 Software and Data Integrity Failures)
- [ ] TLS enforced everywhere; HSTS enabled; weak ciphers disabled
- [ ] Sensitive data encrypted at rest; secrets in a vault/env, never committed
- [ ] No sensitive data in logs, error messages, or URLs
- [ ] Strong algorithms only (AES-GCM, ChaCha20); no deprecated crypto (DES, RC4, ECB)
- [ ] Random values use `crypto.randomUUID()`/`crypto.randomBytes()` — never `Math.random()` for security
- [ ] Deserialization of untrusted data avoided or integrity-checked

#### Configuration & dependencies (A05:2021 Security Misconfiguration, A02:2025 Security Misconfiguration; A06:2021 Vulnerable and Outdated Components, A03:2025 Software Supply Chain Failures; A04:2021/A06:2025 Insecure Design)
- [ ] No hardcoded secrets, tokens, or API keys — see `reference/devsecops.md` for secret scanning
- [ ] Debug/verbose error pages disabled in production; stack traces not exposed
- [ ] Security headers present (CSP, HSTS, X-Frame-Options, X-Content-Type-Options) — helmet/ equivalents
- [ ] Dependencies pinned and audited; no known high/critical CVEs
- [ ] `npm ci` used in CI; lockfile committed; `--ignore-scripts` considered
- [ ] File uploads validated (type, size, content); stored outside web root — see `reference/owasp-cheat-sheets.md`
- [ ] Rate limiting on API and auth endpoints

#### Logging & error handling (A09:2021 Security Logging and Monitoring Failures, A09:2025 Security Logging and Alerting Failures; A10:2025 Mishandling of Exceptional Conditions)
- [ ] Security events logged (auth failures, access denials, input validation failures)
- [ ] Logs do not contain passwords, tokens, or PII
- [ ] Errors fail closed (deny) not open (allow) on unexpected conditions
- [ ] Generic error messages to users; details server-side only
- [ ] NULL/missing-parameter paths handled, not crashing or leaking info

Completion criteria:
- Every changed or in-scope file is checked against all relevant checklist sections.
- Each unchecked item is either confirmed not applicable or recorded as a finding.

### 3. Framework-specific checks

For Node.js projects, load `reference/nodejs-security.md` and check framework-specific concerns:

- **Express**: `helmet()`, `express-rate-limit`, `cors` allow-list, no `X-Powered-By`, body size limits, prototype pollution defenses
- **NestJS**: `ValidationPipe` with `whitelist` + `forbidNonWhitelisted`, `ClassSerializerInterceptor` to strip sensitive fields, Guards for authz, `helmet` middleware, throttler
- **Fastify**: `@fastify/helmet`, `@fastify/rate-limit`, `@fastify/cors` with origin allow-list, schema validation on routes, `@fastify/under-pressure`
- **All**: dependency pinning, `npm audit`/Snyk/Socket, non-root container user, event-loop blocking (ReDoS, sync APIs), prototype pollution

Completion criteria:
- The active framework stack is identified.
- Matching framework checks are reviewed and any gaps are captured as findings.

### 4. Pipeline & deployment checks

When the scope includes CI/CD or deployment, load `reference/devsecops.md` and verify:

- [ ] Dependency scanning (npm audit / Snyk / Dependabot / Trivy) runs in CI and gates on high/critical
- [ ] Secret scanning (Gitleaks pre-commit, TruffleHog in CI) prevents leaked credentials
- [ ] Container scanning (Trivy / Grype) on built images; base image minimal (distroless/slim)
- [ ] SAST (Semgrep / CodeQL) runs on PRs; results triaged
- [ ] DAST (OWASP ZAP) against staging on deploys
- [ ] IaC scanning (Checkov / tfsec) on Terraform/K8s manifests
- [ ] Least privilege: non-root container, read-only FS, dropped capabilities
- [ ] SBOM generated (CycloneDX / SPDX) for supply-chain traceability

Completion criteria:
- CI/CD and deployment controls in scope are reviewed against this checklist.
- Missing controls are documented with severity and remediation guidance.

### 5. Rank findings and report

#### Severity

| Level | Criteria | Examples |
| --- | --- | --- |
| 🔴 Critical | Immediate, exploitable risk | SQL injection, RCE, exposed secrets, broken auth |
| 🟠 High | Significant concern, likely exploitable | auth bypass, IDOR, missing authz on sensitive data |
| 🟡 Medium | Potential vulnerability | missing validation, weak crypto, verbose errors |
| 🟢 Low | Defense-in-depth improvement | missing security header, better logging |
| ℹ️ Info | Awareness note | version end-of-life, future hardening |

#### Output format

```markdown
## Executive Summary

- Overall posture: Secure / Needs attention / Critical issues
- N findings: 🔴 x  🟠 x  🟡 x  🟢 x  ℹ️ x
- Top recommendations (ordered by impact)

## Findings

### [Severity] Title
- **OWASP**: A03:2021-Injection (and A05:2025 if reclassified)
- **Location**: `src/api/upload.ts:42`
- **Issue**: One-line description
- **Impact**: What an attacker can do
- **Recommendation**: Concrete fix with code snippet or config change
- **Reference**: OWASP Cheat Sheet — File Upload; ASVS v5.0.0-5.2.1

## Positive Practices

- Well-implemented controls worth keeping
```

Cite the relevant OWASP category, ASVS requirement ID (e.g. `v5.0.0-6.2.3`), and Cheat Sheet in each finding so the recommendation is traceable to a standard.

Completion criteria:
- Every finding has severity, location, impact, recommendation, and standard references.
- Executive summary totals match the findings list.

## Guidelines

- **Be concrete**: every finding needs a fix the developer can act on, not just a description of the problem.
- **Map to standards**: cite the OWASP Top 10 category and, where relevant, the ASVS requirement ID and Cheat Sheet. This makes findings auditable and educational.
- **Verify, don't assume**: read the actual code before flagging. A pattern that looks vulnerable may be mitigated elsewhere — confirm the mitigation is missing before reporting.
- **Prioritize by exploitability**: a Critical finding that requires no auth and is internet-reachable outranks a theoretical issue behind admin auth.
- **Stay read-only**: never modify code during an audit. Use inspection-only commands (`git diff`, `npm audit`, `cat`, `grep`). If your environment provides an `execute()` wrapper, prefer it for read-only command execution.
- **Note the version**: when citing OWASP Top 10, state whether you are using the 2021 or 2025 edition — they differ (see `reference/owasp-top-10.md`).
