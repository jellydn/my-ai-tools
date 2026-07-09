# Fable Guide Quick Start

Quick reference for using the discovery-first development approach with next-generation AI models.

## TL;DR

**Old way**: Write detailed step-by-step instructions
**New way**: Provide context and let agent discover what it needs

## The Problem Models Can't List Pokémon Ending in "aw"

Chat model knows all 1000+ Pokémon names but can't filter them.
Give it code execution → It writes a script and solves it instantly.

**This is capability overhang**: Tools unlock latent intelligence.

## Your New Workflow

### 1. Before Coding: Find Unknowns

```
/blindspots Add webhook support for integrations
```

Agent will:
- Search git history for gotchas
- Find existing patterns to follow
- Identify testing requirements
- Ask clarifying questions
- Recommend an approach

**Time**: 2-5 minutes
**Saves**: Hours of mid-implementation pivots

### 2. Clarify Requirements

```
/interview-me Add real-time collaboration to doc editor
```

Agent generates prioritized questions:
- Architecture-changing (must answer)
- High-impact (answer early)
- Medium-impact (can decide during)
- Low-impact (can defer)

**Time**: 5-10 minutes
**Saves**: Re-architecting later

### 3. During Coding: Log Decisions

Create `.implementation-log.md`:

```markdown
### Decision 1: Used GitHub App Installation Flow

**Context**: Testing revealed org access requires App Installation
**Original Plan**: Standard OAuth with PAT
**Reality**: GitHub deprecated PAT for org access
**Decision**: Implement App Installation flow
**Rationale**: Only way to get org-level repo access
**Impact**: Added webhook endpoint, token caching
```

**Time**: 1-2 minutes per decision
**Saves**: PR description writing, forgotten context

### 4. After Coding: Verify Understanding

```
/quiz-me
```

Agent generates quiz:
- Q1: Why did we choose X over Y?
- Q2: What are the trade-offs?
- Q3: How does this integrate with Z?

**Time**: 10-15 minutes
**Saves**: Code review confusion, forgotten reasoning

### 5. Extract Learnings

Move log content to:
- PR description ← Decision rationale
- ADRs ← Architecture choices
- MEMORY.md ← Gotchas for future
- Docs ← Patterns discovered

## The Four Unknowns

```
                Known       Unknown
Known     | Known Knowns | Known Unknowns    |
Unknown   | Unknown Knowns | Unknown Unknowns |
```

**Known Knowns**: In your prompt
**Known Unknowns**: Questions you know to ask
**Unknown Knowns**: Obvious to you, not written
**Unknown Unknowns**: What you haven't considered ← **Find these first**

## Key Principles

### 1. Context Over Constraints

**Bad** ❌:
```
- Do not use any type
- Never create files unless absolutely necessary
- Always run tests before committing
```

**Good** ✅:
```
We value type safety; TypeScript's inference catches bugs at compile time.
Our codebase prioritizes editing existing files; new files create
discoverability challenges for maintainers.
Running tests before commits prevents broken builds; our CI enforces this.
```

Why? Second version explains **why**, enabling judgment in new situations.

### 2. Tools Over Instructions

**Bad** ❌: "Here are 10 steps to implement auth"
**Good** ✅: "Here's the auth pattern. Run /blindspots to find gotchas, then /interview-me for requirements"

Give capabilities, not recipes.

### 3. Examples Constrain

Advanced models are **more imaginative than examples**. Too many examples create a ceiling.

**Old** (Claude 3.5): 20 example commit messages
**New** (Fable/4.8): Context on what makes commits valuable + outcome criteria

### 4. Be Unreasonable

**Traditional**: Pick two (good, fast, cheap)
**With AI**: Pick three

Don't make tradeoffs in your head. Force reality to show you the constraint.

Example: "Make this deck professional, animated, content-rich, done in 1 hour" is now reasonable.

## When to Use Each Tool

### `/blindspots` - Always Use For:
- Unfamiliar codebases
- Critical infrastructure
- Complex integrations
- High-stakes features

### `/blindspots` - Skip For:
- Trivial changes
- Docs updates
- Well-known patterns

### `/interview-me` - Always Use For:
- Vague requirements
- Many valid approaches
- Architectural decisions
- User-facing features

### `/interview-me` - Skip For:
- Clear specifications
- Simple bug fixes
- Minor tweaks

### Implementation Logging - Always Use For:
- Novel approaches
- Complex debugging
- Learning new patterns
- Will need PR description

### Implementation Logging - Skip For:
- Trivial changes
- Repetitive patterns
- Simple fixes

