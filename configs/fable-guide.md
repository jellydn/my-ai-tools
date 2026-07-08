# Working with Next-Generation AI Models (Fable Guide)

## Core Philosophy

Models are grown, not designed. What contains them is us—the harness, prompts, and tools we provide. This guide helps you **unhobble** AI agents to reach their full capability.

## Capability Overhang

Models get smarter in **spiky ways**. The tools you give them determine which capabilities you can access.

**Example**: A chat model can't list Pokémon names ending in "aw" even though it knows every Pokémon. But give it code execution, and it writes a script to filter and solve it instantly.

Your role: Discover what's newly possible and provide the right tools.

## The Map and Territory Problem

**Map**: Your prompt, plan, and mental model
**Territory**: Actual codebase, constraints, runtime behavior

When the agent encounters something in the territory not in the map, that's an **unknown**. Your goal is to find unknowns before they become blockers.

### The Four Unknowns

```
                Known to You    Unknown to You
Known Exists    Known Knowns    Known Unknowns
Unknown Exists  Unknown Knowns  Unknown Unknowns
```

- **Known Knowns**: What's in your prompt
- **Known Unknowns**: Questions you know you need to answer
- **Unknown Knowns**: Obvious to you but not written down
- **Unknown Unknowns**: What you haven't considered at all

## Discovery Techniques

### 1. Blind Spot Pass

Before starting implementation, ask the agent to identify unknowns:

```
I'm working on [task] in this codebase. Do a blind spot pass:
- Search the relevant modules
- Check git history for gotchas
- Identify unknown unknowns that could change my approach
```

### 2. Brainstorm & Prototype

For design decisions, generate options to react to:

```
Create 4 widely different design approaches for [feature].
Show me HTML prototypes so I can identify what I want.
```

### 3. Interview Mode

Let the agent fill spec gaps:

```
Interview me about this feature. Prioritize questions that would
change the architecture or uncover hidden requirements.
```

### 4. Reference Mapping

Provide examples instead of explanations:

```
Here's code that shows what I want. Read it, extract the patterns,
and apply them to our codebase.
```

### 5. Implementation Notes

During execution, track deviations:

```
As you implement, log any deviations from the original plan and why.
This helps me understand where reality differed from my mental model.
```

### 6. Knowledge Verification

After implementation, test understanding:

```
Quiz me on what you just implemented. Help me verify I understand
the changes well enough to explain them in the PR.
```

## Context Discovery

Before starting any non-trivial implementation, proactively gather context using available tools:

### Where to Look

| Tool | What It Finds | Why It Matters |
|------|--------------|----------------|
| `fff` | Files by name/path | Find relevant files fast |
| `sem` | Git history at function level | Understand why code changed |
| `ctx` | Past agent sessions | Previous discussions and decisions |
| `qmd` | Durable knowledge, ADRs | Project conventions and learnings |
| `codebase-memory-mcp` | Code structure graph | Functions, classes, call chains |

### Discovery Workflow

1. **Find files**: `fff` to locate relevant modules
2. **Understand history**: `sem` / `git log -S` to trace how the code evolved
3. **Check past work**: `ctx search` for previous agent sessions on this topic
4. **Check project memory**: `qmd query` for ADRs, conventions, gotchas
5. **Deep code analysis**: `codebase-memory-mcp` for call chains and structure
6. **Documentation search**: `doc-search` for ADRs, wiki entries, conventions

See @skills/context-discovery/ for detailed guidance.
See @skills/git-context/ for git-specific context gathering.
See @skills/doc-search/ for documentation-specific search.

## System Prompt Principles

### What Changed with Advanced Models

**Old approach** (Claude 3.5):
- Small system prompt
- Lots of detailed examples
- Many specific instructions
- Prescriptive steps

**New approach** (Fable/4.8+):
- **Minimal system prompt** (80% reduction)
- **Fewer examples** (they constrain imagination)
- **Context, not constraints** (show outcomes, not steps)
- **Positive guidance** (avoid "do not" directives)

### Why Examples Constrain

Advanced models are **more imaginative than the examples we give them**. Heavy examples create a ceiling, not a floor.

**Instead of**: 20 examples of good commit messages
**Provide**: Context on what makes commits valuable + outcome criteria

