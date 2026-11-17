# OWASP ASVS — Application Security Verification Standard

ASVS defines **what to verify** in an application to demonstrate real security assurance. Unlike the Top 10 (which lists risks), ASVS gives concrete, testable security requirements. Use it to build security requirements, verification checklists, and acceptance criteria.

## Current version: ASVS 5.0.0 (May 2025)

- ~350 requirements across **17 chapters**.
- Each requirement has a stable ID: `v<version>-<chapter>.<section>.<requirement>`, e.g. `v5.0.0-6.2.3`.
- Always include the version prefix when citing (`v5.0.0-...`) so the reference stays traceable across releases.

## The 17 chapters (v5.0)

| Ch | Focus |
| --- | --- |
| V1 | Encoding and Sanitization (injection prevention, safe deserialization, memory) |
| V2 | Validation and Business Logic (input validation, anti-automation) |
| V3 | Web Frontend Security (cookies, browser security headers, CSP, origin separation) |
| V4 | API and Web Service (HTTP structure validation, GraphQL, WebSocket) |
| V5 | File Handling (upload, storage, download) |
| V6 | Authentication (password security, MFA, recovery, identity providers) |
| V7 | Session Management (timeouts, termination, session abuse defenses) |
| V8 | Authorization (object/function level, privilege escalation) |
| V9 | Self-contained Tokens (JWT/source integrity, token content) |
| V10 | OAuth and OIDC (clients, resource/auth servers, consent) |
| V11 | Cryptography (algorithms, hashing, random values, key management) |
| V12 | Secure Communication (TLS, service-to-service) |
| V13 | Configuration (backend comm, secret management, info leakage) |
| V14 | Data Protection (at rest, in transit, client-side) |
| V15 | Secure Coding and Architecture (dependencies, defensive coding, concurrency) |
| V16 | Security Logging and Error Handling (security events, log protection) |
| V17 | WebRTC |

## Three verification levels

| Level | Purpose | Effort | Use case |
| --- | --- | --- | --- |
| L1 | Basic — minimum baseline, automatable | Dynamic/SAST, lightweight review | Marketing sites, internal tools, prototypes |
| L2 | Standard — recommended default for apps with sensitive data | Automated + manual, code + docs review | Fintech, healthcare, SaaS with user data |
| L3 | Advanced — highest assurance | Formal design review, threat modeling, deep manual testing | Banking, identity providers, gov/regulated systems |

Each level is a **superset** of the previous: L3 implies full L1+L2 coverage.

## How to use during an audit

1. **Pick a level** based on the app's risk profile. Default to L2 for anything handling user data.
2. **Derive requirements**: for each finding, identify the ASVS requirement(s) it violates and cite the ID (e.g. `v5.0.0-8.3.1` for a missing object-level authorization check).
3. **Build a checklist**: when asked for security requirements or acceptance criteria, pull the relevant chapter's requirements and tailor to the app's architecture (skip chapters that don't apply, e.g. V17 WebRTC for a pure API).
4. **Documented vs Implementation**: ASVS 5.0 separates *Documented Security Decisions* (architectural intent) from *Implementation Requirements* (testable behavior). Flag missing documentation as well as missing controls.
5. **Map to Top 10**: each ASVS chapter maps to OWASP Top 10 categories — use the ASVS index of Cheat Sheets (`reference/owasp-cheat-sheets.md`) to find implementation guidance per requirement.

## ASVS vs other frameworks
- **ASVS** = what to verify (requirements for the app).
- **OWASP SAMM** = how mature your security process is.
- **Top 10** = what the broad risks are (awareness).
- ASVS is the actionable, testable layer between awareness (Top 10) and process maturity (SAMM).

## References
- Project page — https://owasp.org/www-project-application-security-verification-standard/
- ASVS 5.0.0 (GitHub) — https://github.com/OWASP/ASVS/tree/v5.0.0
- Cheat Sheets indexed by ASVS section — https://cheatsheetseries.owasp.org/IndexASVS.html
