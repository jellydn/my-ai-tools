import type { ReviewFinding } from "./types.ts";
export interface PullFile {
	filename: string;
	patch?: string;
}
export function commentableLines(patch = ""): Set<number> {
	let right = 0;
	const lines = new Set<number>();
	for (const row of patch.split("\n")) {
		const hunk = row.match(/^@@ -\d+(?:,\d+)? \+(\d+)/);
		if (hunk) {
			right = Number(hunk[1]);
			continue;
		}
		if (row.startsWith("-")) continue;
		if (row.startsWith("+") || row.startsWith(" ")) {
			lines.add(right);
			right++;
		}
	}
	return lines;
}
export function validateFindings(findings: ReviewFinding[], files: PullFile[], threshold: number) {
	const byPath = new Map(files.map((file) => [file.filename, commentableLines(file.patch)]));
	const seen = new Set<string>();
	const inline: ReviewFinding[] = [];
	const fallback: ReviewFinding[] = [];
	for (const finding of findings.filter((x) => x.confidence >= threshold)) {
		const key = `${finding.path}:${finding.line}:${finding.body}`;
		if (seen.has(key)) continue;
		seen.add(key);
		(byPath.get(finding.path)?.has(finding.line) ? inline : fallback).push(finding);
	}
	return { inline, fallback };
}
