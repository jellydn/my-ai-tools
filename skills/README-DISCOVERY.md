# Discovery Skills for Next-Generation AI Models

Based on Thariq Shihipar's "Field Guide to Fable" talk at AI Engineer 2026, these skills help agents systematically discover unknowns before implementation.

## The Problem: Map vs Territory

Your prompt/plan is the **map**. The actual codebase and constraints are the **territory**. When the agent encounters something in the territory not in the map, that's an **unknown**.

Advanced models can traverse vast solution spaces, making unknown discovery critical before implementation.

## Discovery Workflow

```text
1. blindspot-pass → Identify unknown unknowns
2. spec-interview → Clarify requirements  
3. [Implementation with logging]
4. quiz-me → Verify understanding
```markdown

## Skills

### 1. Blind Spot Pass

**File**: `skills/blindspot-pass/SKILL.md`
**Command**: `/blindspots [task]` (Claude)

Searches for unknown unknowns before starting work:
- Git history for gotchas
- Existing patterns to follow
- Test requirements
- Integration points
- Architectural considerations

**Example**:
```text
/blindspots Add webhook support for third-party integrations
```markdown

Returns structured analysis with:
- Context sources checked
- Key architectural patterns
- Known gotchas
- Testing requirements
- Questions to answer
- Recommended approach

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
```markdown

Returns prioritized questionnaire with:
- Context for each question
- Multiple choice options
- Impact explanation
- Implementation implications

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
```markdown

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
```markdown

## Integration Example

### Before Implementation

```bash
# 1. Discover unknowns
/blindspots Add GitHub OAuth integration

# Agent searches codebase, finds patterns, identifies gotchas
# Agent: "Found existing OAuth pattern, here are 5 gotchas..."

# 2. Clarify requirements
/interview-me Add GitHub OAuth integration

# Agent: "I have 3 architecture-changing questions..."
# User answers questions

# 3. Start implementation with logging
# Agent creates .implementation-log.md
# Tracks decisions as reality diverges from plan
```markdown

### During Implementation

```markdown
# .implementation-log.md

### Decision 1: Use GitHub App Installation Flow

**When**: During initial auth flow implementation
**Context**: Testing revealed org-level access requires App Installation
**Original Plan**: Standard OAuth with PAT
**Reality**: GitHub deprecated PAT for org access
**Decision**: Implement GitHub App Installation flow
**Rationale**: Only way to get org-level repo access
**Impact**: Added webhook endpoint, installation table, token caching
```markdown

### After Implementation

```bash
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

## The Four Unknowns

```text
                Known to You    Unknown to You
Known Exists    Known Knowns    Known Unknowns
Unknown Exists  Unknown Knowns  Unknown Unknowns
```markdown

**Known Knowns**: What's explicit in your prompt
**Known Unknowns**: Questions you know you need to answer
**Unknown Knowns**: Obvious to you but not written down
**Unknown Unknowns**: What you haven't considered at all

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

## Implementation Roadmap

See `.planning/fable-improvements.md` for the full 5-phase implementation plan:
- Phase 1: Streamline system prompts (context over constraints)
- Phase 2: Add discovery tools (these skills)
- Phase 3: Enhance context access (MCP integration, git history)
- Phase 4: Capability discovery (experiment with Fable's new abilities)
- Phase 5: Remove hobbles (eliminate outdated constraints)
