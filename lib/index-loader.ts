import { readFile, stat } from "node:fs/promises";
import type { Index } from "./retriever.ts";

export interface IndexLoader {
	load(): Promise<Index>;
	clear(): void;
}

export function createIndexLoader(indexPath: string): IndexLoader {
	let cache: Index | null = null;
	let cacheMtime = 0;
	let cacheSize = 0;

	return {
		async load() {
			const stats = await stat(indexPath);
			if (!cache || stats.mtimeMs !== cacheMtime || stats.size !== cacheSize) {
				cache = JSON.parse(await readFile(indexPath, "utf-8")) as Index;
				cacheMtime = stats.mtimeMs;
				cacheSize = stats.size;
			}
			return cache;
		},
		clear() {
			cache = null;
			cacheMtime = 0;
			cacheSize = 0;
		},
	};
}
