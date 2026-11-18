---
name: cost-review
description: "Analyze AI coding spend across harnesses (Amp, Claude Code, Codex) and attribute cost changes with a six-term decomposition."
version: 1.0.0
author: my-ai-tools
license: MIT
compatibility: cline, claude, opencode, amp, codex, gemini, cursor, pi
hint: Use when the user asks about AI spend, why a bill went up, or how to reduce token cost.
user-invocable: true
metadata:
  audience: all
  workflow: cost-analysis
  related_skills: [retro, tmux]
---

# Cost Review

Attribute AI coding spend instead of summing it. A total answers nothing; a
per-term decomposition answers "what changed". Follow the Uber software-factory
method: decompose cost into six terms and attribute the week-over-week change
term by term, with no unexplained residual.

## When to Use

Use when the user asks:

- "How much are we spending on AI tools?"
- "Why did my usage/cost jump this week?"
- "Which model tier is worth its cost?"
- "Set up spend nudges before I burn the budget."

## Data Sources

Gather what is locally available. Never call a paid API to answer a cost
question unless the user provides the key and asks for it. Cite the source
next to every number; if a term cannot be observed, mark it `unknown` — do
not invent it.

| Harness | Source | Command / location |
| --- | --- | --- |
| Amp | CLI usage report, if the installed version provides one | `amp usage` (fall back to the harness's usage tool, e.g. the MCP `get_usage` tool, or the Amp web dashboard) |
| Claude Code | Local transcript JSONL | `npx ccusage@latest daily` (reads `~/.claude/projects/**/*.jsonl`); raw counts: `~/.claude/projects/**/*.jsonl` `message.usage` fields |
| Codex | Local session logs | `~/.codex/sessions/**/*.jsonl` token fields, or the OpenAI usage API with a user-provided `OPENAI_API_KEY` |
| Any | Platform dashboards | Ask the user to paste the numbers; record the source and date |

## Method: Six-Term Decomposition

Define one unit of work (a session, a task, a PR — state which you used).
Then:

```text
cost = sessions x turns-per-session x requests-per-turn x tokens-per-request x price-per-token
```

For each term, compute this period and last period, then attribute the cost
delta:

```text
delta(term) = (term_now / term_prev - 1) applied to the previous total
```

The attributed deltas must sum to the observed total change. Any leftover is
an arithmetic or data error — fix it, do not publish a residual. Uber used
this to explain a 34% unit-cost drop with the model held fixed; the point is
that "model price" is usually not the term that moved.

## Output

1. **Decomposition table** — one row per term: value now, value last period,
   attributed delta, and the source file or command behind it.
2. **Attribution sentence** — e.g. "the +38% came from turns/session (+41%,
   longer coordinator sessions), partly offset by cache pricing (-9%)".
3. **Cost per unit** — cost per merged PR, per review, or per landed task if
   the data supports it. Pair it with a quality signal when one exists
   (revert rate, review findings) so cheap is not confused with good.
4. **Spend nudges** — if a weekly budget is set (`AI_WEEKLY_BUDGET_USD`), state
   the projected week-end spend and the nudge level:
   - < 50% of budget: quiet.
   - 50–80%: one line in the reply naming the projection.
   - 80–100%: recommend concrete levers (route mechanical work to a cheaper
     tier, batch tool calls through a shell, raise the compaction threshold).
   - > 100%: recommend pausing non-blocking work until the reset.

## Levers, by term

- **sessions / turns**: long-lived sessions on short cache TTLs re-pay full
  input price after every idle gap. Prefer a longer prompt-cache TTL for the
  long-running session, not more restarts.
- **requests/turn**: chatty tool loops (polling, file-by-file reads) are the
  usual offender; batch them in one shell command.
- **tokens/request**: preloaded MCP schemas and pasted logs; use deferred
  tool loading and grep/tail scoped output instead.
- **price/token**: route mechanical work (log scans, bookkeeping, formatting)
  to the cheapest capable tier. Model choice is the single biggest lever, but
  check the other terms before reaching for it.

## Guardrails

- Every number carries its source. An unsourced number is a guess, not a finding.
- Absolute savings from other teams (Uber, Warp) do not transfer; only the
  decomposition method does.
- If two sources disagree, report both and name the discrepancy instead of
  averaging.
