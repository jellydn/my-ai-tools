# Applied AI & GenAI Cheat Sheet

*A production-oriented reference for learning, interviews, and system design.*

## 1. The Core Mental Model

> AI systems are software systems with probabilistic components.

When designing one, answer:

1. What does the user want?
2. What data or tools are authoritative?
3. Where can the model make a mistake?
4. How do we detect and recover from mistakes?
5. How do we measure quality, latency, security, and cost?

Prefer deterministic software where possible. Use an LLM where language understanding, generation, classification, or dynamic decision-making creates real value.

---

## 2. LLM Fundamentals

| Concept | Practical meaning |
|---|---|
| Token | A piece of text processed by the model. Tokens affect context limits and cost. |
| Context window | The maximum input/output context the model can consider in one request. |
| Temperature | Controls randomness. Lower values are better for predictable structured tasks; higher values can help creative generation. |
| System prompt | High-level behavior, constraints, and role instructions. |
| User prompt | The task or request from the user/application. |
| Structured output | Model output constrained to a schema such as JSON. Still validate it. |
| Hallucination | An answer that sounds plausible but is unsupported or false. |
| Reasoning model | A model optimized for deliberate multi-step problem solving, usually with higher latency/cost. |
| Non-reasoning model | Faster and cheaper for straightforward extraction, classification, transformation, or generation. |

### Transformer explanation

A transformer uses self-attention to model relationships between tokens. Text is tokenized, tokens are represented numerically, and the model predicts the next token autoregressively. For most applied-AI interviews, this conceptual explanation is enough.

---

## 3. Choose the Simplest Technique

Move to a more complex technique only when evaluation shows the simpler one is not enough. These sources do not share a numeric cutoff for accuracy, example count, context size, or cost. Measure that on your own dataset.

| Level | Use it when | Stop here when |
|---|---|---|
| Prompting | The task fits in one call with a system prompt and a few examples. | That call meets the eval bar. |
| Long context or cache | The needed context is known ahead of time and fits the window. | Putting that context in the prompt, or caching it, meets the eval bar. |
| RAG | The context is private, current, or unknown until the query. | Retrieval plus a prompt meets the eval bar. |
| Deterministic workflow | The sequence of steps is fixed. | The coded path meets the eval bar. |
| Agent | The system must act, or the next step depends on intermediate results and cannot be hardcoded. | One agent meets the eval bar. |
| Multi-agent | One agent cannot cover the roles, and evaluation shows the split is worth the extra failure modes. | — |

Fine-tuning is not the next step after RAG. Use it for stable behavior such as style, tone, or strict format, and only after a strong prompt still fails and you have enough labeled examples. Do not fine-tune to inject knowledge.

A practical way to pick among four methods is the gap you need to close:

- Task guidance: prompting.
- Missing private or current information: RAG.
- Inconsistent behavior or format after strong prompts: fine-tuning.
- Unpredictable multi-step action: an agent. Use a workflow when the path is known.

Many applications need only one model call with retrieval and in-context examples.

---

## 4. RAG: Retrieval-Augmented Generation

### Standard pipeline

```text
Documents
  -> parse and clean
  -> chunk
  -> embed
  -> store in vector database

User question
  -> query embedding
  -> retrieve candidates
  -> optional reranking
  -> build context
  -> generate answer
  -> return citations/sources
```

### Why RAG instead of putting everything in the prompt?

- Context windows are limited and expensive.
- Retrieval focuses the model on relevant information.
- Documents can be updated without retraining the model.
- Access control can be applied during retrieval.
- Sources can be shown to users.

### Production RAG checklist

- Parse PDFs, HTML, Markdown, tables, and scanned documents correctly.
- Preserve metadata: title, source, owner, permissions, version, timestamp.
- Chunk by meaning and document structure, not only fixed character count.
- Use overlap carefully; too much overlap increases cost and duplication.
- Store the source document's access control on every chunk. Enforce it again at retrieval, not only at ingestion.
- Combine semantic search with keyword/BM25 search when useful.
- Rerank candidates when initial retrieval returns noisy results.
- Require citations or source references for factual answers.
- Say “I don’t know” when evidence is insufficient.
- Re-index changed documents and remove stale versions.
- Evaluate retrieval separately from answer generation.

### RAG vs fine-tuning

