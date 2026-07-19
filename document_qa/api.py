from __future__ import annotations

import json
import logging
import re
from contextlib import asynccontextmanager
from typing import Annotated

from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware

from document_qa.answering import AnswerGenerator, validate_citations
from document_qa.config import Settings
from document_qa.documents import SUPPORTED_EXTENSIONS, list_documents
from document_qa.embeddings import OpenAIEmbedder
from document_qa.models import AnswerResponse, DocumentInfo, IndexRequest, IndexResponse, PublicConfig, RetrievalRequest, RetrievedChunk
from document_qa.retrieval import Retriever
from document_qa.service import IndexingService
from document_qa.vector_store import FaissVectorStore

settings = Settings.from_env()


class JsonFormatter(logging.Formatter):
	def format(self, record: logging.LogRecord) -> str:
		payload: dict[str, object] = {
			"time": self.formatTime(record, self.datefmt),
			"level": record.levelname,
			"logger": record.name,
			"message": record.getMessage(),
		}
		if record.exc_info:
			payload["exception"] = self.formatException(record.exc_info)
		for field in ("upload_filename", "document_path", "document_count", "chunk_count", "generation"):
			if hasattr(record, field):
				payload[field] = getattr(record, field)
		return json.dumps(payload, ensure_ascii=False)


handler = logging.StreamHandler()
handler.setFormatter(JsonFormatter())
logging.basicConfig(level=settings.log_level, handlers=[handler], force=True)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(_: FastAPI):
	settings.documents_dir.mkdir(parents=True, exist_ok=True)
	settings.index_dir.mkdir(parents=True, exist_ok=True)
	yield


app = FastAPI(title="Local Document Q&A", version="1.0.0", lifespan=lifespan)
app.add_middleware(
	CORSMiddleware,
	allow_origins=["http://localhost:8501", "http://127.0.0.1:8501"],
	allow_credentials=False,
	allow_methods=["GET", "POST"],
	allow_headers=["*"],
)


def _components() -> tuple[FaissVectorStore, OpenAIEmbedder, Retriever, AnswerGenerator]:
	try:
		embedder = OpenAIEmbedder(settings.openai_api_key, settings.openai_base_url, settings.embedding_model)
		store = FaissVectorStore(settings.index_dir, settings.embedding_model)
		return (
			store,
			embedder,
			Retriever(embedder, store, settings.min_relevance),
			AnswerGenerator(settings.openai_api_key, settings.openai_base_url, settings.chat_model),
		)
	except ValueError as exc:
		raise HTTPException(status_code=503, detail=str(exc)) from exc


@app.get("/health")
def health() -> dict[str, str]:
	return {"status": "ok"}


@app.get("/documents", response_model=list[DocumentInfo])
def documents() -> list[DocumentInfo]:
	return list_documents(settings.documents_dir)


@app.get("/config", response_model=PublicConfig)
def public_config() -> PublicConfig:
	return PublicConfig(default_top_k=settings.default_top_k, min_relevance=settings.min_relevance)


@app.post("/documents/upload", response_model=DocumentInfo)
async def upload_document(file: Annotated[UploadFile, File()]) -> DocumentInfo:
	filename = re.sub(r"[^A-Za-z0-9._-]", "_", file.filename or "")
	if not filename or filename.startswith(".") or not any(filename.lower().endswith(ext) for ext in SUPPORTED_EXTENSIONS):
		raise HTTPException(status_code=400, detail="Only .md, .txt, and .pdf files are supported")
	content = await file.read(settings.max_upload_mb * 1024 * 1024 + 1)
	if len(content) > settings.max_upload_mb * 1024 * 1024:
		raise HTTPException(status_code=413, detail=f"Upload exceeds {settings.max_upload_mb} MB")
	path = settings.documents_dir / filename
	try:
		path.parent.mkdir(parents=True, exist_ok=True)
		path.write_bytes(content)
	except OSError as exc:
		logger.exception("upload_failed", extra={"upload_filename": filename})
		raise HTTPException(status_code=500, detail="Could not save uploaded document") from exc
	return next(document for document in list_documents(settings.documents_dir) if document.path == filename)


@app.post("/index/rebuild", response_model=IndexResponse)
def rebuild_index(request: IndexRequest) -> IndexResponse:
	store, embedder, _, _ = _components()
	try:
		return IndexingService(settings, embedder, store).rebuild(request.paths)
	except ValueError as exc:
		raise HTTPException(status_code=400, detail=str(exc)) from exc
	except Exception as exc:
		logger.exception("index_rebuild_failed")
		raise HTTPException(status_code=502, detail="Index rebuild failed; check the backend logs") from exc


@app.post("/retrieve", response_model=list[RetrievedChunk])
def retrieve(request: RetrievalRequest) -> list[RetrievedChunk]:
	_, _, retriever, _ = _components()
	try:
		return retriever.retrieve(
			request.question, request.top_k or settings.default_top_k, request.filters, request.min_relevance
		)
	except Exception as exc:
		logger.exception("retrieval_failed")
		raise HTTPException(status_code=502, detail="Retrieval failed; check the index and backend logs") from exc


@app.post("/ask", response_model=AnswerResponse)
def ask(request: RetrievalRequest) -> AnswerResponse:
	_, _, retriever, generator = _components()
	try:
		chunks = retriever.retrieve(
			request.question, request.top_k or settings.default_top_k, request.filters, request.min_relevance
		)
		answer, citations = validate_citations(generator.answer(request.question, chunks), chunks)
		return AnswerResponse(answer=answer, citations=citations, retrieved_chunks=chunks)
	except Exception as exc:
		logger.exception("answer_failed")
		raise HTTPException(status_code=502, detail="Answer generation failed; check the backend logs") from exc