### Context Over Constraints

**Avoid** ❌:
- "Do not use any type"
- "Never create files unless absolutely necessary"
- "Always run X before Y"

**Prefer** ✅:
- "We value type safety; TypeScript's inference helps catch bugs"
- "Our codebase prioritizes editing existing files; new files create discoverability challenges"
- "Running X before Y ensures Z, which prevents common issues"

The second approach explains **why** and lets the agent apply judgment.

## Working with HTML and Rich Output

Advanced models can generate **embedded HTML** for rich interaction:

- Questionnaires with multiple choice options
- Interactive reports with collapsible sections
- Embedded demos and visualizations
- Progress dashboards

**Encourage agents to use rich formatting** when it improves communication.

## Being Unreasonable (In the Best Way)

### The False Tradeoff

Traditional engineering: "Pick two: Good, Fast, Cheap"

With AI assistance: **Pick three**

Don't make tradeoffs in your head. Force reality to show you the constraint. Often, the constraint doesn't exist—it's a habit from when code was harder.

### How to Be Productively Unreasonable

1. **List everything you want**
2. **Ask the agent to do all of it**
3. **See what's actually hard** (vs what you assumed was hard)
4. **Iterate on the real bottlenecks**

Example: "Make this deck look professional, include animations, generate all content, and finish in an hour" is no longer unreasonable.

## Tool Philosophy

### Give Arms, Not Instructions

Models are like a brain without a body. Tools are the arms.

**Core tools to consider**:
- Code execution (for computation and filtering)
- File system access (for context building)
- Search capabilities (for finding patterns)
- Git operations (for history and patterns)
- Network access (for fetching data)

**The Pokémon principle**: If the model knows something but can't access it, give it a tool to retrieve and process it.

## Staying in the Loop

As agents become more capable, **your role shifts**:

- From: Writing detailed specifications
- To: Identifying unknowns and providing context

**Key practices**:
- Ask agents to explain their reasoning
- Request implementation notes
- Review deviations from plan
- Verify your understanding with quizzes
- Stay engaged with the process

The goal isn't to disconnect—it's to work at a higher level of abstraction while maintaining deep understanding.

## Practical Examples

### Example 1: Adding Auth Provider

**Old prompt**:
```
Add a new OAuth provider for GitHub. Follow these steps:
1. Create a new file in /auth/providers/
2. Implement the OAuthProvider interface
3. Add to the provider registry
4. Update the config schema
...
```

**New prompt**:
```
I need to add GitHub as an OAuth provider. I know nothing about our
auth system. Do a blind spot pass first, then interview me about
requirements before implementing.
```

### Example 2: UI Component

**Old prompt**:
```
Create a modal component with these props: isOpen, onClose, title, children.
Style it with Tailwind. Make it accessible with ARIA attributes.
```

**New prompt**:
```
I need a modal component. Here's our existing button component as a
reference for our design patterns. Create 3 different styling approaches
using our design system, then I'll choose which direction to go.
```

### Example 3: Performance Optimization

**Old prompt**:
```
Optimize the dashboard load time. Use React.memo, implement virtualization,
lazy load components, and split the bundle.
```

**New prompt**:
```
Dashboard is slow. Do a blind spot pass on performance bottlenecks.
Add instrumentation to measure before/after. Propose solutions prioritized
by impact vs effort.
```

## Biology vs Physics

Model behavior is **closer to biology than physics**:
- It's empirical and organic
- We learn with the model as we use it
- There's intuition to build, not just rules to follow
- Capabilities emerge in unexpected ways

**Approach development as discovery**, not engineering.

## Learning and Iteration

After completing work:

1. **Reflect on unknowns encountered**
2. **Update your mental model** of what's possible
3. **Document surprising capabilities** for future reference
4. **Record gotchas** in your knowledge base
5. **Share learnings** with your team

The field is evolving fast. What's impossible today may be trivial tomorrow.

## References

- [Field Guide to Fable - Thariq Shihipar (AI Engineer 2026)](https://www.youtube.com/watch?v=9fubhllmsBU)
- [The Biology of a Large Language Model - Anthropic Research](https://www.anthropic.com/)
- Capability overhang: When model intelligence exceeds our ability to harness it