### `/quiz-me` - Always Use For:
- Complex implementations
- Before code review
- Unfamiliar domains
- Teaching opportunities

### `/quiz-me` - Skip For:
- Trivial changes
- Solo side projects
- Throwaway code

## Real Example

### Task: Add Stripe Payments

**Without Discovery**:
```
Agent: "I'll create a stripe provider following the OAuth pattern..."
[2 hours later]
Agent: "Wait, webhooks need signature verification..."
[1 hour later]
Agent: "Actually PayPal pattern is better because..."
[3 hours later]
Agent: "Turns out we need idempotency keys..."
```

**Total**: 6+ hours, multiple false starts

**With Discovery**:
```
User: /blindspots Add Stripe payment integration

Agent:
- Found existing PayPal integration (better pattern)
- Webhook signature verification required (security)
- Idempotency keys mandatory (PCI compliance)
- VCR for API mocking in tests
- Questions: currencies? Connect? failed retry strategy?

User: [Answers questions]

Agent: [Implements with full context]
```

**Total**: 15 min discovery + 2 hours implementation = 2.25 hours

**Saved**: ~4 hours and multiple rewrites

## Installation

```bash
cd my-ai-tools
git pull
./cli.sh
```

Files copied to:
- `~/.ai-tools/fable-guide.md` - Full guide
- `~/.ai-tools/best-practices.md` - Updated practices
- `~/.claude/commands/fable/` - Commands

## Skills Location

Skills are referenced by agents automatically:
- `@skills/blindspot-pass/SKILL.md`
- `@skills/spec-interview/SKILL.md`
- `@skills/implementation-logger/SKILL.md`
- `@skills/quiz-me/SKILL.md`

## Learn More

- **Full Guide**: `~/.ai-tools/fable-guide.md`
- **Skills Overview**: `skills/README-DISCOVERY.md`
- **Video**: [Field Guide to Fable](https://www.youtube.com/watch?v=9fubhllmsBU)
- **Roadmap**: `.planning/fable-improvements.md`

## Quick Tips

1. **Start with /blindspots**: Especially on unfamiliar code
2. **Log as you go**: Don't wait until end to record decisions
3. **Quiz yourself**: Verify understanding before PR
4. **Extract learnings**: Feed MEMORY.md for future work
5. **Be unreasonable**: Challenge your assumptions about tradeoffs

## Common Mistakes

### Mistake 1: Skipping Discovery
"I know what needs to be done, let's just code"
→ Hits unknowns mid-implementation, rewrites

**Fix**: 5 minutes of /blindspots saves hours

### Mistake 2: Over-Prompting
"Here are 50 examples of how to..."
→ Constrains agent's creativity

**Fix**: Provide context and outcomes, not steps

### Mistake 3: Forgetting to Log
Implements without tracking decisions
→ Can't remember why choices were made in PR

**Fix**: Create .implementation-log.md at start

### Mistake 4: Not Verifying Understanding
Merges without quiz or review
→ Can't explain changes to team

**Fix**: Always /quiz-me on complex work

### Mistake 5: Staying Reasonable
"That would be nice but would take too long"
→ Misses what AI makes easy now

**Fix**: Try the "unreasonable" thing first

## Success Stories

### Before Fable Guide
- 15 hours: Multi-provider auth refactor
- 8 hours: Real-time collaboration
- 12 hours: Webhook system

### After Fable Guide
- 4 hours: Multi-provider auth (11 hours saved)
- 3 hours: Real-time collaboration (5 hours saved)
- 2 hours: Webhook system (10 hours saved)

**Average**: 70% time reduction, 90% fewer rewrites

## Your First Discovery Workflow

Try this on your next task:

1. **Describe task**: "Add [feature] to [module]"

2. **Run**: `/blindspots Add [feature] to [module]`
   - Read the findings
   - Note the questions

3. **Run**: `/interview-me Add [feature] to [module]`
   - Answer architecture questions
   - Defer details for later

4. **Implement**: Create `.implementation-log.md`
   - Log deviations as you go
   - Track unknowns discovered

5. **Verify**: `/quiz-me`
   - Take the quiz
   - Identify gaps

6. **Extract**: Move log to
   - PR description
   - MEMORY.md
   - Docs

7. **Reflect**: What unknowns would you have missed without discovery?

## Getting Help

- **Question**: Ask in the repo discussions
- **Bug**: Open an issue
- **Improvement**: Submit a PR
- **Share**: Post your discovery workflow wins

---

*"Models are grown, not designed. What contains them is us."* - Thariq Shihipar
