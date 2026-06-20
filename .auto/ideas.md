# Autoresearch Ideas — Cursor Composer 2.5 AMP Plugin

## All Completed — 23 experiments

- [x] Plugin created and structurally complete
- [x] Runtime-verified in AMP via `amp plugins list` — loads and shows active
- [x] TypeScript compilation verified — 0 errors in plugin file
- [x] Tools validated against AMP's built-in list (11/11)
- [x] Model validated against AMP's supported models
- [x] All API constraints met: label ≤ 16 chars, key ≤ 16 chars
- [x] Added to cli.sh install (experiment 18)
- [x] README documentation (experiment 17)
- [x] Benchmark improvements (experiments 14, 15, 19)
- [x] Tests added (experiment 20)
- [x] CI integration (experiment 22)
- [x] PR ready for review (experiment 23)

## Blocked (requires AMP GUI or LLM calls)

- **Integration testing**: CLI does not support plugin-defined agent modes (`amp threads new --mode` rejects them). Requires AMP desktop GUI.
- **Model comparison**: Would need to run actual LLM calls through AMP. Not feasible without GUI.
- **Prompt A/B testing**: Would need real user testing or automated LLM eval. Not feasible in current environment.
