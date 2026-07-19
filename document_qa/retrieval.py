from __future__ import annotations

from document_qa.embeddings import Embedder
from document_qa.models import RetrievalFilters, RetrievedChunk
from document_qa.vector_store import FaissVectorStore


class Retriever:
	"""Retrieves relevant chunks without performing answer generation."""

	def __init__(self, embedder: Embedder, store: FaissVectorStore, default_min_relevance: float) -> None:
		self._embedder = embedder
		self._store = store
		self._default_min_relevance = default_min_relevance

	def retrieve(
		self,
		question: str,
		top_k: int,
		filters: RetrievalFilters | None = None,
		min_relevance: float | None = None,
	) -> list[RetrievedChunk]:
		if not question.strip():
			raise ValueError("Question cannot be empty")
		if top_k <= 0:
			raise ValueError("top_k must be greater than zero")
		query_embeddings = self._embedder.embed([question])
		if len(query_embeddings) != 1:
			raise RuntimeError("Embedding provider did not return one query embedding")
		return self._store.search(
			query_embeddings[0],
			top_k,
			self._default_min_relevance if min_relevance is None else min_relevance,
			filters or RetrievalFilters(),
		)
