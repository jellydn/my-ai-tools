# 30-Day Applied AI Learning Sprint

*A practical month of building, measuring, and explaining AI systems.*

This is a build-first learning path for software engineers. Every day produces a small artifact that can be tested, reviewed, or reused. The goal is not to memorize model trivia. The goal is to learn where probabilistic software helps, where deterministic code is better, and how to operate the boundary safely.

## How to use this guide

- Spend 30–60 minutes on the daily exercise.
- Keep one small repository with the prompts, data, evaluations, and notes.
- Record the model, prompt version, latency, token usage, cost, and failures.
- Prefer a deterministic baseline before adding RAG, agents, or fine-tuning.
- Do not use production secrets or private customer data in experiments.
- At the end of each week, write what failed and what you would remove.

## The 30 days

### Week 1 — Model the problem before the model

#### Day 1 — Pick a real task

Choose one narrow task with a clear user and outcome: classify support requests, extract fields from invoices, answer questions over internal docs, or draft a code-review summary.

**Deliverable:** a one-paragraph problem statement with inputs, outputs, users, risks, and a measurable success criterion.

#### Day 2 — Build a deterministic baseline

Write the simplest non-LLM implementation you can. Rules, regular expressions, SQL, and ordinary application code are useful baselines, not failures.

**Deliverable:** baseline code plus three examples where it succeeds and three where it fails.

#### Day 3 — Make the first model call

Use a small, fast model for extraction, classification, or transformation. Keep the prompt short and ask for structured output.

**Deliverable:** a repeatable script with the prompt and model settings stored in version control.

#### Day 4 — Validate the output

Treat model output as untrusted input. Parse it against a schema, handle missing fields, and reject malformed responses.

**Deliverable:** schema validation tests for valid, incomplete, malformed, and adversarial outputs.

#### Day 5 — Create a small golden dataset

Collect representative examples, edge cases, and known failures. Include the expected outcome or an explicit acceptable range.

**Deliverable:** at least 20 labelled cases in a machine-readable format.

#### Day 6 — Measure quality, latency, and cost

Run the same dataset through the baseline and model solution. Track quality separately from latency and cost; a single score hides trade-offs.

**Deliverable:** a small evaluation report with the dataset version, model, metrics, and failure examples.

#### Day 7 — Write the first decision record

Decide whether the model is justified. If it is not clearly better than the baseline, simplify. If it is, document the value and the remaining risks.

**Deliverable:** a short ADR stating what you will build and what you deliberately will not build.

### Week 2 — Ground answers in evidence

#### Day 8 — Prepare the source data

Parse the documents your task actually needs. Preserve title, source, owner, permissions, version, and update time as metadata.

**Deliverable:** a cleaned sample corpus and an ingestion note describing unsupported formats.

#### Day 9 — Chunk by meaning

Compare structure-aware chunks with fixed-size chunks. Keep headings and useful context; avoid splitting tables or procedures in the middle.

**Deliverable:** a chunk preview showing source metadata and at least five difficult documents.

#### Day 10 — Implement retrieval

Start with keyword search or a simple vector index. Do not introduce a framework until you understand the retrieval inputs and outputs.

**Deliverable:** a retrieval function returning ranked chunks, scores, and source paths.

#### Day 11 — Add hybrid search or reranking

Use lexical search for exact names and identifiers, semantic search for meaning, and reranking only when evaluation shows it improves results.

**Deliverable:** a comparison of baseline retrieval and the improved method on the golden questions.

#### Day 12 — Generate cited answers

Require the answer to cite the retrieved sources. If evidence is missing or contradictory, return uncertainty instead of inventing an answer.

**Deliverable:** five answers with citations and three intentional “insufficient evidence” cases.

#### Day 13 — Test permissions and freshness

Apply access control during retrieval, not just during ingestion. Re-index changed documents and remove stale versions.

**Deliverable:** tests proving an unauthorized document cannot influence an answer and an old version is not returned.

#### Day 14 — Evaluate retrieval separately

Measure retrieval recall and answer quality as separate concerns. A fluent answer can still be based on the wrong document.

**Deliverable:** a weekly report containing retrieval failures, answer failures, and the next experiment.

### Week 3 — Add actions carefully

#### Day 15 — Map the workflow

Draw the task as a deterministic sequence. Mark the points where the next step is genuinely unknown and where a normal function is enough.

**Deliverable:** a workflow diagram and a list of candidate tools.

#### Day 16 — Define narrow tools

Give each tool one job, a precise schema, bounded inputs, and a clear result. Keep read tools separate from write tools.

**Deliverable:** tool definitions with examples, validation rules, and error responses.

#### Day 17 — Enforce authorization outside the model

The model may request an action, but application code decides whether it is allowed. Unknown tools, missing approvals, and invalid arguments must fail closed.

**Deliverable:** an authorization test matrix for anonymous, normal, privileged, and revoked users.

