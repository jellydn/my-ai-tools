from document_qa.answering import INSUFFICIENT_ANSWER, format_citation, unique_citations, validate_citations
from document_qa.models import ChunkMetadata, RetrievedChunk


def retrieved(filename: str, index: int) -> RetrievedChunk:
	return RetrievedChunk(
		text="source text",
		score=0.9,
		metadata=ChunkMetadata(
			filename=filename,
			document_path=filename,
			chunk_index=index,
			document_type="markdown",
		),
	)


def test_citation_format_includes_filename_and_chunk_index() -> None:
	assert format_citation(retrieved("guide.md", 7)) == "[guide.md#chunk-7]"


def test_unique_citations_preserve_retrieval_order() -> None:
	first = retrieved("guide.md", 1)
	assert unique_citations([first, retrieved("notes.md", 2), first]) == [
		"[guide.md#chunk-1]",
		"[notes.md#chunk-2]",
	]


def test_citation_validation_fails_closed_for_missing_or_unknown_sources() -> None:
	chunks = [retrieved("guide.md", 1)]
	assert validate_citations("An answer without a citation.", chunks) == (INSUFFICIENT_ANSWER, [])
	assert validate_citations("Claim [unknown.md#chunk-9]", chunks) == (INSUFFICIENT_ANSWER, [])


def test_citation_validation_returns_only_citations_used_in_answer() -> None:
	chunks = [retrieved("guide.md", 1), retrieved("notes.md", 2)]
	answer = "The guide supports this. [guide.md#chunk-1]"

	assert validate_citations(answer, chunks) == (answer, ["[guide.md#chunk-1]"])
