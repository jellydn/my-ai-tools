// Generate the HTML pages in docs/ from the top-level Markdown guides.
//
// Usage: bun scripts/render-docs.ts
//
// GitHub-Flavored Markdown tables are rendered as HTML tables. Links to a
// published guide are rewritten from .md to .html so the static site stays
// inside the shared layout. Other links are left unchanged.

import { readdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { Marked, type Token, type Tokens } from "marked";

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const docsDir = resolve(repoRoot, "docs");

type Page = {
	file: string;
	title: string;
	markdown: string;
};

function escapeHtml(value: string): string {
	return value
		.replaceAll("&", "&amp;")
		.replaceAll("<", "&lt;")
		.replaceAll(">", "&gt;")
		.replaceAll('"', "&quot;");
}

function pageTitle(markdown: string, file: string): string {
	const firstLine = markdown.split("\n")[0] ?? "";
	const match = /^#\s+(.+)$/.exec(firstLine);
	if (!match?.[1]) {
		throw new Error(`${file} is missing a level-1 heading on the first line`);
	}
	return match[1].trim();
}

function loadPages(): Page[] {
	return readdirSync(docsDir)
		.filter((name) => name.endsWith(".md"))
		.sort()
		.map((file) => {
			const markdown = readFileSync(resolve(docsDir, file), "utf8");
			return { file, title: pageTitle(markdown, file), markdown };
		});
}

function rewriteHref(href: string, published: Set<string>): string {
	const hashIndex = href.indexOf("#");
	const pathPart = hashIndex === -1 ? href : href.slice(0, hashIndex);
	const hash = hashIndex === -1 ? "" : href.slice(hashIndex);
	if (pathPart === "" || pathPart.startsWith("mailto:") || /^[a-z][a-z0-9+.-]*:/i.test(pathPart)) {
		return href;
	}
	const resolved = resolve(docsDir, pathPart);
	const rel = relative(docsDir, resolved);
	if (rel.startsWith("..") || !published.has(rel)) {
		return href;
	}
	return `${rel.replace(/\.md$/, ".html")}${hash}`;
}

function isHrefToken(token: Token): token is Tokens.Link | Tokens.Image {
	return token.type === "link" || token.type === "image";
}

function renderMarkdown(markdown: string, published: Set<string>): string {
	const marked = new Marked({ gfm: true });
	marked.use({
		walkTokens(token) {
			if (isHrefToken(token)) {
				token.href = rewriteHref(token.href, published);
			}
		},
	});
	const html = marked.parse(markdown);
	if (typeof html !== "string") {
		throw new Error("marked returned a promise; the docs renderer is synchronous");
	}
	return html.trim();
}

function sidebar(pages: Page[]): string {
	const links = pages
		.map((page) => `<a href="${page.file.replace(/\.md$/, ".html")}">${escapeHtml(page.title)}</a>`)
		.join("\n");
	return `<nav class="sidebar" aria-label="Documentation"><h2>Docs</h2>\n${links}\n</nav>`;
}

function documentPage(title: string, nav: string, body: string): string {
	const safeTitle = escapeHtml(title);
	return `<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><meta name="description" content="${safeTitle} — my-ai-tools documentation"><title>${safeTitle} · my-ai-tools</title><link rel="stylesheet" href="style.css"></head>
<body><header class="site-header"><div class="header-inner"><a class="brand" href="../">my-ai-tools</a><a class="back" href="./">Documentation index</a></div></header>
<div class="layout">${nav}<main><article>
${body}
</article></main></div></body></html>
`;
}

function indexPage(pages: Page[], nav: string): string {
	const items = pages
		.map(
			(page) =>
				`<li><a href="${page.file.replace(/\.md$/, ".html")}">${escapeHtml(page.title)}</a></li>`,
		)
		.join("\n");
	const body = `<h1>Documentation</h1>
<p>Practical guides and notes for my-ai-tools.</p>
<ul class="doc-list">
${items}
</ul>`;
	return documentPage("Documentation", nav, body);
}

const pages = loadPages();
const published = new Set(pages.map((page) => page.file));
const nav = sidebar(pages);

writeFileSync(resolve(docsDir, "index.html"), indexPage(pages, nav));
for (const page of pages) {
	const body = renderMarkdown(page.markdown, published);
	const html = documentPage(page.title, nav, body);
	writeFileSync(resolve(docsDir, page.file.replace(/\.md$/, ".html")), html);
}

console.log(`rendered ${pages.length} docs pages`);
