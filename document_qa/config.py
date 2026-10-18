from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path


def _env_int(name: str, default: int) -> int:
	value = int(os.getenv(name, str(default)))
	if value <= 0:
		raise ValueError(f"{name} must be greater than zero")
	return value


def _env_float(name: str, default: float) -> float:
	value = float(os.getenv(name, str(default)))
	if not -1.0 <= value <= 1.0:
		raise ValueError(f"{name} must be between -1 and 1")
	return value


@dataclass(frozen=True)
class Settings:
	documents_dir: Path
	index_dir: Path
	chunk_size: int
	chunk_overlap: int
	default_top_k: int
	min_relevance: float
	embedding_model: str
	chat_model: str
	openai_api_key: str | None
	openai_base_url: str | None
	log_level: str
	max_upload_mb: int

	@classmethod
	def from_env(cls) -> Settings:
		chunk_size = _env_int("DOCUMENT_QA_CHUNK_SIZE", 1000)
		chunk_overlap = int(os.getenv("DOCUMENT_QA_CHUNK_OVERLAP", "200"))
		if not 0 <= chunk_overlap < chunk_size:
			raise ValueError("DOCUMENT_QA_CHUNK_OVERLAP must be non-negative and smaller than chunk size")
		return cls(
			documents_dir=Path(os.getenv("DOCUMENT_QA_DOCUMENTS_DIR", "document_qa/documents")).resolve(),
			index_dir=Path(os.getenv("DOCUMENT_QA_INDEX_DIR", "document_qa/data")).resolve(),
			chunk_size=chunk_size,
			chunk_overlap=chunk_overlap,
			default_top_k=_env_int("DOCUMENT_QA_TOP_K", 5),
			min_relevance=_env_float("DOCUMENT_QA_MIN_RELEVANCE", 0.25),
			embedding_model=os.getenv("OPENAI_EMBEDDING_MODEL", "text-embedding-3-small"),
			chat_model=os.getenv("OPENAI_MODEL", "gpt-4o-mini"),
			openai_api_key=os.getenv("OPENAI_API_KEY"),
			openai_base_url=os.getenv("OPENAI_BASE_URL"),
			log_level=os.getenv("DOCUMENT_QA_LOG_LEVEL", "INFO").upper(),
			max_upload_mb=_env_int("DOCUMENT_QA_MAX_UPLOAD_MB", 20),
		)
