# DevSecOps — Integrating Security into CI/CD

DevSecOps shifts security left: automated scanning in the pipeline catches vulnerabilities before production, with fast developer feedback and security gates that block rather than just warn. Use this reference when auditing CI/CD workflows, GitHub Actions, GitLab CI, Dockerfiles, or IaC.

## The pipeline security flow

```text
Code Push
  ├─ Secret scanning (pre-commit) ─┐
  ├─ SAST (source) ────────────────┤
  ├─ Dependency scanning (SCA) ────┤
                                  Build
                                   ├─ Container scanning ──┐
                                   ├─ IaC scanning ────────┤
                                                          Deploy to staging
                                                           └─ DAST (running app) → gate → prod
```

Run fast feedback (secrets, SAST, deps) on every PR; slower/deeper scans (full DAST, nightly audit) on schedule or main.

## Scanning categories & tools

### 1. Dependency scanning (SCA — Software Composition Analysis)
Identifies known CVEs in third-party dependencies by comparing versions against vulnerability databases (NVD, OSV, GitHub Advisory DB).

| Tool | Fit |
| --- | --- |
| `npm audit` | Built-in; baseline for Node. `--audit-level=high` to gate. |
| GitHub Dependabot | Native PR alerts + auto-upgrade PRs. Configure `dependabot.yml`. |
| Snyk | Deep CVE DB, reachability, auto-fix PRs, container + IaC too. |
| Trivy (`trivy fs`) | OSS; filesystem/lockfile scan; fast. |
| OWASP Dependency-Check | OSS; multi-ecosystem. |
| Socket.dev | Static analysis of package *behavior* (network/fs access) — catches malware, not just CVEs. |

Gate on high/critical; require lockfiles for accurate transitive resolution.

### 2. Secret detection
Scans code, git history, and config for leaked credentials (API keys, tokens, private keys).

| Tool | Fit |
| --- | --- |
| Gitleaks | OSS, fast, Go binary. Best as a **pre-commit hook** (sub-second). SARIF output for GitHub. |
| TruffleHog | OSS; **verifies** whether detected secrets are still active. Best in **CI/CD** for triaged, verified findings. Scans Docker images, S3. |
| GitHub secret scanning + push protection | Native; blocks secrets before commit (Enterprise). |
| GitGuardian | Enterprise; broad coverage + remediation workflow. |

Recommended pattern: **Gitleaks pre-commit** (speed) + **TruffleHog in CI** (verified depth). Custom rules for internal token formats; entropy detection for unknown patterns.

### 3. SAST (Static Application Security Testing)
Analyzes source code for vulnerability patterns without running it.

| Tool | Fit |
| --- | --- |
| Semgrep | OSS; pattern-based, fast, custom rules, low false positives. Multi-language. |
| GitHub CodeQL | OSS for OSS repos; semantic dataflow analysis; deep. |
| SonarQube | Quality + security gates; CI integration. |
| Snyk Code | SAST with reachability + fix suggestions. |
| Checkmarx / Veracode | Enterprise; deep taint analysis. |

SAST catches injection, hardcoded secrets, weak crypto, missing validation. Pattern-based tools (Semgrep) miss complex interprocedural dataflow — supplement with CodeQL or a commercial tool for complex apps. Tune to reduce false positives or developers ignore findings.

### 4. DAST (Dynamic Application Security Testing)
Tests a **running** application by sending real HTTP requests — finds runtime issues SAST misses (auth bypass, reflected XSS, misconfigured headers).

| Tool | Fit |
| --- | --- |
| OWASP ZAP | OSS; the standard. Active/passive scan; API scan via OpenAPI; authenticated scans. |
| GitLab DAST | ZAP-based; integrated template. |
| Nuclei | OSS; template-based, fast, community templates. |

Run DAST against staging/review apps post-deploy. **Authenticated DAST** (provide login flow) finds far more than unauthenticated. Point at an ephemeral review app per PR for shift-left DAST.

