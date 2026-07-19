from __future__ import annotations

import json
import logging
import os
import threading
import uuid
from pathlib import Path

import faiss
import numpy as np

from document_qa.models import DocumentChunk, RetrievalFilters, RetrievedChunk

logger = logging.getLogger(__name__)
_BUILD_LOCK = threading.Lock()


class FaissVectorStore:
	def __init__(self, directory: Path, embedding_model: str) -> None:
		self.directory = directory
		self.manifest_path = directory / "current.json"
		self.embedding_model = embedding_model
		self._index: faiss.Index | None = None
		self._chunks: list[DocumentChunk] = []
		self._lock = threading.RLock()

	@property
	def size(self) -> int:
		self._ensure_loaded()
		return len(self._chunks)

	def build(self, chunks: list[DocumentChunk], embeddings: list[list[float]]) -> None:
		if not chunks:
			raise ValueError("No non-empty document chunks were found")
		if len(chunks) != len(embeddings):
			raise ValueError("Each chunk must have exactly one embedding")
		vectors = np.asarray(embeddings, dtype="float32")
		if vectors.ndim != 2 or vectors.shape[1] == 0:
			raise ValueError("Embeddings must be a non-empty two-dimensional array")
		faiss.normalize_L2(vectors)
		index = faiss.IndexFlatIP(vectors.shape[1])
		index.add(vectors)

		self.directory.mkdir(parents=True, exist_ok=True)
		generation = uuid.uuid4().hex
		index_path = self.directory / f"{generation}.faiss"
		metadata_path = self.directory / f"{generation}.json"
		manifest = {
			"version": 1,
			"generation": generation,
			"embedding_model": self.embedding_model,
			"dimension": vectors.shape[1],
			"count": len(chunks),
		}
		with _BUILD_LOCK:
			faiss.write_index(index, str(index_path))
			metadata_path.write_text(
				json.dumps([chunk.model_dump() for chunk in chunks], ensure_ascii=False, indent=2), encoding="utf-8"
			)
			temporary_manifest = self.directory / f".{generation}.manifest.tmp"
			temporary_manifest.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
			os.replace(temporary_manifest, self.manifest_path)
			self._index = index
			self._chunks = chunks
		logger.info("faiss_index_built", extra={"chunk_count": len(chunks), "generation": generation})

	def search(
		self,
		query_embedding: list[float],
		top_k: int,
		min_relevance: float,
		filters: RetrievalFilters,
	) -> list[RetrievedChunk]:
		with self._lock:
			self._ensure_loaded()
			if self._index is None or not self._chunks:
				return []
			index = self._index
			chunks = self._chunks
		query = np.asarray([query_embedding], dtype="float32")
		if query.shape[1] != index.d:
			raise ValueError(f"Query embedding has dimension {query.shape[1]}, expected {index.d}")
		faiss.normalize_L2(query)
		scores, indices = index.search(query, len(chunks))
		results: list[RetrievedChunk] = []
		for score, idx in zip(scores[0], indices[0], strict=True):
			if idx < 0 or float(score) < min_relevance:
				continue
			chunk = chunks[int(idx)]
			metadata = chunk.metadata
			if filters.filename and metadata.filename != filters.filename:
				continue
			if filters.document_type and metadata.document_type != filters.document_type:
				continue
			results.append(RetrievedChunk(text=chunk.text, metadata=metadata, score=float(score)))
			if len(results) == top_k:
				break
		return results

	def _ensure_loaded(self) -> None:
		if self._index is not None:
			return
		with self._lock:
			if self._index is not None:
				return
			if not self.manifest_path.exists():
				return
			try:
				manifest = json.loads(self.manifest_path.read_text(encoding="utf-8"))
				if manifest.get("embedding_model") != self.embedding_model:
					raise RuntimeError("The embedding model changed; rebuild the index")
				generation = manifest["generation"]
				index = faiss.read_index(str(self.directory / f"{generation}.faiss"))
				raw_chunks = json.loads((self.directory / f"{generation}.json").read_text(encoding="utf-8"))
				chunks = [DocumentChunk.model_validate(chunk) for chunk in raw_chunks]
			except (KeyError, OSError, ValueError, json.JSONDecodeError, RuntimeError) as exc:
				raise RuntimeError(f"Could not load FAISS index: {exc}") from exc
			if index.ntotal != len(chunks) or manifest.get("count") != len(chunks) or manifest.get("dimension") != index.d:
				raise RuntimeError("FAISS index and chunk metadata are out of sync; rebuild the index")
			self._index = index
			self._chunks = chunks
