# Established Understanding of Agent Basics and Bounded Loops

The user established a fundamental understanding of AI agent architectures (Observe-Act-Reflect loops, tool selection, and bounded execution) by building and evaluating an agent execution loop. This demonstrates how controlled loops wrap around LLM completions, enabling tool usage while guaranteeing safe stopping boundaries via step budgeting.

## Evidence
- Analyzed the `flue-repo-assistant` repository analysis agent architecture (`agents/repo-assistant.ts` and `tools/repository.ts`).
- Built a local TypeScript agent evaluator script (`scripts/evaluate-agent.ts`) implementing step budgeting and tool routing (`list_files`, `read_file`, `search_code`).
- Verified that direct questions (e.g. "What is TypeScript?") answer immediately without tool invocation.
- Confirmed that multi-step repository questions execute an Observe -> Act -> Reflect loop and stop cleanly upon collecting sufficient evidence.
- Tested bounded step budgets (e.g. max 2 steps) and verified that budget exhaustion safely intercepts further tool calls and returns an explicit budget-exhausted answer.
