# Autoresearch: Cursor Composer 2.5 AMP Plugin

## Objective

Create and optimize an AMP plugin (`configs/amp/plugins/cursor-composer-2.5.ts`) that registers a Cursor Composer 2.5 agent mode in the AMP coding assistant, following the same pattern as `configs/amp/plugins/glm-52-mode.ts` but tailored to Cursor Composer 2.5's capabilities.

The plugin uses `amp.experimental.createAgent()` and `amp.experimental.registerAgentMode()` to add a new agent mode with:
- A comprehensive system prompt tailored for code editing with Cursor
- An appropriate set of tools from AMP's plugin API
- A model suitable for Cursor Composer 2.5's capabilities
- Display configuration

## Metrics

- **Primary**: `prompt_score` (0–100, higher is better) — composite quality score based on:
  - **Structure** (35 pts): Does the prompt follow the GLM-5.2 pattern with all required sections (operating_principles, frame_the_task, plan_before_acting, codebase_discovery, tool_use, implementation_style, verification, communication)?
  - **Tool Selection** (20 pts): Are the tools appropriate for a Cursor-style agent (Read, Bash, edit_file, create_file, web_search, search, etc.)? No extraneous tools. Minimum 5, maximum 14.
  - **Specificity** (25 pts): Is the prompt tailored to Cursor rather than a generic copy? References to Cursor's API, agent capabilities, and workflow patterns.
  - **Conciseness** (10 pts): Line count vs information density. No bloated sections.
  - **Code Quality** (10 pts): TypeScript compiles, follows AMP plugin API pattern, proper exports.

- **Secondary**: `tool_count` (number), `line_count` (number), `file_size_bytes` (number)

## How to Run

```bash
./.auto/measure.sh
```

Outputs `METRIC name=value` lines.

## Files in Scope

- `configs/amp/plugins/cursor-composer-2.5.ts` — the AMP plugin being created and optimized
- `.auto/prompt.md` — this experiment definition (may be updated)
- `.auto/measure.sh` — the benchmark script (may be updated for better signal)

## Reference Files

- `configs/amp/plugins/glm-52-mode.ts` — the exact pattern to follow for creating the plugin
- `configs/amp/plugins/orca-agent-status.ts` — example of AMP plugin event handlers
- `configs/amp/plugins/plannotator.ts` — example of AMP plugin with commands

## Off Limits

- Do not modify `configs/amp/plugins/glm-52-mode.ts` — it's the reference pattern
- Do not modify `lib/`, `cli.sh`, `generate.sh`, or test files — those are out of scope
- Do not modify the `.auto/` infrastructure files (log.jsonl, config.json)
- Do not remove existing AMP plugins

## Constraints

1. The plugin must follow the exact structure of `glm-52-mode.ts`: import `PluginAPI`, default export function, use `amp.experimental.createAgent()` and `amp.experimental.registerAgentMode()`
2. TypeScript must compile (structural check — no actual compilation needed, but the import/export pattern must match)
3. The prompt must have meaningful content — not a stub or placeholder
4. No new external dependencies
5. The plugin file must be a single `.ts` file in `configs/amp/plugins/`
6. Model name should reference `cursor/composer-2.5` or a provider that supports Cursor-style capabilities

## What's Been Tried

*(Update this section as experiments accumulate.)*

- **Baseline** (commit 10aec40) — Initial plugin created following GLM-5.2 pattern with Cursor-tailored prompt. Score: 68/100.
  - Structure: 12/30 (import/export perfect, but section depth very low — only 2 sections have 15+ lines)
  - Tools: 15/20 (9/9 desired tools, 11 total, no bloat)
  - Authenticity: 18/25 (5/10 originality, 13/15 Cursor-specificity)
  - Section quality: 13/15 (7/7 complete sections)
  - Code quality: 10/10 (perfect)
  - Key gap: Most prompt sections are 4-7 lines. Need to deepen operating_principles, frame_the_task, plan_before_acting, codebase_discovery, tool_use, implementation_style, verification, and communication to 8+ lines.
