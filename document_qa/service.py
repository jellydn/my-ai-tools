from __future__ import annotations

import logging
from pathlib import Path

from document_qa.config import Settings
from document_qa.documents import load_and_chunk
from document_qa.embeddings import Embedder
from document_qa.models import IndexResponse
from document_qa.vector_store import FaissVectorStore

logger = logging.getLogger(__name__)


class IndexingService:
	def __init__(self, settings: Settings, embedder: Embedder, store: FaissVectorStore) -> None:
		self._settings = settings
		self._embedder = embedder
		self._store = store

	def rebuild(self, relative_paths: list[str]) -> IndexResponse:
		if not relative_paths:
			raise ValueError("Select at least one document to index")
		paths = [self._safe_document_path(path) for path in relative_paths]
		chunks = []
		for path in paths:
			chunks.extend(
				load_and_chunk(
					path,
					path.relative_to(self._settings.documents_dir),
					self._settings.chunk_size,
					self._settings.chunk_overlap,
				)
			)
		if not chunks:
			raise ValueError("The selected documents contain no extractable text")
		logger.info("embedding_chunks", extra={"document_count": len(paths), "chunk_count": len(chunks)})
		embeddings = self._embedder.embed([chunk.text for chunk in chunks])
		self._store.build(chunks, embeddings)
		return IndexResponse(documents_indexed=len(paths), chunks_indexed=len(chunks))

	def _safe_document_path(self, relative_path: str) -> Path:
		root = self._settings.documents_dir
		path = (root / relative_path).resolve()
		if path == root or root not in path.parents:
			raise ValueError(f"Document path is outside the documents directory: {relative_path}")
		if not path.is_file():
			raise ValueError(f"Document does not exist: {relative_path}")
		return path
