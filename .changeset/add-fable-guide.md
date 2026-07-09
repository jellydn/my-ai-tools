---
"my-ai-tools": minor
---

Add Fable Field Guide and Discovery Skills

Based on Thariq Shihipar's "Field Guide to Fable" talk (AI Engineer 2026), adds comprehensive guidance and tooling for working with next-generation AI models.

**New Files**:
- `configs/fable-guide.md` - Comprehensive guide on capability overhang, finding unknowns, and challenging constraints
- `skills/blindspot-pass/` - Find unknown unknowns before implementation
- `skills/spec-interview/` - Clarify specifications through targeted questions
- `skills/implementation-logger/` - Track decisions and deviations during work
- `skills/quiz-me/` - Verify understanding after completion
- `.planning/fable-improvements.md` - Implementation roadmap

**New Commands** (Claude):
- `/blindspots [task]` - Run blind spot analysis
- `/interview-me [feature]` - Generate spec clarification questions

**Updated Files**:
- `configs/claude/CLAUDE.md` - Discovery-first approach, context over constraints
- `configs/best-practices.md` - Streamlined with Fable principles
- `AGENTS.md` - References new discovery tools

**Key Concepts**:
- **Capability Overhang**: Models get smarter in spiky ways; tools unlock capabilities
- **Map vs Territory**: Your plan (map) vs actual codebase (territory); find the unknowns
- **Context over Constraints**: Positive guidance over negative rules
- **Being Unreasonable**: Challenge false tradeoffs (good + fast + cheap = all three)

**Discovery Workflow**:
1. Blind spot pass → Identify unknowns
2. Interview → Clarify requirements
3. Implementation logging → Track decisions
4. Quiz → Verify understanding

Based on: https://www.youtube.com/watch?v=9fubhllmsBU
