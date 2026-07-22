# 30-Day AI Learning Glossary

Terminology established during the 30-Day AI Learning Journey.

## Terms

**Chunk**:
A small, self-contained segment of text split from a larger document to fit within an embedding model's context window or to localize semantic matches.
_Avoid_: Split, section, slice

**Overlap**:
The number of characters or tokens shared between consecutive chunks, designed to preserve contextual meaning at boundary edges.
_Avoid_: Margin, pad, repeat-count

**Semantic Chunking**:
Splitting documents based on natural semantic boundaries (e.g. Tree-sitter AST nodes, markdown headings, structural layout) rather than arbitrary byte, token, or character limits.
_Avoid_: Fixed-size parsing, hard-splitting

**Vector Embedding**:
A numerical array representing the semantic meaning of a chunk, allowing mathematical similarity calculations.
_Avoid_: Word score, encoding

**RAG (Retrieval-Augmented Generation)**:
A pattern that enhances LLM responses by retrieving relevant documents from an external corpus and injecting them into the prompt before generating the final answer.
_Avoid_: Prompt tuning, direct LLM generation

**Grounding Prompt**:
A system prompt that directs the model to answer questions strictly using the provided context and reject queries unsupported by retrieved facts.
_Avoid_: Alignment prompt, system instruction

**Top-K**:
The number of highest-scoring retrieved document chunks passed as context to the LLM.
_Avoid_: Cutoff size, match count

**Metadata Filtering**:
Applying pre-filters (such as file type, date, or author) to candidates before performing vector similarity search.
_Avoid_: Post-hoc ranking, list sorting

**Reranking**:
Using a secondary, highly precise model (like a Cross-Encoder) to re-evaluate the relevance of a larger pool of retrieved chunks (e.g. Top-20) and select the best few (e.g. Top-5).
_Avoid_: Initial vector search, dot-product scoring

**Prompt Template**:
A reusable prompt structure with placeholders or variables that are dynamically populated with user or context data at runtime.
_Avoid_: Static instruction, raw query

**Prompt Registry**:
A central catalog mapping prompt identifiers and versions to their respective schemas, variables, and render functions.
_Avoid_: Hardcoded message collection, prompt directory

**Short-Term Memory**:
Conversation-scoped state that holds recent messages, context, and transient variables for the duration of a single session.
_Avoid_: Chat history, message buffer

**Long-Term Memory**:
Persistent user preferences and facts stored across sessions and projects, surviving restarts and context window resets.
_Avoid_: Permanent storage, database record

**Explicit Consent Gate**:
A design pattern requiring the user to explicitly state or confirm a preference before it is persisted, preventing inferred or hallucinated memory writes.
_Avoid_: Auto-save, implicit capture

**Audit Trail**:
A value-free append-only log recording which keys were mutated and when, without storing the preference values themselves, for accountability and debugging.
_Avoid_: Change log, history file

**FastAPI**:
A modern, high-performance web framework for building APIs with Python, featuring automatic validation and interactive docs.
_Avoid_: Django API, Flask microservice

**Streamlit**:
An open-source Python framework that allows developers to build interactive frontend UIs and data dashboards in minutes.
_Avoid_: Custom React client, templates-based frontend

**Document Q&A**:
An end-to-end RAG system that ingests document files, indexes their chunks into a vector store, retrieves relevant matches for user queries, and compiles grounded responses with source citations.
_Avoid_: Search engine, simple chat completion

**Agent Loop**:
An execution loop around an LLM that iteratively observes context, decides whether to execute a tool or return a final answer, and reflects on tool results.
_Avoid_: Linear chain, single-shot prompt

**Observe-Act-Reflect**:
The core design pattern of AI agents: Observe inputs and tool outputs, Act by invoking a tool or returning a response, and Reflect on remaining state and safety constraints.
_Avoid_: Uncontrolled generation, static completion

**Step Budget**:
A strict limit on the maximum number of tool execution steps an agent may perform before it must stop and produce a final answer using already-collected evidence.
_Avoid_: Infinite loop, unconstrained recursion

**Bounded Execution**:
Configuring strict step budgets, timeouts, read-only permissions, and sandbox constraints to guarantee that an agent stops safely and cannot run indefinitely.
_Avoid_: Autonomous runaway process, unmonitored loop
