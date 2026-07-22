# Teaching Notes & Preferences

- **Environment**: macOS host.
- **Preferred Run Tool**: Bun (e.g., `bun run scripts/compare-chunking.ts`) or `tsx` if Bun has path resolution issues.
- **Learning Journey Focus**: 30-Day AI Learning.
- **Current Day**: Day 9 — Chunking (referencing Day 8 — Embeddings).
- **Core Repository Context**: Jellydn's `my-ai-tools` repository. In PR 309, we implemented a custom semantic chunker inside `lib/code-taste/chunker.ts` which uses `web-tree-sitter` for TS/TSX AST-level chunking and markdown heading-based chunking.
- **Teaching Style**:
  - Visual-first simulators.
  - Interactive browser interfaces to lower friction.
  - Command-line tools for hands-on experimentation.
  - Storage-strength quizzes with equal-length options.
