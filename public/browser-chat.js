import { env, pipeline, TextStreamer } from "https://cdn.jsdelivr.net/npm/@huggingface/transformers@4.2.0/+esm";

const EMBEDDING_MODEL = "Xenova/all-MiniLM-L6-v2";
const LLM_MODEL = "onnx-community/Qwen2.5-Coder-0.5B-Instruct";
const INDEX_PATH = "/public/index-browser.json";

let indexData = null;
let extractorPromise = null;
let generatorPromise = null;

env.allowLocalModels = false;
env.useBrowserCache = true;

function getDevice() {
	return typeof navigator !== "undefined" && "gpu" in navigator ? "webgpu" : "cpu";
}

function encodeSourcePath(path) {
	return path.split("/").map(encodeURIComponent).join("/");
}

function escapeHtml(text) {
	return text
		.replace(/&/g, "&amp;")
		.replace(/</g, "&lt;")
		.replace(/>/g, "&gt;")
		.replace(/"/g, "&quot;")
		.replace(/'/g, "&#39;");
}

export function linkifySource(path) {
	return `<a href="https://github.com/jellydn/my-ai-tools/blob/main/${encodeSourcePath(path)}" target="_blank" rel="noopener">${escapeHtml(path)}</a>`;
}

async function getIndex() {
	if (indexData) return indexData;

	const response = await fetch(INDEX_PATH);
	if (!response.ok) {
		throw new Error(`Failed to load index: ${response.status} ${response.statusText}`);
	}

	const json = await response.json();
	const binary = Uint8Array.from(atob(json.embeddings), (c) => c.charCodeAt(0));
	const embeddings = new Float32Array(
		binary.buffer,
		binary.byteOffset,
		binary.byteLength / Float32Array.BYTES_PER_ELEMENT,
	);

	const chunks = json.chunks.map((chunk, index) => ({
		path: chunk.path,
		text: chunk.text,
		embedding: embeddings.subarray(index * json.dim, (index + 1) * json.dim),
	}));

	indexData = { dim: json.dim, chunks, generatedAt: json.generatedAt, model: json.model };
	return indexData;
}

async function getExtractor() {
	if (!extractorPromise) {
		extractorPromise = pipeline("feature-extraction", EMBEDDING_MODEL, {
			device: getDevice(),
			dtype: "fp32",
		});
	}
	return extractorPromise;
}

async function getGenerator() {
	if (!generatorPromise) {
		generatorPromise = pipeline("text-generation", LLM_MODEL, {
			device: getDevice(),
			dtype: "q4",
		});
	}
	return generatorPromise;
}

function dotProduct(a, b) {
	let sum = 0;
	for (let i = 0; i < a.length; i++) {
		sum += a[i] * b[i];
	}
	return sum;
}

function retrieveTopK(queryEmbedding, chunks, k) {
	const scored = chunks.map((chunk) => ({ chunk, score: dotProduct(queryEmbedding, chunk.embedding) }));
	scored.sort((a, b) => b.score - a.score);
	return scored.slice(0, k).map((item) => item.chunk);
}

function buildPrompt(chunks, question) {
	const context = chunks.map((chunk) => `--- ${chunk.path} ---\n${chunk.text}`).join("\n\n");
	return `You are the my-ai-tools repository assistant.

Answer only from the retrieved repository excerpts below.
Do not invent commands, supported tools, or configuration.
If the retrieved context is insufficient, say exactly: "This is not documented in the repository."
Include the relevant source file paths in your answer.
Keep answers concise and grounded.

Retrieved repository excerpts:
${context}

Question: ${question}`;
}

function updateStatus(callbacks, text) {
	if (callbacks.onStatus) callbacks.onStatus(text);
}

export async function runBrowserChat(question, callbacks) {
	updateStatus(callbacks, "Loading index...");
	const index = await getIndex();

	updateStatus(callbacks, "Loading embedding model...");
	const extractor = await getExtractor();

	updateStatus(callbacks, "Embedding query...");
	const queryOutput = await extractor(question, { pooling: "mean", normalize: true });
	const queryEmbedding = queryOutput.data;

	updateStatus(callbacks, "Retrieving chunks...");
	const topChunks = retrieveTopK(queryEmbedding, index.chunks, 5);

	updateStatus(callbacks, "Loading language model...");
	const generator = await getGenerator();

	updateStatus(callbacks, "Generating answer...");
	const prompt = buildPrompt(topChunks, question);
	const sourcePaths = [...new Set(topChunks.map((chunk) => chunk.path))];

	const streamer = new TextStreamer(generator.tokenizer, {
		skip_prompt: true,
		skip_special_tokens: true,
		callback_function: (token) => {
			if (callbacks.onToken) callbacks.onToken(token);
		},
	});

	await generator([{ role: "user", content: prompt }], {
		max_new_tokens: 512,
		do_sample: false,
		streamer,
	});

	if (callbacks.onSource) callbacks.onSource(sourcePaths);
}
