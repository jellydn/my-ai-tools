# Discovery Skills for Next-Generation AI Models

Based on Thariq Shihipar's "Field Guide to Fable" talk at AI Engineer 2026, these skills help agents systematically discover unknowns before implementation.

## The Problem: Map vs Territory

Your prompt/plan is the **map**. The actual codebase and constraints are the **territory**. When the agent encounters something in the territory not in the map, that's an **unknown**.

Advanced models can traverse vast solution spaces, making unknown discovery critical before implementation.

This file also lists every skill in `skills/` (see [Skill Catalog](#skill-catalog)) and explains how an agent finds,
installs, and uses them (see [Using These Skills with AI Agents](#using-these-skills-with-ai-agents)).

## Discovery Workflow

For non-trivial AI-assisted work that needs a broader accountable process, load
[`accountable-engineering`](accountable-engineering/SKILL.md); it points to each discovery skill only when that branch
applies.

```text
1. blindspot-pass → Identify unknown unknowns
2. spec-interview → Clarify requirements
3. [Implementation with logging]
4. quiz-me → Verify understanding
```

## Skill Catalog

Each name and description comes from the skill's `SKILL.md` frontmatter. **Manual** marks skills with
`disable-model-invocation: true`: the agent does not load them by itself, so invoke them by name (for example
`/retro` in Claude Code, or "use the retro skill").

### Discovery and planning

| Skill | Description |
| --- | --- |
| [`accountable-engineering`](accountable-engineering/SKILL.md) | Use explicit human checkpoints for architecture, security, rollout, or operational decisions. |
| [`blindspot-pass`](blindspot-pass/SKILL.md) | Inspect history and architecture for hidden constraints before risky cross-cutting changes. |
| [`spec-interview`](spec-interview/SKILL.md) | Clarify requirements through targeted questions — uncovers unknown unknowns in specs. |
| [`context-discovery`](context-discovery/SKILL.md) | Use MCP tools to trace behavior that spans multiple modules or history sources. |
| [`git-context`](git-context/SKILL.md) | Search git history for context — commit messages, blame, related changes, impact analysis. |
| [`doc-search`](doc-search/SKILL.md) | Search project documentation — ADRs, wiki entries, conventions via ripgrep, qmd, fff, and ctx. |
| [`codemap`](codemap/SKILL.md) | Create a seven-document architecture map when the user asks to map a codebase. |
| [`capability-experiments`](capability-experiments/SKILL.md) | Build an interactive report or experiment when the user asks to explore model capabilities. |
| [`prd`](prd/SKILL.md) | Generate Product Requirements Documents from feature ideas — plans specs and requirements. |
| [`ralph`](ralph/SKILL.md) (manual) | Convert PRDs to prd.json format for the Ralph autonomous agent system. |
| [`plannotator-setup-goal`](plannotator-setup-goal/SKILL.md) (manual) | Turn ideas into executable goal packages with guided interviews and codebase analysis. |

### Implementation and debugging

| Skill | Description |
| --- | --- |
| [`implementation-logger`](implementation-logger/SKILL.md) | Log implementation decisions — tracks deviations from plan and captures rationale. |
| [`implement-spec`](implement-spec/SKILL.md) (manual) | Implement a complete spec from its ticket graph, using isolated workers and one integration branch. |
| [`orchestrating-fusion`](orchestrating-fusion/SKILL.md) | Coordinate a read-only lead and implementation executor when role separation is requested. |
| [`tdd`](tdd/SKILL.md) | Guide through the Red-Green-Refactor cycle for test-driven development. |
| [`diagnosing-bugs`](diagnosing-bugs/SKILL.md) | Build a tight, red-capable feedback loop before diagnosing failures, then minimize, test ranked hypotheses, and lock the fix with a regression test. |
| [`tmux`](tmux/SKILL.md) | Control tmux sessions remotely — send commands, capture output, manage panes. |
| [`portless-local`](portless-local/SKILL.md) (manual) | Replace port numbers with stable named .localhost URLs for local development. |

### Review and quality

| Skill | Description |
| --- | --- |
| [`code-review`](code-review/SKILL.md) | Review a branch, PR, or worktree diff for repository conventions and stated intent. |
| [`code-quality-review`](code-quality-review/SKILL.md) (manual) | Audit a diff for structural maintainability and unnecessary complexity. |
| [`security-audit`](security-audit/SKILL.md) | Use when reviewing code for security vulnerabilities, hardening an application, or deriving security requirements from OWASP/ASVS guidance. |
| [`slop`](slop/SKILL.md) | Remove AI-generated code slop from git diffs to maintain code quality. |
| [`quiz-me`](quiz-me/SKILL.md) | Verify understanding after implementation with targeted quizzes. |

### Git and pull requests

| Skill | Description |
| --- | --- |
| [`commit-atomic`](commit-atomic/SKILL.md) | Group staged changes into atomic commits with commitizen convention. |
| [`draft-pull-request`](draft-pull-request/SKILL.md) (manual) | Draft pull requests with structured descriptions using gh CLI. |
| [`pr`](pr/SKILL.md) | Write a fast-to-review pull request body with a visual summary, before/after evidence, and merge-risk analysis. |
| [`visual-pr`](visual-pr/SKILL.md) (manual) | Posts a concise visual outline as a GitHub pull request comment. Use only when the user explicitly asks for visual-pr. |
| [`pr-review`](pr-review/SKILL.md) | Fix PR review comments by implementing requested changes. |
| [`babysit-pr`](babysit-pr/SKILL.md) | Use when monitoring an open GitHub PR for CI failures, review feedback, mergeability, and safe retries or fixes. |

### Documentation and knowledge

| Skill | Description |
| --- | --- |
| [`adr`](adr/SKILL.md) | Record architecture decisions with ADRs — captures why, alternatives considered, and consequences. |
| [`docs-update`](docs-update/SKILL.md) (manual) | Update docs when code changes — reviews commits and syncs user-facing documentation. |
| [`qmd-knowledge`](qmd-knowledge/SKILL.md) | Manage project knowledge with qmd — captures learnings, decisions, and conventions. |
| [`llm-wiki`](llm-wiki/SKILL.md) | Build a persistent compounding wiki from raw sources using the LLM Wiki pattern. |

### Sessions and retrospectives

| Skill | Description |
| --- | --- |
| [`handoffs`](handoffs/SKILL.md) | Create handoff plans for continuing work across sessions. |
| [`pickup`](pickup/SKILL.md) (manual) | Resume work from previous handoff sessions stored in .planning/handoffs/. |
| [`retro`](retro/SKILL.md) (manual) | Review a coding session and propose environment changes that prevent repeated agent mistakes. |
| [`cost-review`](cost-review/SKILL.md) | Analyze AI coding spend across harnesses (Amp, Claude Code, Codex) and attribute cost changes with a five-term decomposition. |

## Using These Skills with AI Agents

### How an agent finds the right skill

1. **Match the task to a skill.** Read the [Skill Catalog](#skill-catalog), or list every skill's frontmatter:

   ```bash
   rg -n '^(name|description|hint):' skills/*/SKILL.md
   ```

   The `description` says what the skill does; the `hint` says when to use it.

2. **Check what is installed.** Installed skills live in the universal directory `~/.agents/skills/`. Tool
   directories such as `~/.claude/skills/` link to it.

   ```bash
   ls ~/.agents/skills/
   ```

3. **Install what is missing.** Install one skill, all skills, or run the full installer:

   ```bash
   npx skills add jellydn/my-ai-tools --skill blindspot-pass --global --agent claude-code  # one skill
   npx skills add jellydn/my-ai-tools --yes --global --agent claude-code                   # all skills
   ./cli.sh --dry-run && ./cli.sh                                                          # from a checkout
   ```

4. **Use it.** Most agents load a skill automatically when the task matches its description. For a skill marked
   **manual**, name it in the prompt or invoke it as a slash command (`/<skill-name>` in Claude Code).

### Example prompts

```text
Read skills/README-DISCOVERY.md and tell me which skills fit this task: add OAuth login to the API.
Install any that are missing from ~/.agents/skills/, then use them.
```

```text
Use the blindspot-pass skill before you change the retry logic in lib/install.sh.
```

```text
Which skill fixes review comments on PR #42? Load it and address the comments.
```

```text
The test in tests/cli.bats is flaky. Use the diagnosing-bugs skill, then commit the fix with commit-atomic.
```

```text
/retro   # manual skill: review this session and propose guidance changes
```

## Discovery Skills in Detail

### 1. Blind Spot Pass

**File**: `skills/blindspot-pass/SKILL.md`
**Command**: `/blindspot-pass [task]` (Claude)

Searches for unknown unknowns before starting work:
- Git history for gotchas
- Existing patterns to follow
- Test requirements
- Integration points
- Architectural considerations

**Example**:

```text
/blindspot-pass Add webhook support for third-party integrations
Returns structured analysis with:
- Context sources checked
- Key architectural patterns
- Known gotchas
- Testing requirements
- Questions to answer
- Recommended approach
```

### 2. Spec Interview

**File**: `skills/spec-interview/SKILL.md`
**Command**: `/interview-me [feature]` (Claude)

Generates targeted questions to fill specification gaps:
- Architecture-changing questions (highest priority)
- High-impact decisions
- Medium-impact choices
- Low-impact details

**Example**:
```text
/interview-me Add real-time collaboration to document editor

Returns prioritized questionnaire with:
- Context for each question
- Multiple choice options
- Impact explanation
- Implementation implications
```

**Advanced**: For Fable/4.8+, can generate embedded HTML questionnaires with radio buttons and instant feedback.

### 3. Implementation Logger

**File**: `skills/implementation-logger/SKILL.md`

Tracks decisions and deviations during complex work:
- Where reality differed from plan
- Decision rationale
- Impact on other components
- Unknown unknowns discovered

Creates `.implementation-log.md` during work, then extracts to:
- PR descriptions
- Architecture Decision Records (ADRs)
- MEMORY.md learnings
- Documentation updates

**Template**:
```markdown
# Implementation Log: [Feature]

## Original Approach
[What we planned]

## Deviations & Decisions

### Decision 1: [Title]
**Context**: [What prompted this]
**Original Plan**: [What we thought]
**Reality**: [What we found]
**Decision**: [What we did]
**Rationale**: [Why]
**Impact**: [Side effects]

## Unknowns Discovered
[What we didn't know]

## Learnings
[What worked, what surprised us, what to do differently]
```

### 4. Quiz Me

**File**: `skills/quiz-me/SKILL.md`
**Command**: `/quiz-me` (after implementation)

Generates quiz to verify understanding:
- Recall (what we did)
- Understanding (why we did it)
- Application (how it works)
- Analysis (trade-offs and implications)

Helps with:
- Writing PR descriptions
- Preparing for code review
- Staying "in the loop" with agent work
- Identifying documentation gaps

### 5. Context Discovery

**File**: `skills/context-discovery/SKILL.md`

Proactively gathers context using available MCP tools before and during implementation:
- **fff**: Find relevant files by name/pattern
- **sem**: Git history at function level
- **ctx**: Past agent sessions on the same topic
- **qmd**: Durable project knowledge and ADRs
- **codebase-memory-mcp**: Code structure and call chains

Includes a decision tree for which tool to use based on what you need to find.

### 6. Git Context

**File**: `skills/git-context/SKILL.md`

Searches git history to understand code evolution:
- Recent changes to a module
- Function history via `git log -S`
- Entity-level blame with `sem`
- Related changes across commits
- Impact analysis before making changes

### 7. Documentation Search

**File**: `skills/doc-search/SKILL.md`

Systematically finds and navigates existing project documentation:
- Locate ADRs, wiki entries, conventions, and guides
- Search documentation content with `rg` and `qmd`
- Query past agent sessions for documentation context
- Match existing documentation style before creating new docs
- Cross-reference related documentation

### 8. Capability Experiments

**File**: `skills/capability-experiments/SKILL.md`

Leverages advanced model capabilities for rich outputs and proactive exploration:
- **HTML reports**: Generate structured analysis with interactive elements
- **Embedded questionnaires**: Rich HTML forms for interviews and quizzes
- **Proactive research**: Self-directed codebase exploration patterns
- **Multi-step reasoning**: Structured analysis for complex decisions
- **Capability probes**: Explore what's newly possible with next-gen models

**Example Output**:
```markdown
# Quiz: GitHub OAuth Integration

## Section 1: Core Decisions

Q1: Why did we use GitHub App Installation flow?
a) OAuth is deprecated
b) Installation flow provides org-level access ✓
c) Installation flow is easier

Explain your choice: [Your answer]

## Section 2: Implementation Details

Q2: Describe the token caching strategy
[Open-ended answer]

[Continue through multiple levels of questions]
```

```markdown
## Integration Example

### Before Implementation

# 1. Discover unknowns
/blindspot-pass Add GitHub OAuth integration

# Agent searches codebase, finds patterns, identifies gotchas
# Agent: "Found existing OAuth pattern, here are 5 gotchas..."

# 2. Clarify requirements
/interview-me Add GitHub OAuth integration

# Agent: "I have 3 architecture-changing questions..."
# User answers questions

# 3. Start implementation with logging
# Agent creates .implementation-log.md
# Tracks decisions as reality diverges from plan
```

```markdown
### During Implementation

# .implementation-log.md

### Decision 1: Use GitHub App Installation Flow

**When**: During initial auth flow implementation
**Context**: Testing revealed org-level access requires App Installation
**Original Plan**: Standard OAuth with PAT
**Reality**: GitHub deprecated PAT for org access
**Decision**: Implement GitHub App Installation flow
**Rationale**: Only way to get org-level repo access
**Impact**: Added webhook endpoint, installation table, token caching
```

```markdown
### After Implementation

# 4. Verify understanding
/quiz-me

# Agent generates quiz on implementation
# Agent: "Q1: Why did we use Installation flow vs OAuth?"
# User answers, identifies knowledge gaps

# 5. Extract learnings
# Move log content to:
# - PR description
# - MEMORY.md
# - ADRs
# - Updated documentation
```

```markdown
## Benefits

### 1. Reduced Failed Implementations
Discovering unknowns upfront prevents mid-implementation pivots and dead ends.

### 2. Better Documentation
Implementation logs become PR descriptions and ADRs naturally.

### 3. Staying in the Loop
As agents become more capable, these skills keep you engaged at the right level of abstraction.

### 4. Knowledge Building
Systematic unknown discovery creates compounding knowledge over time.

### 5. Faster Iteration
Frontloading discovery means smoother implementation with fewer surprises.
```

## The Four Unknowns

```text
                Known to You    Unknown to You
Known Exists    Known Knowns    Known Unknowns
Unknown Exists  Unknown Knowns  Unknown Unknowns
```

```markdown

**Known Knowns**: What's explicit in your prompt
**Known Unknowns**: Questions you know you need to answer
**Unknown Knowns**: Obvious to you but not written down
**Unknown Unknowns**: What you haven't considered at all
```
These skills help surface all four categories before implementation.

## When to Use

### Always Use
- Complex or unfamiliar changes
- Critical infrastructure work
- High-stakes features
- When spec is vague

### Sometimes Use
- Medium complexity work
- Refactoring with unclear scope
- Integrations with many moving parts

### Skip for
- Trivial changes
- Well-understood patterns
- Small bug fixes
- Documentation updates

## Tool Philosophy

These skills embody "**context over constraints**":
- They don't prescribe how to code
- They help agents discover what they need to know
- They create positive guidance through discovery
- They let agents apply judgment to situations

## Related Resources

- **Fable Guide**: `configs/fable-guide.md` - Comprehensive guide to working with next-gen models
- **Video**: [Field Guide to Fable](https://www.youtube.com/watch?v=9fubhllmsBU) - Original talk by Thariq Shihipar
- **Best Practices**: `configs/best-practices.md` - Updated with discovery-first approach
- **Claude Config**: `configs/claude/CLAUDE.md` - Discovery-first guidelines

## Key Principles

1. **Discovery before Direction**: Find unknowns before prescribing solutions
2. **Questions over Assumptions**: Encourage asking when uncertain
3. **Tools over Instructions**: Give capabilities, not recipes
4. **Outcomes over Process**: Define success, not how to achieve it
5. **Context over Constraints**: Show what good looks like, don't list don'ts
