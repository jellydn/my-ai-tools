# AI Tools Improvements Based on Fable Field Guide

## Context

Based on Thariq Shihipar's talk "Field Guide to Fable" (AI Engineer, July 2026), this document outlines improvements to our AI tools configuration to maximize effectiveness with next-generation models like Fable.

## Key Insights from Talk

### 1. Unhobbling Claude
- **Capability Overhang**: Models get smarter in spiky ways; tools unlock capabilities
- **System Prompt Evolution**: Cut 80% of system prompt; fewer examples, more context
- **Examples Constrain**: Fable is more imaginative than examples we give it
- **Context > Constraints**: Avoid "do not do this" directives; provide positive guidance

### 2. Finding Your Unknowns
- **Map vs Territory**: Prompt/plan (map) vs actual codebase/constraints (territory)
- **Unknown Categories**:
  - Known knowns: What's in your prompt
  - Known unknowns: What you haven't figured out yet
  - Unknown knowns: What's obvious but unwritten
  - Unknown unknowns: What you haven't considered

### 3. Techniques for Discovery
- **Blind Spot Pass**: Ask Claude to identify relevant unknowns before starting
- **Brainstorm & Prototype**: Generate options to reveal unknown knowns
- **Interviews**: Let Claude question you about spec gaps
- **References**: Provide example code as a map
- **Implementation Notes**: Log deviations during execution
- **Quiz Me**: Verify understanding after implementation

### 4. Being Unreasonable
- **Pick Three**: Good, fast, cheap - demand all three
- **Challenge Tradeoffs**: Force reality to show you the constraint
- **Best Work Faster**: Prove agents work by doing best work of your life, faster

## Proposed Improvements

### Phase 1: Streamline System Prompts

**Goal**: Reduce constraint-heavy instructions; increase contextual guidance

**Changes**:
1. Audit all `AGENTS.md` and `CLAUDE.md` files for negative constraints
2. Replace "do not" directives with positive patterns and context
3. Remove redundant examples that constrain imagination
4. Focus on outcomes and context, not prescriptive steps

**Files to Update**:
- `configs/claude/CLAUDE.md`
- `configs/best-practices.md`
- `configs/claude/agents/*.md`
- `AGENTS.md`

### Phase 2: Add Discovery Tools

**Goal**: Help agents find unknowns before implementation

**New Commands/Skills**:
1. **Blind Spot Analysis** (`/blindspots`)
   - Identify unknown unknowns in codebase
   - Surface relevant gotchas before coding
   - Search git history, docs, Slack for context

2. **Spec Interview** (`/interview-me`)
   - Generate questions to fill spec gaps
   - Focus on architecture-changing decisions
   - Prioritize by impact on implementation

3. **Reference Mapper** (`/map-from`)
   - Accept reference implementation
   - Extract patterns and intentions
   - Adapt to current codebase context

4. **Implementation Logger** (`/log-deviations`)
   - Track where reality diverged from plan
   - Capture decision rationale
   - Build knowledge base of unknowns

5. **Knowledge Verification** (`/quiz-me`)
   - Generate quiz on implemented changes
   - Verify understanding for PR descriptions
   - Ensure agent stays in the loop

### Phase 3: Enhance Context Access

**Goal**: Give agents better tools to build their own context

**Improvements**:
1. **Enhanced MCP Integration**
   - Expand use of fff (file search) and sem (semantic git)
   - Add project-specific context sources
   - Enable proactive context gathering

2. **Git History Context**
   - Add tools to search commit messages
   - Reference previous PRs for patterns
   - Learn from past decision discussions

3. **Documentation References**
   - Link to ADRs (Architecture Decision Records)
   - Reference skills and conventions
   - Surface relevant wiki entries

### Phase 4: Capability Discovery

**Goal**: Systematically discover what's now possible with Fable

**Experiments**:
1. **HTML Reports**: Leverage Fable's HTML generation for rich outputs
2. **Embedded Questionnaires**: Use ask-user-question tool more creatively
3. **Proactive Research**: Test Fable's ability to self-direct exploration
4. **Multi-step Reasoning**: Push boundaries on complex architectural decisions

### Phase 5: Remove Hobbles

**Goal**: Identify and remove constraints from previous model generations

**Audit Areas**:
1. Tool restrictions that may no longer be needed
2. Overly prescriptive workflows
3. Examples that limit creative solutions
4. Safety guardrails that are too restrictive

## Implementation Strategy

### Week 1: Audit & Document
- Review all agent configuration files
- Document current constraints and examples
- Identify candidate sections for simplification

### Week 2: Phase 1 - Streamline
- Rewrite system prompts with context focus
- Remove negative constraints
- Test with real coding tasks

### Week 3: Phase 2 - Discovery Tools
- Build blind spot analysis skill
- Create interview and mapping commands
- Add implementation logging

### Week 4: Phase 3 - Context Enhancement
- Improve MCP tool integration
- Add git history context tools
- Link documentation better

### Week 5: Phase 4-5 - Experiment & Refine
- Test capability boundaries
- Remove identified hobbles
- Document learnings

## Success Metrics

1. **Prompt Simplicity**: Reduce system prompt size by 40-60%
2. **First-Time Success**: Increase successful first-attempt implementations
3. **Context Discovery**: Measure agent's ability to find relevant context without prompting
4. **Unknown Detection**: Track how often agents identify spec gaps before they cause issues
5. **Implementation Quality**: Maintain or improve code quality with less prescriptive guidance

## Key Principles to Maintain

1. **Context over Constraints**: Always prefer showing what good looks like
2. **Tools over Instructions**: Give capabilities, not recipes
3. **Questions over Assumptions**: Encourage agents to ask when uncertain
4. **Discovery over Direction**: Let agents explore the solution space
5. **Outcomes over Process**: Define what success looks like, not how to get there

## References

- Video: [Field Guide to Fable - Thariq Shihipar](https://www.youtube.com/watch?v=9fubhllmsBU)
- Anthropic Research: [The Biology of a Large Language Model](https://www.anthropic.com/)
- Existing: `configs/best-practices.md`, `AGENTS.md`, `MEMORY.md`