| Use RAG when | Use fine-tuning when |
|---|---|
| Knowledge changes, or is private or unknown until query time | You need stable style, tone, or strict format |
| Answers require citations | A strong prompt and examples still fail |
| You need permission-aware retrieval | You have enough labeled examples of that behavior |
| You need to add or update knowledge | Not for injecting knowledge |

They can be combined: RAG supplies current knowledge; fine-tuning shapes behavior. Prefer RAG over fine-tuning when the gap is knowledge.

---

## 5. Embeddings and Vector Search

### What is an embedding?

An embedding is a numerical vector representing the meaning or features of text, images, code, or other data. Similar items should be close together in vector space.

### Semantic search flow

```text
text -> embedding model -> vector -> nearest-neighbor search -> similar content
```

### Similarity

Cosine similarity compares the angle between vectors. Higher similarity generally means more semantic relatedness, but the threshold must be calibrated on real examples.

### Choosing an embedding model

Consider:

- Language coverage
- Domain vocabulary
- Search quality on representative queries
- Vector dimensions and storage cost
- Latency and throughput
- Hosted vs local deployment
- Privacy and data residency
- Version stability and migration cost

Do not choose based only on benchmark scores. Test it on your own golden dataset.

---

## 6. Agents vs Workflows

### Deterministic workflow

Use when the sequence is known and transitions are predictable:

```text
retrieve -> validate -> process -> save
```

### Agent

Use when the system must dynamically decide what to do next:

```text
goal -> choose tool -> observe result -> decide next action -> repeat -> finish
```

### Engineering rule

> Prefer a deterministic workflow. Add agentic behavior only when dynamic decision-making creates enough value to justify the additional risk, cost, latency, and testing difficulty.

### Agent design checklist

- Define the goal and termination condition.
- Limit available tools.
- Limit steps, time, and budget.
- Persist state intentionally; do not assume memory is free.
- Validate every tool call and result.
- Check tool authorization in application code outside the model. Unknown tools and missing approvals fail closed.
- Require human approval for high-impact or irreversible actions. Review medium, high, critical, and unmapped tools. If that approval cannot be validated, fail closed.
- Log decisions and tool interactions.
- Handle loops, retries, partial failure, and cancellation.
- Run structured adversarial tests before production and after material changes. Block a release when a high-risk tool, approval, or credential change has no updated tests.

---

## 7. Tool and Function Calling

A reliable tool call needs:

1. A precise schema.
2. Input validation.
3. Authorization checked outside the model, in the code that executes the tool.
4. Permission checks for the current user. Unknown tools and missing approvals fail closed.
5. Timeouts.
6. Bounded retries with backoff.
7. Idempotency for retried write operations.
8. Validation of the tool result.
9. Safe handling of malformed or adversarial output.
10. Clear error messages the model can act on.

Never let the model invent a successful result. The application should return the real tool result or an explicit failure.

---

## 8. Evaluation

### Offline evaluation

Create a golden dataset containing representative requests, expected outcomes, relevant documents, and known edge cases.

Measure:

- Retrieval recall and precision
- Reranker quality
- Answer correctness
- Groundedness/faithfulness
- Citation accuracy
- Hallucination rate
- Tool-call accuracy
- Structured-output validity
- Task completion rate
- Safety/policy compliance

### Online evaluation

Monitor:

- User feedback
- Task success
- Escalation/fallback rate
- Latency percentiles
- Token usage
- Cost per request
- Error and timeout rate
- Model/version changes
- Drift in query and document distribution

Use A/B tests or controlled rollouts for meaningful changes. Manual testing is useful for discovery, but it is not an evaluation strategy by itself.

---

## 9. Production Reliability

Plan for failure:

- Timeouts for every external call
- Exponential backoff with bounded retries
- Fallback models or deterministic paths
- Rate-limit handling and request queues
- Caching for repeated, safe requests
- Streaming for long responses
- Circuit breakers for failing dependencies
- Idempotency for writes
- Graceful degradation
- Correlation IDs and traceability
- Prompt, model, tool, and configuration version tracking
- Per-tenant limits on tokens, requests, concurrency, and spend
- Limits on recursion, retries, and chain depth
- A kill switch for cost or tool calls
- Near-real-time alerts on token use and spend

A useful answer structure:

