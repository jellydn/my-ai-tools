from __future__ import annotations

import logging
from pathlib import Path

from pypdf import PdfReader
from pypdf.errors import PyPdfError

from document_qa.chunking import chunk_document
from document_qa.models import DocumentChunk, DocumentInfo, document_type_for_path

logger = logging.getLogger(__name__)
SUPPORTED_EXTENSIONS = {".md", ".txt", ".pdf"}


def list_documents(root: Path) -> list[DocumentInfo]:
	root.mkdir(parents=True, exist_ok=True)
	documents = []
	for path in sorted(root.rglob("*")):
		if path.is_file() and path.suffix.lower() in SUPPORTED_EXTENSIONS:
			documents.append(
				DocumentInfo(filename=path.name, path=str(path.relative_to(root)), document_type=document_type_for_path(path))
			)
	return documents


def load_text(path: Path) -> str:
	document_type = document_type_for_path(path)
	try:
		if document_type == "pdf":
			reader = PdfReader(path)
			return "\n\n".join(page.extract_text() or "" for page in reader.pages).strip()
		return path.read_text(encoding="utf-8")
	except (OSError, UnicodeError, ValueError, PyPdfError) as exc:
		raise ValueError(f"Could not read {path.name}: {exc}") from exc


def load_and_chunk(path: Path, source_path: Path, chunk_size: int, overlap: int) -> list[DocumentChunk]:
	text = load_text(path)
	if not text.strip():
		logger.warning("document_has_no_extractable_text", extra={"document_path": str(path)})
		return []
	return chunk_document(text, source_path, document_type_for_path(path), chunk_size, overlap)
