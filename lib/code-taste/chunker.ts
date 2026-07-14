import { extname } from "node:path";
import { fileURLToPath } from "node:url";
import { Language, Parser, type Node as SyntaxNode } from "web-tree-sitter";

export type SemanticChunk = {
	repo: string;
	path: string;
	symbol: string;
	kind: "code" | "documentation";
	text: string;
};

export type ChunkingStats = {
	oversizedUnits: number;
};

const DECLARATION_TYPES = new Set([
	"class_declaration",
	"enum_declaration",
	"function_declaration",
	"generator_function_declaration",
	"interface_declaration",
	"lexical_declaration",
	"type_alias_declaration",
]);

const TARGET_MARKDOWN_CHUNK_LENGTH = 4_000;
export const MAX_SEMANTIC_CHUNK_LENGTH = 8_000;
type MarkdownFence = { marker: "`" | "~"; length: number };
let initialized: Promise<void> | undefined;
let typescriptLanguage: Promise<Language> | undefined;
let tsxLanguage: Promise<Language> | undefined;

function initializeParser(): Promise<void> {
	initialized ??= Parser.init();
	return initialized;
}

async function loadLanguage(name: "typescript" | "tsx"): Promise<Language> {
	await initializeParser();
	const wasmUrl = import.meta.resolve(`@vscode/tree-sitter-wasm/wasm/tree-sitter-${name}.wasm`);
	return Language.load(fileURLToPath(wasmUrl));
}

function languageFor(path: string): Promise<Language> {
	if (extname(path).toLowerCase() === ".tsx") {
		tsxLanguage ??= loadLanguage("tsx");
		return tsxLanguage;
	}
	typescriptLanguage ??= loadLanguage("typescript");
	return typescriptLanguage;
}

function declarationName(node: SyntaxNode, source: string): string {
	const name = node.childForFieldName("name");
	if (name) return source.slice(name.startIndex, name.endIndex);

	if (node.type === "lexical_declaration") {
		const declarator = node.namedChildren.find((child) => child.type === "variable_declarator");
		const variableName = declarator?.childForFieldName("name");
		if (variableName) return source.slice(variableName.startIndex, variableName.endIndex);
	}

	return `lines ${node.startPosition.row + 1}-${node.endPosition.row + 1}`;
}

function startWithComments(node: SyntaxNode): number {
	let start = node.startIndex;
	let previous = node.previousNamedSibling;
	while (previous?.type === "comment" && node.startPosition.row - previous.endPosition.row <= 2) {
		start = previous.startIndex;
		previous = previous.previousNamedSibling;
	}
	return start;
}

function supportingTypes(node: SyntaxNode, declarations: SyntaxNode[], source: string): string[] {
	const nodeText = source.slice(node.startIndex, node.endIndex);
	return declarations.flatMap((candidate) => {
		if (!new Set(["interface_declaration", "type_alias_declaration", "enum_declaration"]).has(candidate.type)) return [];
		const name = declarationName(candidate, source);
		if (candidate === node || !new RegExp(`\\b${name.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}\\b`).test(nodeText))
			return [];
		return [source.slice(startWithComments(candidate), candidate.endIndex).trim()];
	});
}

