import { chunkText } from "../lib/indexer";

const SAMPLE_DOCUMENT = `
# Retrieval-Augmented Generation (RAG) Architecture

Retrieval-Augmented Generation is a pattern where an LLM retrieves facts from an external vector index to answer questions.
Without grounding, LLMs are prone to hallucinating facts or missing domain-specific context.

## The Role of Embeddings

We convert documents into dense numerical vectors called embeddings.
When a user submits a query, we compute similarity scores between the query vector and our database of document vectors.
The most relevant chunks are then injected into the prompt.

## The Chunking Tradeoff

We must chunk text because models have strict input token limits.
If our chunks are too large, we capture irrelevant text that dilutes the search signal.
If our chunks are too small, we lose context (e.g., a sentence saying 'They are injected' without defining 'They').
`.trim();

function runComparison() {
	console.log("====================================================");
	console.log("   Day 9 — Chunking Comparison CLI Utility");
	console.log("====================================================\n");

	const QUERY = "injected";

	// Configuration 1: Small Chunks, No Overlap
	const config1 = { size: 120, overlap: 0 };
	const chunks1 = chunkText(SAMPLE_DOCUMENT, config1.size, config1.overlap);

	// Configuration 2: Small Chunks, With Overlap
	const config2 = { size: 120, overlap: 40 };
	const chunks2 = chunkText(SAMPLE_DOCUMENT, config2.size, config2.overlap);

	// Configuration 3: Large Chunks, No Overlap
	const config3 = { size: 400, overlap: 0 };
	const chunks3 = chunkText(SAMPLE_DOCUMENT, config3.size, config3.overlap);

	console.log(`Analyzing query: "${QUERY}"\n`);

	console.log("----------------------------------------------------");
	console.log(`1. Small Chunks, NO Overlap (Size: ${config1.size}, Overlap: ${config1.overlap})`);
	console.log("----------------------------------------------------");
	console.log(`Total chunks generated: ${chunks1.length}`);
	const matches1 = chunks1.filter((c) => c.toLowerCase().includes(QUERY));
	console.log(`Matches found: ${matches1.length}`);
	matches1.forEach((m, idx) => {
		console.log(`\nMatch #${idx + 1}:`);
		console.log(`<<< ${m} >>>`);
	});

	console.log("\n----------------------------------------------------");
	console.log(`2. Small Chunks, WITH Overlap (Size: ${config2.size}, Overlap: ${config2.overlap})`);
	console.log("----------------------------------------------------");
	console.log(`Total chunks generated: ${chunks2.length}`);
	const matches2 = chunks2.filter((c) => c.toLowerCase().includes(QUERY));
	console.log(`Matches found: ${matches2.length}`);
	matches2.forEach((m, idx) => {
		console.log(`\nMatch #${idx + 1}:`);
		console.log(`<<< ${m} >>>`);
	});

	console.log("\n----------------------------------------------------");
	console.log(`3. Large Chunks, NO Overlap (Size: ${config3.size}, Overlap: ${config3.overlap})`);
	console.log("----------------------------------------------------");
	console.log(`Total chunks generated: ${chunks3.length}`);
	const matches3 = chunks3.filter((c) => c.toLowerCase().includes(QUERY));
	console.log(`Matches found: ${matches3.length}`);
	matches3.forEach((m, idx) => {
		console.log(`\nMatch #${idx + 1}:`);
		console.log(`<<< ${m} >>>`);
	});

	console.log("\n====================================================");
	console.log("   Evaluation Analysis");
	console.log("====================================================");
	console.log(
		"- Did small chunks with 0 overlap split 'The most relevant chunks are then injected into the prompt.'?",
	);
	console.log(
		"  Yes, and without overlap, you might lose the subject context ('embeddings' / 'RAG').",
	);
	console.log("- Does overlap bridge the split? Look at Match #1 in Config 2 vs Config 1.");
	console.log(
		"- Does a large chunk size dilute precision? Look at how much extra text is retrieved in Config 3.",
	);
}

runComparison();
