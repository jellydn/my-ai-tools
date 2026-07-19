from pathlib import Path

import pytest

from document_qa.chunking import chunk_document


def test_markdown_chunks_preserve_heading_metadata_and_overlap() -> None:
	text = "# Intro\n" + "alpha beta gamma delta epsilon zeta eta theta iota kappa " * 3
	chunks = chunk_document(text, Path("guide.md"), "markdown", chunk_size=70, overlap=15)

	assert len(chunks) > 1
	assert all(chunk.metadata.heading == "Intro" for chunk in chunks)
	assert [chunk.metadata.chunk_index for chunk in chunks] == list(range(len(chunks)))
	assert all(len(chunk.text) <= 70 for chunk in chunks)
	assert set(chunks[0].text.split()) & set(chunks[1].text.split())


def test_chunking_rejects_invalid_overlap() -> None:
	with pytest.raises(ValueError, match="overlap"):
		chunk_document("text", Path("notes.txt"), "text", chunk_size=10, overlap=10)