> “I would start with the simplest reliable path, define failure boundaries, add observability, and then optimize latency and cost based on measurements.”

---

## 10. Security

Key threats:

- Prompt injection from users or retrieved documents
- Sensitive-data leakage
- PII exposure in prompts, logs, or traces
- Excessive tool permissions
- Data poisoning
- Insecure generated code or queries
- Cross-tenant retrieval
- Model output used without validation

Defenses:

- Treat user input and retrieved content as untrusted data.
- Separate instructions from data.
- Apply authorization before retrieval and tool execution.
- Use least-privilege tools and scoped credentials.
- Validate generated SQL, code, JSON, and API parameters.
- Redact sensitive values from logs.
- Test adversarial prompts and malicious documents before production and after material changes. Run those tests in CI.
- Require confirmation for irreversible or high-impact actions. If the approval cannot be validated, fail closed.
- Treat a guardrail model as an extra layer only. It does not replace input validation, structured prompts, least-privilege tools, or human approval for destructive actions.

---

## 11. Model Selection

Choose based on the task, not brand preference:

```text
quality needs
+ latency budget
+ cost budget
+ privacy/deployment constraints
+ tool/structured-output support
+ reliability and availability
```

Use a large model when the task is complex or ambiguity is costly. Use a smaller model when the task is repetitive, well-defined, high-volume, or latency-sensitive.

Hosted models usually provide easier operations and stronger capabilities. Local/open models may improve privacy, cost control, and deployment flexibility, but add infrastructure and quality trade-offs.

Benchmark candidate models on the same representative dataset.

---

## 12. Tool-Grounded Travel Assistant Architecture

### User request

> “Find me the cheapest way from one city to another next weekend.”

### Strong architecture

```text
User
  -> LLM extracts intent and structured parameters
  -> validate dates, locations, passengers, constraints
  -> call authoritative travel/search APIs
  -> receive real inventory, routes, availability, and prices
  -> apply deterministic filters/ranking
  -> LLM explains and formats the verified options
  -> user receives bookable results and sources
```

The LLM handles natural language and orchestration. The travel APIs remain the source of truth for prices, availability, and routes.

### Safeguards

- Structured tool calls
- Schema and business-rule validation
- No invented routes or prices
- API timeouts and retries
- Latency budgets
- Caching where freshness allows
- Clear handling of unavailable or stale results
- Evaluation against real travel queries
- Confirmation before booking or other irreversible actions

---

## 13. Internal Policy Assistant Architecture

For thousands of company policy documents:

```text
ingest -> parse -> chunk -> metadata + permissions -> embed -> index
question -> authorize -> retrieve -> rerank -> answer with citations
```

Discuss:

- Document ownership and update propagation
- Access control stored on every chunk and enforced again at retrieval
- Tenant isolation
- Versioning and stale content
- Retrieval quality and evaluation datasets
- Citation and groundedness requirements
- “No answer found” behavior
- Monitoring, caching, latency, and cost
- PII and prompt-injection defenses

---

## 14. Project Story Template

Prepare 2–3 real projects using:

```text
Problem
-> Why AI was appropriate
-> Architecture
-> Model and data/tools
-> Implementation
-> Evaluation
-> Hardest challenge
-> Result
-> What I would change today
```

Keep claims precise. A defensible positioning statement:

> “My production engineering background comes from building and scaling full-stack systems, cloud infrastructure, and reliable services. My applied-AI experience has grown through recent projects using LLMs, RAG, agents, and AI-assisted development. I approach AI as a production system that needs measurable quality, reliability, security, and cost control.”

---

## 15. Rapid Interview Answers

### How do you reduce hallucinations?

Use authoritative retrieval, clear instructions, structured outputs, citations, confidence/abstention behavior, tool grounding, validation, and evaluation against a golden dataset. Monitor production feedback and investigate failures.

### What is tool calling?

The model selects a declared function and produces structured arguments. The application validates permissions and inputs, executes the function, validates the result, and returns the real output to the model.

### What makes an agent different from a chatbot?

A chatbot mainly generates responses. An agent can choose tools, take actions, observe results, maintain state, and continue until a goal or stopping condition is reached.

### Why not use agents everywhere?

