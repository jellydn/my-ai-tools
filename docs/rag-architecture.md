# Repository RAG architecture

The repository assistant uses this repository as its knowledge base. It intentionally does not use LangChain so retrieval, grounding, and prompt construction remain visible and explainable.

```text
Repository + GitHub Issues/PRs
            │
            ▼
       Document loader
            │
            ▼
  1,000 character chunks
    (150 character overlap)
            │
            ▼
 OpenAI-compatible embeddings
            │
            ▼
 In-image vector index (JSON)
            │
            ▼
 Cosine retriever + metadata filter
            │
            ▼
 Grounding prompt policy
            │
            ▼
OpenRouter + retrieval trace
```

## Indexed data

- `README.md`, `docs/`, and any `CHANGELOG*` or `SOUL.md` file
- CLI implementation and help in `cli.sh` and `generate.sh`
- supported TypeScript, JavaScript, Markdown, shell, PowerShell, JSON/JSONC, YAML, and TOML files
- example configs under `configs/`
- up to 100 recent GitHub Issues and 100 recent Pull Requests, fetched when the index is built; each type is capped at 200 chunks and every included item keeps a summary chunk before extra body chunks are selected

Generated indexes, dependencies, caches, secrets, credentials, and repository metadata are excluded. Local files are limited to 1 MiB each, 20 MiB total input, and 5,000 chunks so an accidental generated file cannot produce an unbounded image. GitHub fetch failure is non-fatal so local and Fly builds remain possible during a GitHub outage. Use `GITHUB_TOKEN` to raise the API rate limit and `GITHUB_REPOSITORY=owner/repo` when indexing a fork.

GitHub entries contain bounded title, state, author, and body excerpts. They do not include comments, reviews, changed-file diffs, or the complete conversation.

Each chunk stores a source path and metadata:

```ts
type ChunkMetadata = {
  type: "documentation" | "issue" | "pull_request" | "cli_help" | "example_config" | "source";
  author?: string;
  url?: string;
};
```

This supports pre-filtering by document type without changing the index schema. Path and author filters remain future extensions.

## Retrieval and grounding

The server embeds the question with the same model used at index time, optionally filters candidates by document type, calculates cosine similarity, and sends the requested top 3, 5, 10, or 20 chunks to the answer model. Top 5 remains the default. The prompt treats excerpts as untrusted data, requires answers to use only those excerpts, cite relevant paths, and return `This is not documented in the repository.` when the evidence is insufficient. The UI appends deduplicated links for the retrieved sources, including direct links for Issues and Pull Requests. Local-file links use `GITHUB_SOURCE_REF`; deployments should pass the indexed commit SHA as a Docker build argument so links do not silently drift with `main`. These links are a retrieval trace rather than a claim-level citation validator.

The JSON vector index is an intentional first production step: the corpus fits in one Fly machine image, deployment is stateless, and there is no external database to operate. pgvector becomes appropriate when the corpus or update frequency makes rebuilding the image too slow, or when multiple application instances need incremental index updates.

## Observability

Server mode emits one JSON log per accepted request:

```json
{
  "event": "rag_request",
  "questionLength": 27,
  "topK": 5,
  "filters": { "types": ["documentation", "example_config"] },
  "retrievedChunks": [{ "path": "README.md", "type": "documentation", "score": 0.8123 }],
  "retrievalLatencyMs": 18,
  "promptTokens": 1420,
  "responseTokens": 186,
  "latencyMs": 934
}
```

Failures include an `error` stage. Token counts are `null` if an OpenAI-compatible provider does not report streaming usage. Browser mode logs equivalent retrieval and timing details to the browser console.

These logs make it possible to inspect poor retrieval, compare settings, and track latency/cost without logging raw questions, prompt hashes, embeddings, or API credentials. Production log retention and access controls are still required.

## Production roadmap

1. Add filter controls to the chat UI and extend filtering to path and author.
2. Add BM25 retrieval, merge it with vector results, and retrieve an initial top 20.
3. Rerank those 20 candidates down to the five chunks sent to the model.
4. Move vectors to pgvector when incremental updates or horizontal scaling justify the operational cost.
5. Cache unchanged document embeddings by content hash and cache short-lived retrieval results.
6. Re-embed changed documents after repository updates and rebuild everything after an embedding-model upgrade.

Chunk size is a relevance tradeoff: very small chunks lose surrounding meaning, while very large chunks dilute matches and consume prompt tokens. A 150-character overlap (15% of the target size) preserves text that crosses boundaries. Metadata narrows irrelevant candidates, hybrid search improves exact command and filename matching, reranking improves final context quality, and citations let users verify the answer instead of trusting model memory.

## Learning notes

1. Retrieval quality depends more on chunking, metadata, and retrieval strategy than on the answer model itself.
2. A grounded RAG system should answer only from retrieved context and provide source citations instead of relying on model memory.
3. Production RAG benefits from hybrid search, reranking, and observability—retrieved chunks, similarity scores, latency, and token usage—to improve accuracy and debuggability.
