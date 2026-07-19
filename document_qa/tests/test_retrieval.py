from pathlib import Path

from document_qa.models import ChunkMetadata, DocumentChunk, RetrievalFilters
from document_qa.vector_store import FaissVectorStore


def chunk(filename: str, document_type: str, index: int) -> DocumentChunk:
	return DocumentChunk(
		text=f"content for {filename}",
		metadata=ChunkMetadata(
			filename=filename,
			document_path=filename,
			chunk_index=index,
			document_type=document_type,  # type: ignore[arg-type]
		),
	)


def build_store(tmp_path: Path) -> FaissVectorStore:
	store = FaissVectorStore(tmp_path, "test-embedding-model")
	store.build(
		[chunk("guide.md", "markdown", 0), chunk("notes.txt", "text", 0), chunk("manual.pdf", "pdf", 0)],
		[[1.0, 0.0], [0.8, 0.6], [-1.0, 0.0]],
	)
	return store


def test_metadata_filters_apply_before_top_k(tmp_path: Path) -> None:
	store = build_store(tmp_path)

	by_filename = store.search([1.0, 0.0], 2, -1.0, RetrievalFilters(filename="notes.txt"))
	by_type = store.search([1.0, 0.0], 2, -1.0, RetrievalFilters(document_type="pdf"))

	assert [item.metadata.filename for item in by_filename] == ["notes.txt"]
	assert [item.metadata.filename for item in by_type] == ["manual.pdf"]


def test_minimum_relevance_threshold_excludes_low_scores(tmp_path: Path) -> None:
	store = build_store(tmp_path)

	results = store.search([1.0, 0.0], 10, 0.9, RetrievalFilters())

	assert [item.metadata.filename for item in results] == ["guide.md"]
	assert results[0].score >= 0.9


def test_persisted_index_reloads_in_a_new_store(tmp_path: Path) -> None:
	build_store(tmp_path)

	reopened = FaissVectorStore(tmp_path, "test-embedding-model")
	results = reopened.search([1.0, 0.0], 1, 0.9, RetrievalFilters())

	assert [item.metadata.filename for item in results] == ["guide.md"]
