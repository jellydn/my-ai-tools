from __future__ import annotations

from pathlib import Path
from typing import Literal

from pydantic import BaseModel, Field

DocumentType = Literal["markdown", "text", "pdf"]


class ChunkMetadata(BaseModel):
	filename: str
	document_path: str
	chunk_index: int
	document_type: DocumentType
	heading: str | None = None


class DocumentChunk(BaseModel):
	text: str
	metadata: ChunkMetadata


class RetrievedChunk(DocumentChunk):
	score: float


class RetrievalFilters(BaseModel):
	filename: str | None = None
	document_type: DocumentType | None = None


class RetrievalRequest(BaseModel):
	question: str = Field(min_length=1)
	top_k: int | None = Field(default=None, ge=1, le=100)
	min_relevance: float | None = Field(default=None, ge=-1, le=1)
	filters: RetrievalFilters = Field(default_factory=RetrievalFilters)


class AnswerResponse(BaseModel):
	answer: str
	citations: list[str]
	retrieved_chunks: list[RetrievedChunk]


class IndexRequest(BaseModel):
	paths: list[str] = Field(default_factory=list)


class IndexResponse(BaseModel):
	documents_indexed: int
	chunks_indexed: int


class DocumentInfo(BaseModel):
	filename: str
	path: str
	document_type: DocumentType


class PublicConfig(BaseModel):
	default_top_k: int
	min_relevance: float


def document_type_for_path(path: Path) -> DocumentType:
	extension = path.suffix.lower()
	if extension == ".md":
		return "markdown"
	if extension == ".txt":
		return "text"
	if extension == ".pdf":
		return "pdf"
	raise ValueError(f"Unsupported document type: {extension or '(none)'}")
