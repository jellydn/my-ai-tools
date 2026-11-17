# Local Document Q&A

A small, local-first retrieval-augmented generation application built with FastAPI, Streamlit, OpenAI, and FAISS. It indexes selected Markdown, plain-text, and PDF files and answers only from retrieved chunks.

## Setup

Python 3.11+ is recommended.

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r document_qa/requirements.txt
export OPENAI_API_KEY="..."
# Optional for OpenAI-compatible providers:
export OPENAI_BASE_URL="https://api.openai.com/v1"
export OPENAI_MODEL="gpt-4o-mini"
export OPENAI_EMBEDDING_MODEL="text-embedding-3-small"
mkdir -p document_qa/documents
```

Put `.md`, `.txt`, and `.pdf` files in `document_qa/documents/`, or upload them from the UI. Then run the backend and UI in separate terminals:

```bash
uvicorn document_qa.api:app --reload
streamlit run document_qa/streamlit_app.py
```

Open the Streamlit URL, select documents, click **Rebuild index**, and ask a question. The REST API docs are available at `http://127.0.0.1:8000/docs`.

### Test with OpenRouter free models

[OpenRouter's free-model collection](https://openrouter.ai/collections/free-models) contains chat/generation models. Embeddings use a separate embedding-capable model. The following configuration uses OpenRouter's free chat router and a free NVIDIA embedding model:

```bash
export OPENROUTER_API_KEY="..."
export OPENAI_API_KEY="$OPENROUTER_API_KEY"
export OPENAI_BASE_URL="https://openrouter.ai/api/v1"
export OPENAI_MODEL="openrouter/free"
export OPENAI_EMBEDDING_MODEL="nvidia/nemotron-3-embed-1b:free"

mkdir -p document_qa/documents
cp document_qa/README.md document_qa/documents/sample.md
uvicorn document_qa.api:app --reload
```

In another terminal, preserving the same environment variables:

```bash
streamlit run document_qa/streamlit_app.py
```

In the UI, select `sample.md`, rebuild the index, and try “What are this application's limitations?” Verify that the answer contains source labels such as `[sample.md#chunk-N]` and that the retrieved-chunk panel shows scores and previews. Raising the minimum relevance above the returned scores should produce the explicit insufficient-context response.

`openrouter/free` randomly selects an available free chat model, so instruction-following quality and latency can vary. Select a specific current `:free` model from the collection when reproducibility matters. Free model availability and rate limits change; verify the current [free chat models](https://openrouter.ai/collections/free-models) and [embedding models](https://openrouter.ai/models?fmt=cards&output_modalities=embeddings) before testing. Some free providers may log prompts or use them for model improvement, so use non-sensitive test documents and review the selected provider's data policy. Rebuild the FAISS index whenever `OPENAI_EMBEDDING_MODEL` changes.

## Architecture

```text
Markdown / text / PDF
        │
        ▼
loader → heading-aware overlapping chunks → OpenAI embeddings → local FAISS index
                                                                    │
question → OpenAI query embedding → filtered/threshold retrieval ───┘
                                      │
                                      ▼
                         grounded answer + citations
```

- `chunking.py` splits text by natural boundaries and records filename, path, chunk index, type, and Markdown heading.
- `documents.py` loads UTF-8 text/Markdown and extracts PDF text with `pypdf`.
- `vector_store.py` atomically publishes a normalized inner-product FAISS generation plus JSON metadata.
- `retrieval.py` is independent from generation and applies `top_k`, filename/type filters, and minimum relevance.
- `answering.py` sends only retrieved source text to the chat model and requires `[document/path#chunk-N]` citations.
- `api.py` exposes document, indexing, retrieval, and answering endpoints; `streamlit_app.py` is the UI client.

## Configuration

| Environment variable | Default | Purpose |
| --- | --- | --- |
| `OPENAI_API_KEY` | required | OpenAI-compatible API key |
| `OPENAI_BASE_URL` | OpenAI | Optional compatible endpoint |
| `OPENAI_MODEL` | `gpt-4o-mini` | Answer model |
| `OPENAI_EMBEDDING_MODEL` | `text-embedding-3-small` | Embedding model |
| `DOCUMENT_QA_DOCUMENTS_DIR` | `document_qa/documents` | Allowed local/upload directory |
| `DOCUMENT_QA_INDEX_DIR` | `document_qa/data` | FAISS and metadata directory |
| `DOCUMENT_QA_CHUNK_SIZE` | `1000` | Maximum chunk characters |
| `DOCUMENT_QA_CHUNK_OVERLAP` | `200` | Overlapping characters |
| `DOCUMENT_QA_TOP_K` | `5` | API-side default top K |
| `DOCUMENT_QA_MIN_RELEVANCE` | `0.25` | Minimum cosine similarity |
| `DOCUMENT_QA_MAX_UPLOAD_MB` | `20` | Per-file upload limit |
| `DOCUMENT_QA_LOG_LEVEL` | `INFO` | Backend log level |
| `DOCUMENT_QA_API_URL` | `http://127.0.0.1:8000` | Backend URL used by Streamlit |

Changing embedding models usually changes vector dimensions; rebuild the index after any embedding model change.

## API and tests

```bash
# Retrieve only (does not invoke the chat model)
curl -s http://127.0.0.1:8000/retrieve \
  -H 'content-type: application/json' \
  -d '{"question":"What is the setup process?","top_k":5,"min_relevance":0.3,"filters":{"document_type":"markdown"}}'

# Unit tests do not call OpenAI
python -m pytest document_qa/tests
```

Sample questions:

- “Summarize the installation steps and cite each source.”
- “What limitations are documented?”
- “How does the configuration differ between these documents?”

## Limitations

- This is a single-user local application: it has no authentication or multi-tenant isolation.
- PDF extraction handles embedded text, not scanned images/OCR, tables, or complex layouts.
- Chunk sizes are characters rather than model tokens; headings are available only for Markdown.
- Rebuilding replaces the complete index and incurs embedding API cost. Uploaded files overwrite same-named files.
- Similarity scores are cosine similarities after vector normalization; useful thresholds vary by embedding model and corpus.
- Answers with missing or unknown citation labels fail closed to the insufficiency response. Source previews keep accepted answers auditable.
