# OWASP Cheat Sheet Series — Practical Implementation Guidance

The Cheat Sheet Series gives concise, actionable implementation guidance for specific security topics. Use it when a finding needs a concrete fix pattern, not just a standard reference. Each cheat sheet is indexed to ASVS sections so requirements map to implementation.

## Index by topic (most useful for audits)

### Authentication & passwords
- **Authentication Cheat Sheet** — general auth architecture, session vs token, step-up auth.
- **Password Storage Cheat Sheet** — use bcrypt/argon2/scrypt; work factors; pepper vs salt; never MD5/SHA1.
- **Credential Stuffing Prevention Cheat Sheet** — rate limiting, MFA, breach-password checks, CAPTCHA considerations.

### Tokens & sessions
- **JSON Web Token Cheat Sheet** — when to use JWT, enforce an explicit algorithm allow-list (reject `alg: none` and unexpected algorithms), prefer asymmetric signing (RS256/ES256) when tokens are verified by multiple services, use short expiry + refresh, validate claims (`exp`, `iss`, `aud`), store in HttpOnly cookies (not localStorage), and rotate keys.
- **Session Management Cheat Sheet** — session ID generation, rotation on auth, idle/absolute timeout, invalidation, secure cookie flags.

### Injection prevention
- **Injection Prevention Cheat Sheet** — parameterized queries, ORM safe usage, allow-list input validation, escaping by context.
- **SQL Injection Prevention Cheat Sheet** — prepared statements, stored procedures done safely, escaping as last resort.
- **Query Parameterization Cheat Sheet** — language/framework examples.
- **OS Command Injection Cheat Sheet** — avoid shell with user input, use argument arrays, built-in safe APIs.

### XSS & output encoding
- **Cross-Site Scripting Prevention Cheat Sheet** — contextual output encoding, auto-escaping templates, CSP, `dangerouslySetInnerHTML`/`v-html` avoidance.
- **DOM-based XSS Prevention Cheat Sheet** — safe sinks, `textContent` over `innerHTML`, sanitization with DOMPurify.
- **XSS Filter Evasion Cheat Sheet** — know the bypasses to test defenses.

### CSRF & request forgery
- **Cross-Site Request Forgery Prevention Cheat Sheet** — token-based, SameSite cookie, double-submit, origin/header checks. Modern default: SameSite=Lax/Strict + origin validation.
- **Server-Side Request Forgery Prevention Cheat Sheet** — URL allow-lists, block internal IP ranges, disable HTTP redirects, do not return raw responses.

### File handling
- **File Upload Cheat Sheet** — validate extension/MIME/content (magic bytes), rename on store, store outside web root, serve via proxy with `Content-Disposition`, scan for malware, size limits, disable script execution in upload dir.
- **File Storage Cheat Sheet** — encryption at rest, access control, metadata handling.

### Data protection & crypto
- **Cryptographic Storage Cheat Sheet** — encryption at rest, key management, algorithm choice.
- **Key Management Cheat Sheet** — generation, storage, rotation, separation of duties.
- **Transport Layer Protection Cheat Sheet** — TLS config, HSTS, certificate pinning.

### Access control
- **Authorization Cheat Sheet** — deny by default, object-level checks, centralized authz, role/attribute models.
- **Insecure Direct Object Reference Prevention Cheat Sheet** — indirect references, per-user mapping, ownership checks.
- **Transaction Authorization Cheat Sheet** — step-up auth for high-value flows.

### Configuration & infrastructure
- **Clickjacking Defense Cheat Sheet** — `X-Frame-Options`, CSP `frame-ancestors`.
- **Content Security Policy Cheat Sheet** — strict CSP, nonce-based, reporting.
- **HTTP Strict Transport Security Cheat Sheet** — HSTS preload, includeSubDomains.
- **XML External Entity Prevention Cheat Sheet** — disable DTD, external entities.
- **Deserialization Cheat Sheet** — avoid untrusted deserialization, integrity checks, allow-list types.

### Architecture & process
- **Threat Modeling Cheat Sheet** — STRIDE, data flow, trust boundaries.
- **Attack Surface Analysis Cheat Sheet** — reduce exposure, inventory endpoints.
- **Abuse Case Cheat Sheet** — think like an attacker in requirements.
- **Third-Party JavaScript Management Cheat Sheet** — SRI, subresource integrity, vendor review.
- **Dependency Graph & SBOM Best Practices Cheat Sheet** — SBOM generation, transitive dep visibility.

## How to use during an audit

1. When a finding maps to a topic, cite the specific cheat sheet in the recommendation, e.g. *"Fix: follow the OWASP File Upload Cheat Sheet — validate magic bytes and store outside web root."*
2. The cheat sheets are **indexed by ASVS section** (https://cheatsheetseries.owasp.org/IndexASVS.html) — use this to go from an ASVS requirement ID to the matching implementation guidance.
3. Prefer the cheat sheet's concrete pattern over a vague recommendation. A finding that says "fix your JWT handling" is weak; one that says "enforce an explicit JWT algorithm allow-list, use asymmetric signing when multi-service verification is required, set short expiries with refresh tokens, and store tokens in HttpOnly cookies per the JWT Cheat Sheet" is actionable.

## References
- Cheat Sheet Series home — https://cheatsheetseries.owasp.org/
- ASVS-indexed cheat sheets — https://cheatsheetseries.owasp.org/IndexASVS.html
- GitHub repo — https://github.com/OWASP/CheatSheetSeries
