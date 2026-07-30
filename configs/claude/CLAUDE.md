# Claude Code Guidelines

Use judgment. These instructions define outcomes, not a mandatory workflow.

## Token-Efficient Sessions

- Keep responses concise and actionable. Lead with conclusions, file paths, and verification results.
- Scope discovery to the task. Prefer targeted graph, `fff`, `rg`, or `fd` queries over broad searches and full-file dumps.
- Limit command output with filters, path scopes, and line ranges. Do not load documentation until it is relevant.
- Run `/context` during long sessions. Use `/clear` after finishing a task or when switching to unrelated work.
- Use `/handoffs` and `/pickup` when useful context must survive a reset.

## Working with Advanced Models (Fable/4.8+)

- You are more capable than the examples given here. These guidelines provide context and outcomes, not prescriptive steps. Use judgment and discovery.
- For a comprehensive guide on capability overhang, finding unknowns, and being unreasonable (in the best way), read `~/.ai-tools/fable-guide.md`. Do not load it for routine work.

## Discovery and Planning

For familiar, focused work, proceed with existing patterns. For unfamiliar or complex work:

1. Identify unknowns with `/blindspots` or the `blindspot-pass` skill.
2. Use `context-discovery`, graph, git history, and documentation tools only as the task requires.
3. Use `/interview-me` when an unanswered question would materially change the solution.
4. Propose phased plans only for large or risky changes.

Apply reasoning to new situations (context over constraints).

## Tools for Discovery

- `/blindspots [task]` - Find unknown unknowns before starting
- `/interview-me [feature]` - Clarify spec gaps with targeted questions
- `/map-from [reference]` - Learn from example code
- Context discovery (`context-discovery` skill) - Proactive MCP tool usage
- Git history context (`git-context` skill) - Commit history and patterns
- Documentation search (`doc-search` skill) - Find ADRs, wiki, conventions
- Capability experiments (`capability-experiments` skill) - HTML reports, proactive research
- Implementation logging (`implementation-logger` skill) - Track deviations
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

For full details, read `~/.ai-tools/best-practices.md` only when the repository lacks equivalent guidance or the task needs its detailed development workflow.

## Search & Discovery Tools

- Prefer code graph tools for symbol relationships, `fff` for file discovery, and `sem` for semantic git context when available.
- Prefer `rg` and `fd` over `grep` and `find` in shell searches.
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
- Prefer Bun for scripts, `tsx` for TS files when Bun is unsuitable
- Test your changes before finishing

Read `~/.ai-tools/git-guidelines.md` before destructive or history-changing git operations.

## Knowledge Management

- Read `~/.ai-tools/MEMORY.md` (durable learnings/qmd) and `~/.ai-tools/agent-memory.md` (session notes/agentmemory) only when deciding whether or where to persist a learning.
- Use implementation logs only for complex work with meaningful plan deviations.
- After a confirmed bug fix or durable technical decision, offer to record the learning.

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
- For more details, read `~/.ai-tools/fable-guide.md` section on "Being Unreasonable".