### 5. Container scanning
Scans Docker images for OS-level CVEs (base image packages) and app-level vulnerabilities.

| Tool | Fit |
| --- | --- |
| Trivy (`trivy image`) | OSS; the standard. Fast; vuln + secret + misconfig. |
| Grype | OSS; fast SBOM-based vuln matching. |
| Snyk Container | Deep DB + fix PRs. |
| Aqua / Black Duck | Enterprise. |

The biggest lever is often the **base image**: switch `ubuntu:22.04` → `gcr.io/distroless/base` or `debian:bookworm-slim` to remove hundreds of unused-package CVEs. Rebuild regularly to pick up upstream patches. Run as non-root, read-only FS, dropped capabilities.

### 6. IaC scanning
Scans Terraform, CloudFormation, K8s manifests, Helm charts for misconfigurations.

| Tool | Fit |
| --- | --- |
| Checkov | OSS; broad IaC + cloud misconfig. |
| tfsec / Trivy IaC | OSS; Terraform-focused. |
| KICS | OSS; multi-IaC. |
| OPA / Gatekeeper | Policy-as-code; admission control in K8s. |

## CI/CD security gates (audit checklist)

- [ ] **Pre-commit**: Gitleaks hook blocks secrets locally before push
- [ ] **PR pipeline**: SAST (Semgrep/CodeQL) + dependency scan + secret scan run on every PR
- [ ] **Build**: image built, then container scan (Trivy) gates on high/critical
- [ ] **IaC**: Checkov/tfsec runs on infra PRs
- [ ] **Deploy to staging**: ephemeral review app; DAST (ZAP authenticated) runs post-deploy
- [ ] **Gate policy**: new critical/high findings block merge; pre-existing findings tracked, not blocking
- [ ] **SBOM**: CycloneDX/SPDX generated and stored per release for supply-chain traceability
- [ ] **Least privilege**: CI runner tokens scoped; deploy keys per-repo; no broad PATs; secrets in OIDC/Vault not env vars in logs
- [ ] **Scheduled deep scan**: nightly full SAST + full dependency + container scan on main
- [ ] **Findings routed**: SARIF uploaded to GitHub Security tab or a dashboard; auto-ticketed; owners assigned

## GitHub Actions example (Node.js)

```yaml
# .github/workflows/security.yml
name: Security
on: [pull_request]
jobs:
  secrets:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262
        with: { fetch-depth: 0 }
      - uses: gitleaks/gitleaks-action@ff98106e4c7b2bc287b24eaf42907196329070c7
  sast:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262
      - uses: returntocorp/semgrep-action@713efdd345f3035192eaa63f56867b88e63e4e5d
  deps:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262
      - uses: actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020
        with: { node-version: "24" }
      - run: npm ci --ignore-scripts
      - run: npm audit --audit-level=high
  container:
    runs-on: ubuntu-latest
    steps:
      - uses: aquasecurity/trivy-action@2736533278103862a861f4a35ebac3e97854d956
        with:
          image-ref: node:24-alpine
          severity: HIGH,CRITICAL
          exit-code: "1"
```

## Hardening the pipeline itself
- Pin actions to a commit SHA, not a floating tag (`@v4` can be hijacked).
- Use OIDC for cloud deploys instead of long-lived secrets.
- Restrict `pull_request_target` usage (it runs with secrets — dangerous with untrusted PRs).
- Limit `GITHUB_TOKEN` permissions to read-only by default; escalate per-job.
- Audit third-party actions for network calls and credential access.

## References
- OWASP DevSecOps Guideline — https://owasp.org/www-project-devsecops-guideline/
- OWASP DevSecOps Maturity Model — https://dsomm.owasp.org/
- Trivy — https://github.com/aquasecurity/trivy
- Semgrep — https://semgrep.dev/
- Gitleaks — https://github.com/gitleaks/gitleaks
- TruffleHog — https://github.com/trufflesecurity/trufflehog
- OWASP ZAP — https://www.zaproxy.org/
- GitHub Security hardening — https://docs.github.com/en/actions/security-guides