function fenceDelimiter(line: string): { marker: "`" | "~"; length: number; rest: string } | undefined {
	const match = /^\s*(`{3,}|~{3,})(.*)$/.exec(line);
	const delimiter = match?.[1];
	if (!delimiter) return undefined;
	return { marker: delimiter[0] as "`" | "~", length: delimiter.length, rest: match[2] ?? "" };
}

function closesFence(delimiter: ReturnType<typeof fenceDelimiter>, fence: MarkdownFence): boolean {
	return Boolean(
		delimiter && delimiter.marker === fence.marker && delimiter.length >= fence.length && delimiter.rest.trim() === "",
	);
}

function markdownBlocks(text: string): string[] {
	const blocks: string[] = [];
	let lines: string[] = [];
	let fence: MarkdownFence | undefined;

	for (const line of text.split("\n")) {
		const delimiter = fenceDelimiter(line);
		if (fence) {
			lines.push(line);
			if (closesFence(delimiter, fence)) fence = undefined;
			continue;
		}
		if (delimiter) {
			fence = { marker: delimiter.marker, length: delimiter.length };
			lines.push(line);
			continue;
		}
		if (line.trim() === "") {
			if (lines.length > 0) blocks.push(lines.join("\n"));
			lines = [];
			continue;
		}
		lines.push(line);
	}
	if (lines.length > 0) blocks.push(lines.join("\n"));
	return blocks;
}

function splitMarkdownSection(text: string): string[] {
	if (text.length <= TARGET_MARKDOWN_CHUNK_LENGTH) return [text];
	const blocks = markdownBlocks(text);
	const chunks: string[] = [];
	let current = "";
	for (const block of blocks) {
		if (current && current.length + block.length + 2 > TARGET_MARKDOWN_CHUNK_LENGTH) {
			chunks.push(current);
			current = "";
		}
		current = current ? `${current}\n\n${block}` : block;
	}
	if (current) chunks.push(current);
	return chunks;
}

export async function chunkTypeScript(
	repo: string,
	path: string,
	source: string,
	stats?: ChunkingStats,
): Promise<SemanticChunk[]> {
	const language = await languageFor(path);
	const parser = new Parser();
	parser.setLanguage(language);
	const tree = parser.parse(source);
	if (!tree) {
		parser.delete();
		return [];
	}

	try {
		const chunks: SemanticChunk[] = [];
		const nodes = tree.rootNode.namedChildren.flatMap((node) => {
			const declaration = node.type === "export_statement" ? node.namedChildren.at(-1) : node;
			return declaration && DECLARATION_TYPES.has(declaration.type) ? [{ wrapper: node, declaration }] : [];
		});
		const declarations = nodes.map((item) => item.declaration);
		for (const { wrapper, declaration } of nodes) {
			if (!declaration || !DECLARATION_TYPES.has(declaration.type)) continue;

			const symbol = declarationName(declaration, source);
			const primary = source.slice(startWithComments(wrapper), wrapper.endIndex).trim();
			const context = supportingTypes(declaration, declarations, source);
			const text = [...context, primary].join("\n\n");
			if (text.length <= MAX_SEMANTIC_CHUNK_LENGTH) {
				chunks.push({
					repo,
					path,
					symbol,
					kind: "code",
					text,
				});
			} else if (stats) {
				stats.oversizedUnits += 1;
			}
		}
		return chunks;
	} finally {
		tree.delete();
		parser.delete();
	}
}

export function chunkMarkdown(repo: string, path: string, source: string, stats?: ChunkingStats): SemanticChunk[] {
	const lines = source.replace(/\r\n/g, "\n").split("\n");
	const sections: Array<{ heading: string; lines: string[] }> = [];
	let current = { heading: "Introduction", lines: [] as string[] };
	let fence: MarkdownFence | undefined;

	for (const line of lines) {
		const delimiter = fenceDelimiter(line);
		if (fence) {
			current.lines.push(line);
			if (closesFence(delimiter, fence)) fence = undefined;
			continue;
		}
		if (delimiter) {
			fence = { marker: delimiter.marker, length: delimiter.length };
			current.lines.push(line);
			continue;
		}
		const heading = /^(#{1,6})\s+(.+?)\s*$/.exec(line);
		if (heading) {
			if (current.lines.some((item) => item.trim().length > 0)) sections.push(current);
			current = { heading: heading[2] ?? "Section", lines: [line] };
		} else {
			current.lines.push(line);
		}
	}
	if (current.lines.some((item) => item.trim().length > 0)) sections.push(current);

	const chunks = sections.flatMap((section) =>
		splitMarkdownSection(section.lines.join("\n").trim())
			.map((text, index) => ({
				repo,
				path,
				symbol: index === 0 ? section.heading : `${section.heading} (part ${index + 1})`,
				kind: "documentation" as const,
				text,
			}))
			.filter((chunk) => {
				if (chunk.text.length <= MAX_SEMANTIC_CHUNK_LENGTH) return true;
				if (stats) stats.oversizedUnits += 1;
				return false;
			}),
	);
	return chunks;
}

export async function chunkFile(
	repo: string,
	path: string,
	source: string,
	stats?: ChunkingStats,
): Promise<SemanticChunk[]> {
	return extname(path).toLowerCase() === ".md"
		? chunkMarkdown(repo, path, source, stats)
		: chunkTypeScript(repo, path, source, stats);
}
