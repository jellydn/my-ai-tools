# Autoresearch Ideas — Cursor Composer 2.5 AMP Plugin

## Completed
- [x] Plugin created and structurally complete (15 experiments)
- [x] Runtime-verified in AMP via `amp plugins list` — loads and shows active
- [x] TypeScript compilation verified — 0 errors in plugin file
- [x] Tools validated against `amp plugins show-agent-options --json` (11/11)
- [x] Model validated against AMP's supported agent models list
- [x] All API constraints met: label ≤ 16 chars, key ≤ 16 chars, valid hex color

## Deferred ideas (not yet pursued)

- **Add to cli.sh install**: The AMP plugin install section in cli.sh skips `.ts` files (`[ -d "$plugin_dir" ] || continue`). Our plugin won't be installed by the installer until this is fixed. Requires modifying cli.sh.

- **Integration testing**: Start an AMP thread with the cursor-comp-2.5 mode and verify the agent actually responds with the Cursor Composer 2.5 behavior.

- **Model comparison**: The model is `openai/gpt-5.2-codex` but the prompt targets Cursor Composer behavior. Could compare code quality across different models (claude-sonnet-4-6, gpt-5.5, gemini-3.5-flash).

- **Documentation**: Add a README section about how to use the Cursor Composer mode in AMP.

- **Benchmark improvements**: The current benchmark doesn't verify prompt/tool list consistency — references like "search" tool could drift from the actual tool list. Also doesn't check key/label lengths.

- **Prompt A/B testing**: Create variants of the Cursor Composer prompt (different operating principles, tool guidance styles) and compare code generation quality on a standard benchmark.
