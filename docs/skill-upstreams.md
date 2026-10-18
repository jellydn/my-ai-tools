# Skill upstream maintenance

Last checked: 2026-10-07. Repository base: `163951e` (PR #417).

`skills/` is canonical. The Amp bundle in
`configs/amp/plugins/my-ai-tools-skills/skills/` must contain identical files.
The Claude marketplace points directly to canonical directories. `generate.sh`
exports installed home configuration; it is not an upstream skill updater.

## Refresh policy

- Read local history before replacing an upstream-inspired skill. Preserve local
  tool names, resource paths, approval rules, and intentional workflow changes.
- Fetch upstream text at a recorded commit. Review scripts, hooks, MCP startup,
  credential access, network destinations, and external-state changes before import.
- Copy changed canonical bundles to the Amp mirror and run the mirror test.
- Recommendations are live upstream installations, not vendored or locked bundles.
  A checked commit records the review point, not a promise that a future install
  uses that revision. Review executable content again before installation or use.

The October 2 refresh was an unpushed commit on another executor. Its thread was
read for the method and decisions; its patch was not copied. This refresh compares
current files directly with current upstream sources. Later local changes take
precedence, including the restored `babysit-pr` and first-party `visual-pr`.

## Canonical skills: 36 checked

| Skills | Source revision | Decision |
| --- | --- | --- |
| `plannotator-setup-goal` | [backnotprop/plannotator@1d9fe3f](https://github.com/backnotprop/plannotator/commit/1d9fe3f10fb34af0ef3ce9eed8db1c103a0b05cc), latest release v0.28.6 | Update interview/fact bundles, result persistence, accepted fact metadata, optional grilling, and browser-session patience. Keep portable metadata and plan gate. |
| `portless-local` | [vercel-labs/portless@7abf4df](https://github.com/vercel-labs/portless/commit/7abf4df5d939fe3b527a120e20bc270c681c3536), latest release v0.15.7 | Update workspace/configuration support, state directory, diagnostics, sharing, routing, and framework flag limits. Gate privileged/system/network changes. |
| `codemap` | [glittercowboy/get-shit-done@bdcaab2](https://github.com/glittercowboy/get-shit-done/commit/bdcaab2c752d9a33a1a1ca9acf3a3c81fb991815) | Adapt scoped mapping, sequential fallback, dates, output checks, and secret scanning. Keep seven compact local templates and standalone operation; do not import GSD SDK dependencies. Reject invalid scope rather than falling back to a whole-repository scan. |
| `diagnosing-bugs` | [mattpocock/skills@6fd9479](https://github.com/mattpocock/skills/commit/6fd947921b935b7e1e69293a200400f0fdd5c15f) | Add the non-blocking ranked-hypothesis checkpoint. Preserve local red-capable feedback loop and regression-seam rules. |
| `code-review`, `implement-spec`, `pr`, `retro`, `tdd` | Same Matt Pocock revision | Keep local adaptations: portable context discovery, safe worktree integration, PR evidence, human-selected retrospectives, and Red-Green-Refactor. Do not require absent setup skills, invent issue-tracker configuration, or import upstream resets. |
| `prd`, `ralph` | [snarktank/ralph@6c53cb0](https://github.com/snarktank/ralph/commit/6c53cb0b831ebe8739c6a003e22af14902d8b0b5) | No applicable behavioral update; retain local metadata and formatting. |
| `tmux` | [mitsuhiko/agent-stuff@0865c84](https://github.com/mitsuhiko/agent-stuff/commit/0865c849befd2021490679f96a8dee58c84ac857) | Preserve intentional LogPilot/socket adaptation. |
| `visual-pr` | [humanlayer/skills@ca7c808](https://github.com/humanlayer/skills/commit/ca7c8088db69e315a8b2deea43820270457f8f3c) | Preserve first-party marked-comment publisher; upstream replaces the PR body. Keep comment template and publisher tests. |
| `babysit-pr` | [openai/codex@5e96aab](https://github.com/openai/codex/commit/5e96aabd68dc6194f5ad928cb7f5d0bc71b72df9), final pre-removal source | Current upstream path returns 404. Preserve the explicitly restored local watcher and its tests; do not remove it again. |

The following 22 skills are local designs or adaptations of ideas/standards, not
maintained upstream file copies. Their current repository versions remain canonical:

`accountable-engineering`, `adr`, `blindspot-pass`, `capability-experiments`,
`code-quality-review`, `commit-atomic`, `context-discovery`, `doc-search`,
`docs-update`, `draft-pull-request`, `git-context`, `handoffs`,
`implementation-logger`, `llm-wiki`, `orchestrating-fusion`, `pickup`, `pr-review`,
`qmd-knowledge`, `quiz-me`, `security-audit`, `slop`, `spec-interview`.

The 15 tool-specific SKILL.md files under `configs/{amp,cline,kimi-code}/skills/`
are local adapters for `code-reviewer`, `test-generator`, `documentation-writer`,
`ai-slop-remover`, and `security-audit`. They have no independent external upstream;
keep their tool-specific guidance. Do not replace the short adapter security skill
with the larger canonical audit workflow.

## Recommendations: 21 entries, 20 repositories checked

All checked repositories are reachable and unarchived; API trees were not truncated.
Named skill selectors were checked against frontmatter, not only directory names.
In particular, Engram's `plugin/claude-code/skills/memory/SKILL.md` declares
`name: engram-memory`; the existing selector is correct despite the directory name.
Collection entries remain live collections; this check is not a security audit of
every skill they may install. Preserve the local pstack-first order.

| Repository | Checked commit | Notes |
| --- | --- | --- |
| BuilderIO/skills | [530d9ee](https://github.com/BuilderIO/skills/commit/530d9eee0453be9672960ef7b0a265c949cd8b08) | `visual-recap`; supports local-files privacy mode. |
| Gentleman-Programming/engram | [3423d74](https://github.com/Gentleman-Programming/engram/commit/3423d7484ca11d5222640a1e6880ff5f54f589c5) | Latest release v3.1.0; checked MCP contract has 22 tools. Update stale 20-tool wording. |
| GoogleChrome/modern-web-guidance | [650eb83](https://github.com/GoogleChrome/modern-web-guidance/commit/650eb83619134adb947b1ee8755e6511270bc444) | `modern-web-guidance`; linked guide bundle. |
| av/facts | [30911b8](https://github.com/av/facts/commit/30911b8efe3fd4dc641463ed6de57ca5bedd0d72) | Collection; verification commands execute shell code. |
| blader/humanizer | [225a6f3](https://github.com/blader/humanizer/commit/225a6f39ac85f76ee48dbad772ea4abe4ed6c9d8) | Root skill. |
| ctxrs/ctx | [56aaf35](https://github.com/ctxrs/ctx/commit/56aaf35233ce7f8aa739c207525a3d67e6ddddbd) | Agent-history skill; keep sensitive transcripts out of shared outputs. |
| dzhng/jevgrep | [703aba1](https://github.com/dzhng/jevgrep/commit/703aba1a36a3b854be405244ea748f607cd630c0) | `jevgrep`; interactive saved-provider credentials, Node.js 22+. |
| expo/skills | [d4f4840](https://github.com/expo/skills/commit/d4f484024fec15196bfd3c272e953e3f983972cf) | Live collection. |
| factory-ai/factory-plugins | [d362dc1](https://github.com/factory-ai/factory-plugins/commit/d362dc1823301bee56315bd73f22b5614392365c) | `no-use-effect`. |
| github/gh-stack | [d4ab7ab](https://github.com/github/gh-stack/commit/d4ab7ab47e5b3e3708a27c8c42abcdf4bc321419) | Skill metadata 0.2.0; authenticated GitHub writes and history operations require authorization. |
| jezweb/claude-skills | [64965d9](https://github.com/jezweb/claude-skills/commit/64965d9d9fc76ad2caeea2e27dd8d679ec7521b3) | Remove stale 97-skill count; live collection. |
| mattpocock/skills | [6fd9479](https://github.com/mattpocock/skills/commit/6fd947921b935b7e1e69293a200400f0fdd5c15f) | Both `grill-with-docs` and `improve-codebase-architecture`. |
| michael-denyer/pstack-claude | [552b1c8](https://github.com/michael-denyer/pstack-claude/commit/552b1c85f990f1b0bb7d9806aa2e8461ce5438d0) | `poteto-mode`; playbooks and reviewer scripts remain upstream. |
| modem-dev/hunk | [252f59d](https://github.com/modem-dev/hunk/commit/252f59dd39409b2390d02b0f9e003819c9d41176) | Latest release v0.23.0; correct path is `packages/hunk/skills/hunk-review/SKILL.md`. |
| mvanhorn/last30days-skill | [7f582ad](https://github.com/mvanhorn/last30days-skill/commit/7f582ad8c2e140eca08098b245f9e31b68e28b60) | Network research; credential/config loading includes env, Keychain, and pass. |
| openclaw/agent-skills | [0595f72](https://github.com/openclaw/agent-skills/commit/0595f725087f0208c69edbaf74cb968ca876fd04) | `autoreview`; see transmission warning below. |
| privatenumber/mac-ocr | [d9f25ba](https://github.com/privatenumber/mac-ocr/commit/d9f25baecc7258a3479f3a067e001838ca4e9c71) | `mac-ocr`; macOS-only runtime, optional piped network input. |
| shadcn/improve | [cac56e1](https://github.com/shadcn/improve/commit/cac56e1ebd3c279aa9153616cfeac7b174ab90f9) | Explicit issue publication flag; sensitive public findings require confirmation. |
| tt-a1i/archify | [73aaa06](https://github.com/tt-a1i/archify/commit/73aaa0696e8f72c232ea710e6fa94fd953f3e773) | `archify`; local rendering/browser checks, optional brand-URL capture. |
| vercel-labs/agent-skills | [063bee9](https://github.com/vercel-labs/agent-skills/commit/063bee94c3f4df8453406c830b0a7df0f2860278) | Live collection. |

## Security review notes

- No new executable scripts, hooks, MCP declarations, endpoints, or credentials
  are imported by this refresh. Existing scripts remain unchanged.
- Portless may change trust stores and hosts files, expose servers, install a
  root/SYSTEM startup service, or terminate processes. The local skill now makes
  those approval boundaries explicit. Do not print TLS keys or ngrok tokens.
- Codemap's supplementary secret check prints only filenames. It does not prove
  absence of all secrets. Invalid scope does not authorize wider exploration.
- Plannotator JSON can contain private goal details. Keep it in the goal directory;
  browser idleness is not permission to terminate the user's session. Commands use
  direct stdout redirection so a pipeline cannot hide a CLI failure.
- Engram hooks perform session writes, import Git-synced memory, and may start a
  local server with cloud autosync enabled. Cloud transmission depends on configured
  credentials/settings. Review those settings and consent before enabling cloud sync
  or an external `ENGRAM_URL`; installing a skill alone is not installing its hooks.
- Visual Recap normally publishes to hosted Plan MCP. Use its supported
  `AGENT_NATIVE_PLANS_MODE=local-files` mode when hosted database writes are not
  authorized. This refresh does not change personal environment settings.
- Autoreview sends captured diffs/source to a reviewer provider and deliberately
  has no pre-transmission secret scanner. Reviewer findings occur **after** sending.
  Run approved local secret checks first and authorize provider transmission. Its
  executable isolates reviewer credentials/settings; do not weaken isolation.
- Jevgrep and Last 30 Days use external providers and saved credentials. Do not
  ask for keys in chat, print them, or execute imported setup scripts during a refresh.
- Live collection installs and upstream CLI downloads remain a supply-chain risk.
  The snapshot above is not a blanket security approval for their current or future
  scripts. No upstream helper was executed for this refresh.

## Validation on this refresh

- Full Bats suite with PyYAML and jsonschema: 589 passed, 1 failed. The failure,
  `validate_config_with_schema fails when schema mismatches`, also reproduces on
  the unchanged base. Its unquoted shell heredoc expands `$schema` to an empty
  key, so the fixture does not declare a schema. Leave that unrelated bug unchanged.
- Focused recommendation and Amp bundle tests: 75 passed.
- Bun tests: 48 passed; TypeScript typecheck passed.
- Babysit PR watcher tests: 5 passed.
- Shell syntax, token-efficiency sync, installer/export dry runs, mirror equality,
  and skill frontmatter checks passed. No real installation was run.
- Changed JSON passes Biome. Full repository Biome reports 427 errors and one
  informational diagnostic, identical to the unchanged base. No unrelated
  formatting changes are included.
