// Day 8 — Semantic Search Cosine Similarity CLI Utility

type Note = {
	id: number;
	text: string;
	vector: number[];
};

const TARGET_NOTES: Note[] = [
	{
		id: 1,
		text: "Configure PostgreSQL connection pool for backend server.",
		vector: [0.9, 0.1, 0.0, 0.0],
	},
	{
		id: 2,
		text: "Style the dashboard using CSS grid and dark theme variables.",
		vector: [0.1, 0.9, 0.0, 0.0],
	},
	{
		id: 3,
		text: "Fix null pointer exception crash in API auth handler.",
		vector: [0.3, 0.0, 0.9, 0.0],
	},
	{
		id: 4,
		text: "Adopted a stray kitten from the animal rescue shelter.",
		vector: [0.0, 0.0, 0.0, 1.0],
	},
];

const QUERIES: Record<string, number[]> = {
	relational: [1.0, 0.0, 0.0, 0.0],
	visual: [0.0, 1.0, 0.0, 0.0],
	crash: [0.0, 0.0, 1.0, 0.0],
	feline: [0.0, 0.0, 0.0, 1.0],
};

function dotProduct(vecA: number[], vecB: number[]): number {
	return vecA.reduce((sum, val, idx) => sum + val * (vecB[idx] ?? 0), 0);
}

function magnitude(vec: number[]): number {
	return Math.sqrt(vec.reduce((sum, val) => sum + val * val, 0));
}

function cosineSimilarity(vecA: number[], vecB: number[]): number {
	const dot = dotProduct(vecA, vecB);
	const magA = magnitude(vecA);
	const magB = magnitude(vecB);
	if (magA === 0 || magB === 0) return 0;
	return dot / (magA * magB);
}

function runSemanticSearch() {
	console.log("====================================================");
	console.log("    Day 8 — Cosine Similarity Semantic Search");
	console.log("====================================================\n");

	console.log("Target Notes Corpus:");
	TARGET_NOTES.forEach((n) => {
		console.log(`[Note #${n.id}] ${n.text}`);
		console.log(`        Vector: [${n.vector.join(", ")}]`);
	});
	console.log("");

	for (const [queryName, queryVec] of Object.entries(QUERIES)) {
		console.log("----------------------------------------------------");
		console.log(`Query: "${queryName}"  Vector: [${queryVec.join(", ")}]`);
		console.log("----------------------------------------------------");

		const ranked = TARGET_NOTES.map((note) => {
			const similarity = cosineSimilarity(queryVec, note.vector);
			return { note, similarity };
		}).sort((a, b) => b.similarity - a.similarity);

		ranked.forEach((r, idx) => {
			const matchIndicator = r.similarity > 0.5 ? "★ MATCH" : "  -    ";
			console.log(
				`Rank #${idx + 1} | Score: ${r.similarity.toFixed(4)} | ${matchIndicator} | ${r.note.text}`,
			);
		});
		console.log("");
	}

	console.log("====================================================");
	console.log("    Mathematical Analysis");
	console.log("====================================================");
	console.log("- Notice how query 'feline' retrieves the stray kitten note with score 1.0000.");
	console.log("- Notice how query 'relational' retrieves PostgreSQL note with score 0.9939.");
	console.log(
		"  (Cosine calculation: (1.0*0.9 + 0*0.1 + 0*0 + 0*0) / (1.0 * sqrt(0.81 + 0.01)) = 0.9 / 0.9055 = 0.9939)",
	);
}

runSemanticSearch();
