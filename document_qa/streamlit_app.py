from __future__ import annotations

import os
from typing import Any

import requests
import streamlit as st

API_URL = os.getenv("DOCUMENT_QA_API_URL", "http://127.0.0.1:8000").rstrip("/")
TIMEOUT = 120


def api_request(method: str, path: str, **kwargs: Any) -> Any:
	try:
		response = requests.request(method, f"{API_URL}{path}", timeout=TIMEOUT, **kwargs)
		response.raise_for_status()
		return response.json()
	except requests.RequestException as exc:
		detail = getattr(exc.response, "text", "") if exc.response is not None else ""
		raise RuntimeError(f"Backend request failed: {detail or exc}") from exc


st.set_page_config(page_title="Local Document Q&A", page_icon="📚", layout="wide")
st.title("📚 Local Document Q&A")
st.caption("Index Markdown, text, and PDF files, then ask grounded questions with chunk-level citations.")

with st.sidebar:
	st.header("Documents")
	uploads = st.file_uploader("Upload documents", type=["md", "txt", "pdf"], accept_multiple_files=True)
	if st.button("Upload", disabled=not uploads, use_container_width=True):
		try:
			for upload in uploads:
				api_request("POST", "/documents/upload", files={"file": (upload.name, upload.getvalue(), upload.type)})
			st.success(f"Uploaded {len(uploads)} document(s)")
		except RuntimeError as exc:
			st.error(str(exc))

	try:
		documents = api_request("GET", "/documents")
		config = api_request("GET", "/config")
	except RuntimeError as exc:
		st.error(str(exc))
		documents = []
		config = {"default_top_k": 5, "min_relevance": 0.25}
	paths = [document["path"] for document in documents]
	selected_paths = st.multiselect("Local documents", paths, default=paths)
	if st.button("Rebuild index", type="primary", disabled=not selected_paths, use_container_width=True):
		try:
			with st.spinner("Chunking and embedding documents..."):
				result = api_request("POST", "/index/rebuild", json={"paths": selected_paths})
			st.success(f"Indexed {result['documents_indexed']} documents / {result['chunks_indexed']} chunks")
		except RuntimeError as exc:
			st.error(str(exc))

	st.header("Retrieval")
	top_k = st.slider("Top K", min_value=1, max_value=20, value=min(config["default_top_k"], 20))
	min_relevance = st.slider(
		"Minimum relevance", min_value=-1.0, max_value=1.0, value=config["min_relevance"], step=0.05
	)
	filename_filter = st.selectbox("Filename filter", ["Any", *[document["filename"] for document in documents]])
	document_type_filter = st.selectbox("Document type filter", ["Any", "markdown", "text", "pdf"])

question = st.text_input("Question", placeholder="What does the documentation say about…?")
if st.button("Ask", type="primary", disabled=not question, use_container_width=True):
	payload = {
		"question": question,
		"top_k": top_k,
		"min_relevance": min_relevance,
		"filters": {
			"filename": None if filename_filter == "Any" else filename_filter,
			"document_type": None if document_type_filter == "Any" else document_type_filter,
		},
	}
	try:
		with st.spinner("Retrieving and answering..."):
			result = api_request("POST", "/ask", json=payload)
		st.subheader("Answer")
		st.write(result["answer"])
		if result["citations"]:
			st.caption("Citations: " + " ".join(result["citations"]))
		st.subheader("Retrieved chunks")
		if not result["retrieved_chunks"]:
			st.info("No chunks met the filters and relevance threshold.")
		for chunk in result["retrieved_chunks"]:
			metadata = chunk["metadata"]
			label = f"{metadata['filename']} · chunk {metadata['chunk_index']} · score {chunk['score']:.3f}"
			with st.expander(label):
				if metadata.get("heading"):
					st.caption(f"Heading: {metadata['heading']}")
				st.caption(metadata["document_path"])
				st.text(chunk["text"])
	except RuntimeError as exc:
		st.error(str(exc))
