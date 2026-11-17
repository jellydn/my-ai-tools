# OWASP Top 10 — Vulnerability Categories

The OWASP Top 10 is the standard awareness document for the most critical web application security risks. Two editions are in active use: **2021** (widely referenced in tooling and compliance) and **2025** (the latest release). Cite which edition you are mapping to.

## OWASP Top 10:2025 (latest)

| ID | Category | Focus |
| --- | --- | --- |
| A01:2025 | Broken Access Control | Still #1. Authorization failures, IDOR, privilege escalation. |
| A02:2025 | Security Misconfiguration | Moved up. Configuration errors, default creds, verbose errors, IaC misconfig. |
| A03:2025 | Software Supply Chain Failures | **New #3.** Expands beyond dependencies to build tools, pipelines, containers, package registries. |
| A04:2025 | Cryptographic Failures | Weak/broken crypto, plaintext transport, key management. |
| A05:2025 | Injection | SQLi, NoSQLi, XSS (now folded in), command injection, LDAP injection. |
| A06:2025 | Insecure Design | Missing threat modeling, no abuse cases, design-level flaws. |
| A07:2025 | Authentication Failures | Credential stuffing, weak recovery, session management, MFA gaps. |
| A08:2025 | Software or Data Integrity Failures | Unsigned updates, unsafe deserialization, CI/CD integrity. |
| A09:2025 | Security Logging and Alerting Failures | Missing detection, no alerting on security events. |
| A10:2025 | Mishandling of Exceptional Conditions | **New.** Improper error handling, failing open, NULL deref, unhandled edge cases. |

### Key 2021 → 2025 shifts
- **A03** renamed from *Vulnerable and Outdated Components* to *Software Supply Chain Failures* — the supply chain is now treated as part of the application.
- **A10** is brand new: *Mishandling of Exceptional Conditions* (24 CWEs covering fail-open, NULL deref, missing-param handling, sensitive info in errors).
- *Server-Side Request Forgery* (A10:2021) is folded into broader categories in 2025, most commonly **A01:2025 Broken Access Control** when internal resources are reachable because authorization/trust boundaries fail.
- Order shifted: Misconfiguration rose to #2, Injection dropped to #5.

## OWASP Top 10:2021 (still widely referenced)

| ID | Category |
| --- | --- |
| A01:2021 | Broken Access Control |
| A02:2021 | Cryptographic Failures (was "Sensitive Data Exposure") |
| A03:2021 | Injection (XSS folded in) |
| A04:2021 | Insecure Design (new) |
| A05:2021 | Security Misconfiguration (XXE folded in) |
| A06:2021 | Vulnerable and Outdated Components |
| A07:2021 | Identification and Authentication Failures |
| A08:2021 | Software and Data Integrity Failures (new; deserialization folded in) |
| A09:2021 | Security Logging and Monitoring Failures |
| A10:2021 | Server-Side Request Forgery (SSRF) (new) |

## How to use during an audit

1. For each finding, identify the **root cause category**, not just the symptom. OWASP 2021+ intentionally names categories by root cause (e.g. "Cryptographic Failures" not "Sensitive Data Exposure").
2. Map the finding to the CWE(s) under the category when possible — this aids tool correlation and remediation tracking.
3. State the edition: `A03:2021-Injection` vs `A05:2025-Injection` — the numbering changed.
4. Check the 2025 list for findings that fit the new categories (supply chain, exceptional conditions) even if you also reference 2021.

## References
- OWASP Top 10:2025 — https://owasp.org/Top10/2025/
- OWASP Top 10:2021 — https://owasp.org/Top10/2021/
- Main project page — https://owasp.org/www-project-top-ten/
