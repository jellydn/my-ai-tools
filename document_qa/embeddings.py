from __future__ import annotations

from collections.abc import Sequence
from typing import Protocol

from openai import OpenAI


class Embedder(Protocol):
	def embed(self, texts: Sequence[str]) -> list[list[float]]: ...


class OpenAIEmbedder:
	_BATCH_SIZE = 256

	def __init__(self, api_key: str | None, base_url: str | None, model: str) -> None:
		if not api_key:
			raise ValueError("OPENAI_API_KEY is required for indexing and retrieval")
		self._client = OpenAI(api_key=api_key, base_url=base_url)
		self._model = model

	def embed(self, texts: Sequence[str]) -> list[list[float]]:
		if not texts:
			return []
		embeddings: list[list[float]] = []
		for start in range(0, len(texts), self._BATCH_SIZE):
			batch = list(texts[start : start + self._BATCH_SIZE])
			response = self._client.embeddings.create(model=self._model, input=batch, encoding_format="float")
			ordered = sorted(response.data, key=lambda item: item.index)
			if len(ordered) != len(batch):
				raise RuntimeError("Embedding provider returned an unexpected number of embeddings")
			embeddings.extend(item.embedding for item in ordered)
		return embeddings
