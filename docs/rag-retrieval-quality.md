# Day 11: retrieval quality

This evaluation changes retrieval, not the answer model. The smoke benchmark uses the browser index and the three questions in `scripts/evaluate-retrieval.ts`. Each build is a new point-in-time evaluation: pinning a public source revision does not freeze mutable Issue/PR content. Archive the index if you need to repeat the same corpus. Build from a publicly available revision, then run:

```bash
GITHUB_SOURCE_REF="$(git rev-parse HEAD)" npm run index:browser
npm run eval:retrieval
npm run eval:retrieval -- --check-links
```

“Answer-support rate” is a retrieval-only proxy: at least one human-labeled supporting path was retrieved. It is not an LLM-as-judge score. Prompt tokens are estimated from context characters because the embedding-only benchmark deliberately does not invoke or change the LLM. Provider-reported prompt and response tokens remain available in live `rag_request` logs.

## Top-k trade-offs

Historical measurements on 2,234 chunks with `Xenova/all-MiniLM-L6-v2` (three-question smoke set; ranking latency excludes query embedding and generation). The original index was not archived; these values are not reproducible baseline guarantees:

| top-k | Relevance density | Answer-support rate | Estimated prompt tokens | Retrieval latency |
|---:|---:|---:|---:|---:|
| 3 | 22% | 67% | 529 | 7.57 ms |
| 5 | 40% | 100% | 866 | 5.96 ms |
| 10 | 33% | 100% | 1,818 | 4.78 ms |
| 20 | 40% | 100% | 3,993 | 4.93 ms |

Top 3 missed supporting Pull Request evidence for one question; top 5 was the smallest setting with 100% answer support. Prompt usage grew by 7.5× from top 3 to top 20, while ranking latency stayed within measurement noise because every candidate is scored before slicing. Top 5 therefore remains the default, while 10 and 20 are better treated as future reranker candidate pools than direct prompt input.

## Metadata filtering

`POST /api/chat` accepts an optional filter before vector scoring:

```json
{
  "message": "How do I add an MCP server?",
  "topK": 5,
  "types": ["documentation", "example_config"]
}
```

Supported types are `documentation`, `source`, `issue`, `pull_request`, `cli_help`, and `example_config`. The benchmark compares each example question unfiltered and with these expected filters:

| Question | Suggested filter | Expected trade-off |
|---|---|---|
| How do I add an MCP server? | `documentation`, `example_config` | Removes source and conversation noise, but can hide implementation details. |
| How does the repository chat work? | `documentation`, `source` | Focuses on architecture and implementation; excludes useful historical PR rationale. |
| What changed in recent pull requests? | `pull_request` | Removes nearly all local-corpus noise; intentionally hides docs that summarize landed changes. |

Filters are therefore optional and caller-selected, never inferred as a hard constraint. An empty filtered candidate set returns the grounded abstention instead of falling back silently to unfiltered results.

Measured at top 5:

| Question | Unfiltered relevant/noise | Filtered relevant/noise | Result |
|---|---:|---:|---|
| How do I add an MCP server? | 2/3 | 5/0 | Noise disappeared, but all five filtered chunks came from `README.md`; source diversity needs improvement. |
| How does the repository chat work? | 2/3 | 3/2 | Filtering helped modestly; two broadly related skill chunks remained. |
| What changed in recent pull requests? | 2/3 | 5/0 | The `pull_request` filter produced the clearest gain. |

The MCP filter also hid the useful `wiki/wiki/concepts/mcp-registry.md` source because wiki pages are currently classified as `source`. Filtering removed noise overall but can hide useful cross-type evidence, which is why it is not inferred automatically.

## Retrieval trace validation

- GitHub Issues and Pull Requests retain their canonical API-provided URL.
- Source files come from an anonymous public checkout selected by `GITHUB_SOURCE_REF`; links use its resolved commit SHA.
- The benchmark checks URLs in the unfiltered top-five retrieval traces, not every indexed URL, and warns when the index is older than 24 hours. `--check-links` also issues bounded HTTP `HEAD` requests and reports failures without aborting the local evaluation.
- Retrieved sources remain a retrieval trace, not claim-level citation proof. Users must be able to open the source and verify the answer.

## Degraded retrieval policy

| Scenario | Index/build behavior | Deployment/user behavior |
|---|---|---|
| GitHub Issue/PR API unavailable | Continue with the public checkout and a warning. | Chat remains available; Issue/PR questions may abstain. |
| Public checkout unavailable or private | Fail indexing without consulting credentials or local files. | Keep the last published index; do not publish private data. |
| Empty GitHub corpus | Continue if local chunks exist and report zero GitHub documents. | Conversation filters return the grounded abstention. |
| Empty full corpus | Fail indexing and deployment. | Do not serve a knowingly empty knowledge base. |
| Stale index | A compatible index remains usable. The evaluation script warns when it is older than 24 hours; the server has no automatic age alert. | Rebuild explicitly; an age indicator and production alerts remain future work. |
| Embedding model/dimension mismatch | Reject retrieval and require a rebuild. | Return HTTP 500 with a generic retrieval error; log `retrieval_failed` without sensitive input. |

This separates optional remote enrichment from required local grounding. A stale but compatible index is usually better than no service; an incompatible index is unsafe because its similarity scores are meaningless.

## Observability review

The old logs included raw questions, which can contain secrets or private text. Server logs now contain question length, top-k, active type filters, retrieved path/type/score, retrieval latency, provider token counts, total latency, and failure stage. Browser diagnostics also include source authors. They do not contain raw prompts, prompt hashes, chunk text, embeddings, API tokens, or credentials. Index generation already reports corpus counts; a production metrics backend should aggregate corpus age/counts and retrieval latency without adding user text.

Unsalted prompt hashing was rejected because common questions can be guessed offline. If correlation later becomes necessary, server logs should use a dedicated, rotatable HMAC key; browser logs should remain uncorrelated. Access controls, short retention, and secret scanning/redaction at the log sink remain necessary.

## Production improvement proposal (design only)

1. **Hybrid BM25 + vector search:** union lexical and semantic candidates so exact commands, filenames, and acronyms are not lost when embedding similarity is weak. Retrieve about 20 candidates.
2. **Metadata pre-filtering:** already implemented for type; extend to path, author, state, branch, and time windows so scoring starts with the right corpus slice.
3. **Cross-encoder reranking:** jointly score the query and each of the 20 candidates, then send only the best five. This should improve relevance density without paying top-20 prompt cost.
4. **Content-hash embedding cache:** key embeddings by model plus normalized content hash. Unchanged chunks avoid paid, variable re-embedding and make experiments faster and reproducible.
5. **Incremental indexing:** update only changed files and GitHub records, while atomically publishing a versioned index. This reduces staleness and rebuild time.
6. **Retrieval evaluation benchmark:** grow the current three smoke questions into reviewed relevance judgments with Recall@k, MRR/nDCG, filter false-negative rate, abstention accuracy, token usage, and latency gates in CI.

The next implementation should be hybrid top-20 retrieval followed by reranking to five, but only after the benchmark has enough labeled queries to prove the extra complexity and latency improve quality.

## Learning notes

1. The largest answer-quality issue was irrelevant document types crowding a small top-k, especially broad queries about recent Pull Requests.
2. Metadata pre-filtering gave the biggest targeted gain because it removed noise before scoring without changing embeddings or the LLM.
3. Hybrid retrieval plus reranking is next: lexical search recovers exact repository vocabulary, while reranking preserves a compact, high-quality prompt.
