---
name: orchestrating-fusion
description: "Coordinates a strong read-only lead with a cheaper implementation executor. Use for non-trivial coding tasks that benefit from separate planning, execution, and independent verification."
license: MIT
compatibility: claude, opencode, amp, codex, gemini, cursor, pi, cline
user-invocable: true
metadata:
  audience: all
  workflow: orchestration
---

# Fusion Orchestration

Separate judgment from mechanical implementation. A lead investigates, decides, specifies, reviews, and verifies. An executor edits only the bounded scope in the lead's specification.

## Route Deliberately

Do not force every task through Fusion:

- Keep a tiny, already-understood, single-file mechanical change in the normal writable session.
- Use Fusion when investigation, architectural judgment, multiple non-trivial writes, or independent review materially improve the result.
- Offer a durable PRD, ADR, or implementation plan only when persistent artifacts reduce substantial ambiguity. Never create a spec lifecycle merely because a change is large or risky.

## Native Adapters

Prefer the installed native roles when the current tool exposes them:

- **OpenCode:** run the `fusion-lead` primary; it can delegate to `fusion-executor` and cannot edit or run shell commands.
- **Amp:** select the `fusion` agent mode; its restricted tool surface exposes `fusion_executor` for implementation.
- **Codex:** from the writable root session, spawn `fusion-lead` for the specification, then spawn the sibling `fusion-executor`; a read-only child cannot safely escalate a nested child to workspace-write.
- **Pi:** from the root session, use the `Agent` tool to run `fusion-lead`, then run the sibling `fusion-executor`; `pi-subagents` enforces the lead's tool allowlist and intentionally disables nested delegation.

For other assistants, apply the workflow below using their native subagent/task tool. Treat role separation as advisory unless the harness actually restricts each role's tools or sandbox.

## Workflow

1. Have the lead inspect the request and relevant code. It may delegate read-only discovery.
2. The lead resolves architectural and product choices. Ask the user only when a missing decision materially changes the result.
3. The lead selects only the relevant installed skills. Include each exact `SKILL.md` path in the handoff; do not paraphrase a skill into a lossy substitute or preload unrelated skills.
4. The lead sends the executor one bounded specification using this contract. When the harness prevents nested delegation, the lead returns this specification to the writable root, which starts the executor as a sibling:

```text
OBJECTIVE
FILES
INTERFACES
CONSTRAINTS
SKILLS
VERIFICATION
```

5. The executor reads every listed skill from its exact path, implements the smallest complete change, persists artifacts before responding, and returns a final text envelope:

```text
STATUS
EXECUTIVE SUMMARY
CHANGES
VERIFIED
SKILLS LOADED
RISKS
QUESTIONS
NEXT RECOMMENDED
KEY LEARNINGS
```

Verification contract: the executor runs only checks the runtime permits or the user has approved. Exact read-only inspection commands usually run directly. Other checks may require approval, root mediation, or may be denied (OpenCode denial can terminate the child before an envelope returns). When a check cannot run inside the executor, it must report `VERIFICATION REQUIRED` with the exact command; the interactive root then runs that exact command and supplies the evidence before acceptance. Never treat a missing, declined, timed-out, or root-only check as passed.

6. The lead gates the handoff before claiming success:
   - Validate that every required envelope section is present (or that a structured failure envelope explains why it is not).
   - Read back every claimed changed path or artifact.
   - Confirm named paths and symbols exist and the changes remain in scope.
   - Inspect exact verification commands and outcomes; independently rerun the narrowest meaningful check when possible.
   - Relay blocking questions losslessly, preserving every option, constraint, and reason input is required.
7. If the gate fails, the lead sends one targeted correction specification. If the second result still fails, stop and report the evidence instead of entering an unbounded fix loop.

Run independent executor tasks in parallel only when their write targets do not overlap. Never delegate commit, push, deployment, destructive operations, or external side effects without explicit user approval.

## Capability Guarantees

Prompt text is not a security boundary. Describe a role as enforced only when the harness removes mutation tools or applies a read-only sandbox. Shell access can bypass a missing edit tool, so a role with unrestricted shell is not mechanically read-only.

**Pi skill paths:** Fusion on Pi supports project-local skills under the task working directory (for example `.agents/skills/.../SKILL.md` or `.pi/skills/...`). The executor denies external-directory reads, so globally installed skills under `~/.agents/skills` are not loadable inside the child. The interactive root mediates global skills when needed. Full dynamic global-skill support needs a larger adapter or upstream read-only external access.

**Amp residuals:** Amp authorizes `fusion_executor` from plugin-owned lead thread IDs after the lead is observed; until then it falls back to the complete expected lead agent definition (`kind` + `name`), which is not documented as a unique authorization principal across third-party plugins.

If the native executor is unavailable or its model/provider fails, report the blocker. Do not silently let a supposedly read-only lead edit as a fallback; ask the user to switch to normal unrestricted mode instead.
