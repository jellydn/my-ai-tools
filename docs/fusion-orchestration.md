# ⚡ Fusion Orchestration Guide

> **Fusion Mode** is a multi-agent orchestration architecture that separates **judgment and architecture** (Lead) from **mechanical implementation** (Executor) across OpenCode, Amp, Pi, and Codex.

---

## 💡 What is Fusion Orchestration?

When single AI agents work on complex tasks, they frequently mix planning, code editing, and self-verification. This often leads to context rot, premature edits, scope creep, and self-congratulatory claims of success without empirical verification.

**Fusion Mode** solves this by establishing a strict separation of concerns:

- **Fusion Lead (Architect/Planner/Verifier)**: A high-reasoning, read-only agent. It inspects the codebase, resolves architecture choices, defines bounded contracts, delegates tasks, and independently verifies the output.
- **Fusion Executor (Implementation Worker)**: A fast, targeted execution agent. It receives a bounded specification, loads required skills, edits only the specified files, runs unit tests/build checks, and reports results via a structured envelope.

```
                    ┌─────────────────────────┐
                    │       Fusion Lead       │
                    │   (Read-Only Planner)   │
                    └────────────┬────────────┘
                                 │
                   1. Bounded Specification
                                 │
                                 ▼
                    ┌─────────────────────────┐
                    │     Fusion Executor     │
                    │ (Implementation Worker) │
                    └────────────┬────────────┘
                                 │
                     2. Structured Envelope
                                 │
                                 ▼
                    ┌─────────────────────────┐
                    │       Fusion Lead       │
                    │  (Independent Gatekeeper)│
                    └─────────────────────────┘
```

---

## 🎯 When to Use vs. When NOT to Use

| Scenario | Use Fusion Mode? | Rationale |
|----------|-----------------|-----------|
| **Multi-file feature implementation** | ✅ **Yes** | Benefit from separate planning, bounded file edits, and independent verification. |
| **Complex architectural refactoring** | ✅ **Yes** | Prevents broken contracts and broad unguided code mutations. |
| **Tasks needing strict verification** | ✅ **Yes** | Lead independently verifies diffs and test results before acceptance. |
| **Trivial 1-line typo / import fix** | ❌ **No** | Too much overhead. Keep in standard writable session. |
| **Single-file mechanical update** | ❌ **No** | Single agent is faster and more direct. |
| **Exploratory Q&A / Code discovery** | ❌ **No** | Standard read-only session is sufficient. |

---

## 🛠️ Tool-by-Tool Implementations

Native Fusion integration is available across multiple AI coding tools in this repository:

### 1. OpenCode
- **Primary Agent**: `fusion-lead`
- **Behavior**: Read-only primary session (`permission` blocks restrict file writes and shell execution). Delegates implementation to `fusion-executor` via subagents.

### 2. Amp
- **Agent Mode**: `fusion`
- **Behavior**: Exposes `fusion_executor` tool to plugin-authorized lead threads.

### 3. Pi Agent
- **Execution Pattern**: Sibling delegation from the root session.
- **Behavior**: Root session calls `fusion-lead` for specification, then passes the specification to sibling `fusion-executor`. (`pi-subagents` enforces tool allowlists and isolates child sessions).
- *Note:* Pi executor requires skills under project-local directories (e.g. `.agents/skills/...`).

### 4. Codex
- **Execution Pattern**: Sibling delegation.
- **Behavior**: Root session invokes `fusion-lead` for plan and specification, then executes sibling `fusion-executor` with bounded file permissions.

---

## 📋 The Handoff Contract & Envelope Protocol

Communication between Lead and Executor is governed by strict, structured contracts:

### 1. Lead-to-Executor Specification Contract

The Lead produces a spec with exact boundaries:

```text
OBJECTIVE: <Clear goal statement>
FILES: <Exact list of target file paths to create/modify>
INTERFACES: <Public signatures, types, or API contracts to satisfy>
CONSTRAINTS: <Style rules, forbidden modifications, backward-compatibility requirements>
SKILLS: <Exact filesystem paths to relevant SKILL.md files to load>
VERIFICATION: <Specific test suite or build commands to execute>
```

### 2. Executor-to-Lead Return Envelope Contract

Upon completing implementation, the Executor returns a structured summary:

```text
STATUS: SUCCESS | VERIFICATION_FAILED | BLOCKED
EXECUTIVE SUMMARY: <High-level narrative of what was done>
CHANGES: <Summary of modified files and functions>
VERIFIED: <Passed check commands and output summary>
SKILLS LOADED: <List of SKILL.md paths actually read>
RISKS: <Potential edge cases or follow-up items>
QUESTIONS: <Blockers requiring user input>
NEXT RECOMMENDED: <Suggested next steps>
KEY LEARNINGS: <Domain insights discovered during implementation>
```

### 3. Verification & Approval Rules

- **Direct Checks**: Read-only checks and standard unit tests run directly inside the executor when permitted by sandbox policy.
- **Verification Required**: If a check cannot run inside the executor due to permission or lifecycle limits, the executor marks it as `VERIFICATION REQUIRED` with the exact command string.
- **No Self-Proclamation**: Neither Lead nor Executor may mark a task as "Passed" without empirical command output.

---

## 📖 Step-by-Step Walkthrough Example

### Example Workflow: Adding a New Plugin Endpoint

1. **Step 1: Lead Investigation**
   User asks to add a new authentication endpoint. `fusion-lead` inspects `configs/` and existing route definitions.

2. **Step 2: Specification Hand-off**
   `fusion-lead` issues a bounded specification:
   ```text
   OBJECTIVE: Add JWT validation helper in lib/auth.ts
   FILES: lib/auth.ts, tests/auth.test.ts
   INTERFACES: export function validateJwt(token: string): AuthPayload
   CONSTRAINTS: Must use existing jwt-verify library, no extra external deps
   SKILLS: skills/tdd/SKILL.md
   VERIFICATION: bun test tests/auth.test.ts
   ```

3. **Step 3: Executor Implementation**
   `fusion-executor` loads `skills/tdd/SKILL.md`, implements `lib/auth.ts`, writes unit tests in `tests/auth.test.ts`, and runs `bun test tests/auth.test.ts`.

4. **Step 4: Envelope Return & Independent Lead Verification**
   `fusion-executor` returns the `STATUS: SUCCESS` envelope. `fusion-lead` reviews the git diff and test output. If clean, `fusion-lead` accepts the result and presents it to the user.

---

## 🔍 Troubleshooting & Gotchas

- **Max 2 Correction Attempts**: If `fusion-executor` fails verification, `fusion-lead` sends 1 targeted correction specification. If it fails a second time, execution halts to present evidence to the user rather than entering an infinite loop.
- **No Unsafe Fallbacks**: If `fusion-executor` is unavailable or fails to spawn, `fusion-lead` must **not** silently make file edits itself. It will inform the user and request switching to standard mode.
- **Pi Skill Paths**: On Pi, child subagents cannot read outside the project workspace. Place required custom skills in `.agents/skills/` within the repository.

---

## 🔗 Related Resources

- [Agent Teams Usage Examples](./agent-teams-examples.md)
- [Subagent Infrastructure](../wiki/wiki/entities/subagent-infrastructure.md)
- [Orchestrating Fusion Skill](../../skills/orchestrating-fusion/SKILL.md)
