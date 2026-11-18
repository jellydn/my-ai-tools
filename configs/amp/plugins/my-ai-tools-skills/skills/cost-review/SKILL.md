---
name: cost-review
description: "Analyze AI coding spend across harnesses (Amp, Claude Code, Codex) and attribute cost changes with a five-term decomposition."
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

| Harness     | Source                                                  | Command / location                                                                                                                                                                                                |
| ----------- | ------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Amp         | CLI usage report, if the installed version provides one | `amp usage` (fall back to the harness's usage tool, e.g. the MCP `get_usage` tool, or the Amp web dashboard)                                                                                                      |
| Claude Code | Local transcript JSONL                                  | `npx ccusage@20.0.51 daily` (version pinned so every review runs the same release; bump deliberately) reading `~/.claude/projects/**/*.jsonl`; raw counts: `~/.claude/projects/**/*.jsonl` `message.usage` fields |
| Codex       | Local session logs                                      | `~/.codex/sessions/**/*.jsonl` token fields, or the OpenAI usage API with a user-provided `OPENAI_API_KEY`                                                                                                        |
| Any         | Platform dashboards                                     | Ask the user to paste the numbers; record the source and date                                                                                                                                                     |

### Confirm the log schema before aggregating

Local logs differ per harness and per release. Before aggregating any token
fields, confirm the schema you are reading and whether the counters are
cumulative: where they are (Codex session logs can be), aggregate counter
changes inside the reporting window, never a sum of cumulative snapshots.
Check whether the input total already includes cached tokens, and price
cached and non-cached input separately so nothing is counted twice. When a
schema or the applicable rates cannot be confirmed, report that spend as
`unknown` and say what would confirm it.

## Method: Five-Term Decomposition

Define one unit of work (a session, a task, a PR — state which you used).
Then:

```text
cost = sessions x turns-per-session x requests-per-turn x tokens-per-request x price-per-token
```

For each term, compute this period and last period, then attribute the cost
delta with **sequential substitution**: hold every term but one at its
previous value, recompute the total, and give that term the difference. Walk
the terms in a fixed order — sessions, turns per session, requests per turn,
tokens per request, price per token — and state the order in the report,
because it affects the allocation when several terms move together.

The walk is required, not cosmetic: cost is a product, so the terms'
percentage deltas do not add. Example: sessions 100 → 200 and turns per
session 10 → 20, tokens per request fixed. Baseline 100 × 10 = 1,000 units;
observed 200 × 20 = 4,000. Substitution attributes +1,000 to sessions
(200 × 10 = 2,000) and +2,000 to turns/session (200 × 20 = 4,000): the sums
reconcile. Attributing each factor's own +100% to the 1,000-unit baseline
would give +1,000 + +1,000 = 2,000, leaving 1,000 unexplained despite
perfectly consistent data. The attributed amounts always sum exactly to the
observed change; if they do not, the data or arithmetic is wrong — fix it,
do not publish a residual. Uber used
this to explain a 34% unit-cost drop with the model held fixed; the point is
that "model price" is usually not the term that moved.

Cache pricing is not a sixth term: cached input is billed at a fraction of
the input price, so it lives inside price-per-token. Either take the cost
fields the billing data already carries (ccusage reports costs per model), or
split tokens-per-request into cached and non-cached input, each with its own
rate. Never price cached tokens at the full input rate — that double-counts
them.

Two situations suspend the walk:

- **The previous period has no usage.** Against a zero baseline the
  percentage change and the per-term split are undefined. Report the spend
  as new activity with its absolute amount, and mark the percentage and the
  per-term split as unavailable.
- **A factor cannot be observed, or the two periods are not comparable.**
  Exact reconciliation is required only when both periods have complete,
  comparable cost data. Otherwise report the observed total change, list
  the factors that are `unknown`, and state what prevents the attribution —
  never manufacture a complete split.

## Output

1. **Decomposition table** — one row per term: value now, value last period,
   attributed delta, and the source file or command behind it.
2. **Attribution sentence** — e.g. "the +38% came from turns/session (+41%,
   longer coordinator sessions), partly offset by price/token (-9%, cheaper
   model mix on mechanical work)".
3. **Cost per unit** — cost per merged PR, per review, or per landed task if
   the data supports it. Pair it with a quality signal when one exists
   (revert rate, review findings) so cheap is not confused with good.
4. **Spend nudges** — if a weekly budget is set (`AI_WEEKLY_BUDGET_USD`), pick
   the band from the share of the budget actually spent so far, and report the
   projected week-end spend alongside it, with the elapsed-time and spending
   assumptions the projection rests on. The bands do not overlap:
   - under 50% spent: quiet.
   - 50% up to but not including 80% spent: one line in the reply naming the
     projection.
   - 80% up to and including 100% spent: recommend concrete levers (route
     mechanical work to a cheaper tier, batch tool calls through a shell,
     raise the compaction threshold if the harness supports that control).
   - over 100%: recommend pausing non-blocking work until the reset.

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
