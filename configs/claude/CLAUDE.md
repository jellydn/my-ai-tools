# 🤖 Claude Code Agent Guidelines

## Working with Advanced Models (Fable/4.8+)

**Key shift**: You're more capable than the examples I give you. These guidelines provide context and outcomes, not prescriptive steps. Use judgment and discovery.

See @~/.ai-tools/fable-guide.md for comprehensive guide on capability overhang, finding unknowns, and being unreasonable (in the best way).

## Discovery-First Approach

Before jumping into implementation:

**For unfamiliar/complex work**:
1. Run a blind spot pass (@skills/blindspot-pass/) to identify unknowns
2. Discover context using MCP tools (@skills/context-discovery/) — fff, sem, ctx, qmd
3. Interview me (@skills/spec-interview/) if major decisions unclear
4. Search git history for patterns
5. Propose approach based on findings

**Context over constraints**: These guidelines explain why, not just what. Apply reasoning to new situations.

## Tools for Discovery

- `/blindspots [task]` - Find unknown unknowns before starting
- `/interview-me [feature]` - Clarify spec gaps with targeted questions  
- `/map-from [reference]` - Learn from example code
- Context discovery (@skills/context-discovery/) - Proactive MCP tool usage
- Git history context (@skills/git-context/) - Commit history and patterns
- Documentation search (@skills/doc-search/) - Find ADRs, wiki, conventions
- Capability experiments (@skills/capability-experiments/) - HTML reports, proactive research
- Implementation logging (@skills/implementation-logger/) - Track deviations
- `/quiz-me` - Verify understanding after completion

## Session Management

Run long-running commands in tmux with directory-based session names:

```bash
SESSION=$(basename "$PWD")
tmux new -d -s "$SESSION"
tmux send-keys -t "$SESSION" 'npm run dev' Enter
tmux capture-pane -p -t "$SESSION" -S -20  # Check without attaching
```

For AI-enhanced monitoring: `logpilot watch "$SESSION"`

See @~/.ai-tools/best-practices.md for full details.

## Search & Discovery Tools

- Use fff MCP tools for file operations
- Use sem MCP tools for semantic git operations
- Prefer `fd` (fdfind) and `rg` (ripgrep) for searching
- Search git history for patterns: `git log --grep="term"`
- Look for TODOs/gotchas: `rg "TODO|FIXME|HACK|XXX"`

## Code Quality Principles

**Clarity and Simplicity**:
- Self-documenting code through clear naming and structure
- Modular, loosely coupled design
- Type safety (TypeScript inference over `any`)
- Comments explain why, not what

**Verification**:
- Run typecheck, lint, biome on JS/TS changes
- Prefer Bun for scripts, tsx for TS files
- Test your changes before finishing

## Knowledge Management

- @~/.ai-tools/MEMORY.md - Durable learnings (qmd) vs session notes (agentmemory)
- @~/.ai-tools/agent-memory.md - Auto-capture learnings, persist fixes
- Implementation logs - Track decisions during complex work
- After fixing bugs: Offer to record learnings

## Development Patterns

**Planning**:
- For familiar work: Proceed with standard patterns
- For complex work: Use discovery tools first
- Propose plans in phases for large changes

**Implementation**:
- Follow existing patterns when they exist
- Extract reusable abstractions when repeating
- Avoid premature optimization
- Keep changes focused and reviewable

**Iteration**:
- Commit atomic, logical changes
- Write clear commit messages (conventional commits)
- Track deviations in implementation log
- Quiz yourself to verify understanding

## Being Unreasonable (Productively)

Don't assume tradeoffs. Challenge constraints:
- Good + Fast + Cheap: Try for all three
- Force reality to show you the bottleneck
- Ask "what if we just did all of it?"
- Use tools to make hard things easy

See @~/.ai-tools/fable-guide.md section on "Being Unreasonable"
