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
