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

## 3. RAG: Retrieval-Augmented Generation

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
- Filter by user permissions before or during retrieval.
- Combine semantic search with keyword/BM25 search when useful.
- Rerank candidates when initial retrieval returns noisy results.
- Require citations or source references for factual answers.
- Say “I don’t know” when evidence is insufficient.
- Re-index changed documents and remove stale versions.
- Evaluate retrieval separately from answer generation.

### RAG vs fine-tuning

| Use RAG when | Use fine-tuning when |
|---|---|
| Knowledge changes frequently | Behavior/style needs to be learned repeatedly |
| Answers require private or current documents | You need consistent formatting or task behavior |
| Citations and traceability matter | You have high-quality representative training data |
| You need permission-aware retrieval | Prompting and RAG are not sufficient |

They can be combined: RAG supplies current knowledge; fine-tuning shapes behavior.

---

## 4. Embeddings and Vector Search

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

## 5. Agents vs Workflows

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
- Log decisions and tool interactions.
- Handle loops, retries, partial failure, and cancellation.
- Keep humans in the loop for high-impact actions.

---

## 6. Tool and Function Calling

A reliable tool call needs:

1. A precise schema.
2. Input validation.
3. Authentication and authorization.
4. Permission checks for the current user.
5. Timeouts.
6. Bounded retries with backoff.
7. Idempotency for retried write operations.
8. Validation of the tool result.
9. Safe handling of malformed or adversarial output.
10. Clear error messages the model can act on.

Never let the model invent a successful result. The application should return the real tool result or an explicit failure.

---

## 7. Evaluation

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

## 8. Production Reliability

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
- Cost and token budgets

A useful answer structure:

> “I would start with the simplest reliable path, define failure boundaries, add observability, and then optimize latency and cost based on measurements.”

---

## 9. Security

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
- Test adversarial prompts and malicious documents.
- Require confirmation for irreversible or high-impact actions.

---

## 10. Model Selection

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

## 11. Tool-Grounded Travel Assistant Architecture

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

## 12. Internal Policy Assistant Architecture

For thousands of company policy documents:

```text
ingest -> parse -> chunk -> metadata + permissions -> embed -> index
question -> authorize -> retrieve -> rerank -> answer with citations
```

Discuss:

- Document ownership and update propagation
- Access control and tenant isolation
- Versioning and stale content
- Retrieval quality and evaluation datasets
- Citation and groundedness requirements
- “No answer found” behavior
- Monitoring, caching, latency, and cost
- PII and prompt-injection defenses

---

## 13. Project Story Template

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

## 14. Rapid Interview Answers

### How do you reduce hallucinations?

Use authoritative retrieval, clear instructions, structured outputs, citations, confidence/abstention behavior, tool grounding, validation, and evaluation against a golden dataset. Monitor production feedback and investigate failures.

### What is tool calling?

The model selects a declared function and produces structured arguments. The application validates permissions and inputs, executes the function, validates the result, and returns the real output to the model.

### What makes an agent different from a chatbot?

A chatbot mainly generates responses. An agent can choose tools, take actions, observe results, maintain state, and continue until a goal or stopping condition is reached.

### Why not use agents everywhere?

Agents add nondeterminism, latency, cost, security risk, and testing complexity. A deterministic workflow is easier to reason about and operate when the process is known.

### How do you evaluate an LLM application?

Use a representative golden dataset for offline metrics such as retrieval quality, correctness, groundedness, tool accuracy, and task completion. Add online monitoring for feedback, latency, cost, failures, and drift.

### How do you handle prompt injection?

Treat all external content as untrusted, separate instructions from data, restrict tools and permissions, validate outputs, avoid exposing secrets, and test malicious user and retrieved-document inputs.

### How do you manage latency and cost?

Use smaller models for simple tasks, limit context, retrieve only relevant data, cache safe repeated work, stream responses, parallelize independent calls, set budgets/timeouts, and measure before optimizing.

---

## 15. High-Value Questions to Practice

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

## 16. One-Night Preparation Plan

### Hour 1: RAG fundamentals

- RAG pipeline
- Chunking and metadata
- Embeddings and vector search
- Reranking
- Hallucination reduction
- Policy-assistant architecture

### Hour 2: Production AI

- Agents vs workflows
- Tool calling and structured output
- Evaluation
- Security and prompt injection
- Reliability, latency, and cost

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