Agents add nondeterminism, latency, cost, security risk, and testing complexity. Start with prompting. Use long context when the context is known and fits. Use RAG when the context is private, current, or unknown until query time. Use a workflow when the path is fixed. Use an agent only when the next step cannot be hardcoded. Use fine-tuning for style or format, not to add knowledge.

### How do you handle prompt injection?

Treat all external content as untrusted, separate instructions from data, restrict tools and permissions, validate outputs, avoid exposing secrets, and test malicious user and retrieved-document inputs. A guardrail model is only an extra check.

### How do you evaluate an LLM application?

Use a representative golden dataset for offline metrics such as retrieval quality, correctness, groundedness, tool accuracy, and task completion. Add online monitoring for feedback, latency, cost, failures, and drift. Block a release when a high-risk tool, approval, or credential change has no updated adversarial tests.

### How do you manage latency and cost?

Use smaller models for simple tasks, limit context, retrieve only relevant data, cache safe repeated work, stream responses, parallelize independent calls, set budgets/timeouts, and measure before optimizing.

---

## 16. High-Value Questions to Practice

1. Explain RAG. Why not put everything in the context window?
2. RAG vs fine-tuning: when would you use each?
3. What are embeddings and vector databases?
4. How would you reduce hallucinations?
5. How do you evaluate an LLM application?
6. What is tool/function calling?
7. What makes an agent different from a chatbot?
8. Agent vs deterministic workflow?
9. How do you handle prompt injection?
10. How do you manage LLM latency and cost?
11. How do you choose between hosted and open-source models?
12. How do you implement retries and fallbacks?
13. How do you make structured output reliable?
14. How would you build a production RAG application?
15. Tell me about an AI system you built.
16. What was the hardest problem?
17. How did you evaluate it?
18. What would you change if you rebuilt it today?

---

## 17. One-Night Preparation Plan

### Hour 1: RAG fundamentals

- RAG pipeline
- Chunking, metadata, and chunk-level access control
- Embeddings and vector search
- Reranking
- Hallucination reduction
- Policy-assistant architecture

### Hour 2: Production AI

- Simplest-technique ladder: prompt, long context, RAG, workflow, agent
- Agents vs workflows
- Tool calling and structured output
- Evaluation
- Security and prompt injection
- Reliability, spend limits, latency, and cost

### Hour 3: Rehearsal

- Prepare 2–3 project stories
- Rehearse the travel-assistant architecture
- Answer the 18 questions aloud
- Spend the final 20–30 minutes speaking, not reading

---

## Final Positioning

Do not present yourself as an ML researcher if that is not your background.

Your differentiator is:

> Production software engineering + system design + cloud/infrastructure + practical applied AI.

Frame AI problems as systems that must work reliably in production. That means authoritative data, bounded model behavior, measurable quality, security, observability, and sensible cost.

---

## Sources

Checked 2026-10-07. These pages informed the technique ladder and the production controls above. They do not share one numeric threshold for switching methods, and no single page states one combined mandatory set.

- [Towards AI engineering playbook](https://github.com/louisfb01/ai-engineering-cheatsheets/blob/main/AI_Engineering_Playbook.md) — simpler-first order. Its context-size and tool-count cutoffs are not repeated by the other pages here, so this sheet does not use them.
- [What We've Learned From A Year of Building with LLMs](https://applied-llms.org/) — prototype with prompting; prefer RAG for new knowledge.
- [Building effective agents](https://www.anthropic.com/engineering/building-effective-agents) — one call when it is enough; a workflow when the path is known; an agent when the step count cannot be hardcoded.
- [From Prompt to Production](https://builder.aws.com/content/3JJrLZnjtr2acv0fIZxNC2hjsmJ/from-prompt-to-production-choosing-prompt-engineering-rag-fine-tuning-and-agents) — one author’s gap test. It is not an AWS standard.
- [OWASP AI Agent Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/AI_Agent_Security_Cheat_Sheet.html) — authorization outside the agent, fail closed, human approval, adversarial tests.
- [OWASP Secure AI Model Ops Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secure_AI_Model_Ops_Cheat_Sheet.html) — per-tenant limits, kill switch, spend alerts.
- [OWASP LLM Prompt Injection Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/LLM_Prompt_Injection_Prevention_Cheat_Sheet.html) — a guardrail model is only an extra layer.
- [OWASP RAG Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/RAG_Security_Cheat_Sheet.html) — access control on every chunk, enforced again at retrieval.
