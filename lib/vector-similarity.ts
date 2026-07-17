/** Cosine similarity for equal-length embedding vectors. Returns 0 when either vector has zero norm. */
export function cosineSimilarity(a: number[], b: number[]): number {
	let dot = 0;
	let aNorm = 0;
	let bNorm = 0;
	const length = Math.max(a.length, b.length);
	for (let index = 0; index < length; index++) {
		const aValue = a[index] ?? 0;
		const bValue = b[index] ?? 0;
		dot += aValue * bValue;
		aNorm += aValue * aValue;
		bNorm += bValue * bValue;
	}
	return dot / (Math.sqrt(aNorm) * Math.sqrt(bNorm) || 1);
}
