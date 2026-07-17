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
