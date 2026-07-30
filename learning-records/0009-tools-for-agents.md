# Established Understanding of Tools for Agents

The user established how agent tools (File, Search, API) are structured, validated, and fed back into context by evaluating the tool architecture in `flue-repo-assistant` (PR #7). This demonstrates how typed schemas (Zod/Valibot) ensure parameter bounds, how standardized metadata (`InspectionMetadata = { used, remaining, limit }`) informs context, and how observations feed back into the Observe-Act-Reflect loop.

## Evidence
- Analyzed `flue-repo-assistant` PR #7 tool architecture (`list_files`, `read_file`, `search_code`).
- Confirmed tool selection rules: `list_files` when structure/path is unknown, `search_code` when symbol/phrase path is unknown, and `read_file` when exact file is known.
- Created an interactive tool simulator in `lessons/0009-tools-for-agents.html` displaying schema validation and result traces.
- Built `scripts/evaluate-tools.ts` testing tool schemas (`list_files`, `read_file`, `search_code`), verifying truncation calculation (`truncated = requestedEnd > endLine || endLine < lines.length`), error wrapping with budget (`wrapWithBudget`), and safe debug logging (`createDebugLogger`).