#### Day 18 — Add timeouts, retries, and idempotency

Assume network calls fail and models repeat themselves. Bound retries, use backoff, and make write operations safe to retry.

**Deliverable:** failure-injection tests for timeout, duplicate request, malformed result, and partial completion.

#### Day 19 — Define termination and budgets

Set maximum steps, wall-clock time, token budget, and tool-call budget. A system without a stopping rule is an incident waiting to happen.

**Deliverable:** a run policy that explains when the system stops, asks for approval, or escalates.

#### Day 20 — Add human approval

Require confirmation for irreversible, high-impact, or externally visible actions. Show the proposed action and the evidence behind it.

**Deliverable:** an approval screen or CLI prompt plus tests that prove approval cannot be bypassed.

#### Day 21 — Compare workflow and agent

Implement the same task as a fixed workflow and as a bounded agent. Compare quality, latency, cost, and failure recovery.

**Deliverable:** a decision explaining whether dynamic planning is worth its additional complexity.

### Week 4 — Operate and teach the system

#### Day 22 — Add observability

Log request ID, model, prompt version, retrieval sources, tool calls, latency, token usage, outcome, and error class. Redact secrets and sensitive content.

**Deliverable:** a trace that explains one successful run and one failed run without reading raw private data.

#### Day 23 — Test adversarial inputs

Try prompt injection, poisoned documents, malicious tool arguments, oversized inputs, data exfiltration requests, and misleading retrieved content.

**Deliverable:** an adversarial test set with severity, expected behavior, and release-blocking failures.

#### Day 24 — Improve cost and latency

Use the smallest model that meets the evaluation bar. Cache stable context, parallelize independent reads, trim irrelevant context, and stream only where it helps users.

**Deliverable:** before-and-after measurements with quality held constant.

#### Day 25 — Test model changes

Treat model, prompt, embedding model, chunker, and reranker changes as versioned releases. Re-run the golden dataset before switching defaults.

**Deliverable:** a regression report showing improvements, regressions, and unresolved cases.

#### Day 26 — Add a fallback path

Define what happens when the provider is unavailable, the answer is uncertain, retrieval is empty, or a tool fails halfway through.

**Deliverable:** a fallback matrix and an end-to-end test for each important failure mode.

#### Day 27 — Package the workflow

Write the setup instructions, environment variables, dry-run command, test command, and rollback procedure. A useful experiment should be reproducible by someone else.

**Deliverable:** a README section that takes a new developer from clone to first verified run.

#### Day 28 — Explain the trade-offs

Write a one-page system design covering the baseline, data flow, trust boundaries, evaluation, operations, and known limitations.

**Deliverable:** a design note that a reviewer can challenge without opening the implementation.

#### Day 29 — Teach it without hiding uncertainty

Explain the system to another engineer. Ask them to predict where it fails and to find one unsupported claim in its output.

**Deliverable:** review notes and at least one change made from the feedback.

#### Day 30 — Ship the smallest useful version

Remove experiments that did not improve the measured outcome. Keep the smallest reliable path, its tests, its evaluation dataset, and its operational limits.

**Deliverable:** a tagged release or pull request with a changelog, evaluation summary, known limitations, and next experiment.

## What this month should teach

1. **AI is a software component, not the architecture.** Use deterministic code wherever it is sufficient.
2. **Evaluation comes before optimization.** Without a representative dataset, model and retrieval changes are guesses.
3. **Knowledge and behavior are different problems.** Use retrieval for current or private knowledge; consider fine-tuning only for stable behavior after prompting and examples fail.
4. **Agents need boundaries.** Tools, permissions, budgets, termination conditions, and approvals belong in application code.
5. **Fluency is not correctness.** Require evidence, citations, validation, and explicit uncertainty.
6. **Operational details are part of quality.** Latency, cost, privacy, observability, fallback behavior, and rollback determine whether a demo can become a product.
7. **The durable skill is judgment.** Learn to choose the least complex system that meets the measured need, then verify it continuously.

## Suggested project layout

```text
ai-learning-lab/
├── README.md
├── data/
│   ├── golden.jsonl
│   └── adversarial.jsonl
├── src/
├── evals/
│   ├── run.py
│   └── reports/
├── prompts/
├── traces/
└── decisions/
```

Keep prompts, evaluation data, and decisions versioned with the code. That history is more useful than a screenshot of a successful demo.

## References

- [Applied AI & GenAI Cheat Sheet](ai-applied-genai-cheat-sheet.md) — concepts and production checklists.
- [OWASP Top 10 for LLM Applications](https://owasp.org/www-project-top-10-for-large-language-model-applications/) — security risks to include in adversarial tests.
- [NIST AI Risk Management Framework](https://www.nist.gov/itl/ai-risk-management-framework) — risk-management vocabulary and lifecycle guidance.
