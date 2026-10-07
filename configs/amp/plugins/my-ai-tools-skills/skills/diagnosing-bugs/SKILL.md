---
name: diagnosing-bugs
description: "Build a tight, red-capable feedback loop before diagnosing failures, then minimize, test ranked hypotheses, and lock the fix with a regression test."
license: MIT
compatibility: cline, claude, opencode, amp, codex, gemini, cursor, pi
hint: Use when a bug is failing, flaky, incorrect, slow, or difficult to reproduce
user-invocable: true
metadata:
  audience: all
  workflow: debugging
  source: mattpocock/skills@6fd947921b935b7e1e69293a200400f0fdd5c15f
  source_path: skills/engineering/diagnosing-bugs/SKILL.md
---

# Diagnosing Bugs

Use this workflow for bugs, flaky failures, and performance regressions. The central rule is simple: do not start with a theory. First build a feedback loop that can go red on the user's actual symptom.

## When to Use

Use when:

- A test, command, request, or UI flow is failing.
- Behavior is incorrect but the failure is not yet understood.
- A bug is intermittent or timing-sensitive.
- A performance regression needs measurement before optimization.

Do not claim a diagnosis from code inspection alone when the symptom has not been reproduced or captured.

## Process

### 1. Redact and gather context

Redact secrets from commands, logs, screenshots, traces, and environment output before showing or storing them. Read the relevant project instructions, glossary, ADRs, issue, and recent changes. Record the exact user-visible symptom, not a nearby error.

### 2. Build a tight feedback loop

Prefer the smallest unattended command that exercises the real path and asserts the symptom:

1. A failing unit, integration, or end-to-end test at the correct public seam.
2. A curl or HTTP script against a running service.
3. A CLI fixture and expected-output comparison.
4. A browser script asserting DOM, console, or network behavior.
5. A replay of a captured request, event, or trace.
6. A minimal harness with real collaborators at the failing boundary.
7. A property or fuzz loop for input-dependent failures.
8. A bisection or differential loop when the regression has a known range.

Tighten the loop: cache setup, narrow assertions to the exact symptom, pin time and randomness, isolate the filesystem, and remove unnecessary network work. A slow or flaky loop is not a sufficient feedback loop until it is made deterministic or its reproduction rate is high enough to debug.

If no red-capable loop can be built, stop and report what was tried. Ask for a redacted trace, log, HAR, core dump, screen recording with timestamps, or access to the reproducing environment rather than guessing.

### 3. Reproduce and minimize

Run the loop and confirm it fails for the reported reason. For intermittent bugs, repeat or stress the trigger until its reproduction rate is useful. Minimize one input, caller, configuration, or step at a time; keep only elements that are load-bearing for the failure.

Completion condition: removing any remaining element makes the loop pass.

### 4. Rank falsifiable hypotheses

Write 3–5 ranked hypotheses. Each must predict an observable result:

> If `<cause>` is responsible, changing `<variable>` should make the symptom disappear or become worse.

Show the ranked list to the user before testing so they can supply domain evidence or identify hypotheses already ruled out. This is not an approval gate: proceed with the ranking while the user is unavailable.

Probe one prediction at a time. Prefer a debugger or REPL, then targeted logs at boundaries that distinguish hypotheses. Tag temporary logs with a unique prefix such as `[DEBUG-1234]` so cleanup is mechanical. For performance issues, measure a baseline and use a profiler or timing harness instead of logging everything.

### 5. Add the regression test before the fix

When a correct seam exists:

1. Convert the minimized reproduction into a test at the highest interface that exposes the real bug.
2. Run it and observe the expected failure.
3. Apply the smallest fix.
4. Run the test and the original, unminimized loop again.

Do not add a shallow test that cannot reproduce the call chain or interaction that caused the bug. If no correct seam exists, document that architectural gap and make it a follow-up improvement rather than claiming strong regression coverage.

### 6. Clean up and verify

Before declaring the bug fixed:

- The original reproduction no longer fails.
- The regression test passes at the correct seam.
- All temporary debug instrumentation is removed (`grep` the debug prefix).
- Throwaway harnesses and captured sensitive artifacts are deleted or safely redacted.
- The root cause and the verification commands are recorded in the commit or PR description.
- Broader tests and relevant lint/type checks pass, or their exact blockers are reported.

## Common Pitfalls

- **Theory before reproduction:** reading code until a plausible story appears. Build the red-capable loop first.
- **Wrong failure:** fixing an adjacent error while the user's symptom remains. Capture the exact symptom before changing code.
- **Single hypothesis:** anchoring on the first explanation. Rank several predictions and test them independently.
- **Debug-log archaeology:** leaving untagged instrumentation behind. Use a unique prefix and grep before finishing.
- **False regression confidence:** testing a helper that cannot exercise the real failure. Move the test to the highest viable seam or record the missing seam.
- **Performance guesswork:** optimizing before measuring. Establish a baseline and compare before/after results.

## Verification Checklist

- [ ] Sensitive output is redacted.
- [ ] A command that can go red on the exact symptom has been run.
- [ ] The reproduction was minimized.
- [ ] Multiple falsifiable hypotheses were considered.
- [ ] A regression test covers the real behavior or the missing seam is documented.
- [ ] The original loop, regression test, and broader checks were run.
- [ ] Temporary logs, harnesses, and artifacts were removed.
