from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path

from document_qa.models import ChunkMetadata, DocumentChunk, DocumentType

HEADING_PATTERN = re.compile(r"^(#{1,6})\s+(.+?)\s*$", re.MULTILINE)


@dataclass(frozen=True)
class TextSection:
	text: str
	heading: str | None


def _split_text(text: str, chunk_size: int, overlap: int) -> list[str]:
	normalized = text.replace("\r\n", "\n").strip()
	if not normalized:
		return []

	chunks: list[str] = []
	start = 0
	while start < len(normalized):
		end = min(start + chunk_size, len(normalized))
		if end < len(normalized):
			paragraph_break = normalized.rfind("\n\n", start, end)
			line_break = normalized.rfind("\n", start, end)
			word_break = normalized.rfind(" ", start, end)
			best_break = max(paragraph_break + 2 if paragraph_break >= start else -1, line_break + 1, word_break + 1)
			if best_break > start:
				end = best_break
		chunk = normalized[start:end].strip()
		if chunk:
			chunks.append(chunk)
		if end == len(normalized):
			break
		start = max(end - overlap, start + 1)
	return chunks


def _markdown_sections(text: str) -> list[TextSection]:
	matches = list(HEADING_PATTERN.finditer(text))
	if not matches:
		return [TextSection(text=text, heading=None)]

	sections: list[TextSection] = []
	if text[: matches[0].start()].strip():
		sections.append(TextSection(text=text[: matches[0].start()], heading=None))
	for index, match in enumerate(matches):
		end = matches[index + 1].start() if index + 1 < len(matches) else len(text)
		sections.append(TextSection(text=text[match.start() : end], heading=match.group(2).strip()))
	return sections


def chunk_document(
	text: str,
	path: Path,
	document_type: DocumentType,
	chunk_size: int,
	overlap: int,
) -> list[DocumentChunk]:
	if chunk_size <= 0 or not 0 <= overlap < chunk_size:
		raise ValueError("chunk_size must be positive and overlap must be between zero and chunk_size")
	sections = _markdown_sections(text) if document_type == "markdown" else [TextSection(text, None)]
	chunks: list[DocumentChunk] = []
	for section in sections:
		for chunk_text in _split_text(section.text, chunk_size, overlap):
			chunks.append(
				DocumentChunk(
					text=chunk_text,
					metadata=ChunkMetadata(
						filename=path.name,
						document_path=path.as_posix(),
						chunk_index=len(chunks),
						document_type=document_type,
						heading=section.heading,
					),
				)
			)
	return chunks
