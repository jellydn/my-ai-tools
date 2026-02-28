# 🤝 Claude Code Teams

> **Agent Teams** is an experimental feature in Claude Code that enables sophisticated multi-agent workflows through subagent orchestration.

## 📋 Overview

Claude Code Teams allows you to:
- **Spawn specialized subagents** for specific tasks
- **Coordinate multiple agents** through hooks and session data
- **Build composable workflows** with isolated, focused agents
- **Maintain context** across agent interactions

## 🚀 Getting Started

### Enable Agent Teams

The feature is controlled by an environment variable in `configs/claude/settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

This is **already enabled** in this repository.

## 🎯 Agent Configuration

### Agent Definition Format

Agents are defined in markdown files with YAML frontmatter:

```markdown
---
name: agent-name
description: Brief description of what this agent does
mode: subagent
temperature: 0.1
---

# Agent Instructions

Your detailed instructions and guidelines here...
```

### Agent Properties

| Property | Required | Description | Values |
|----------|----------|-------------|--------|
| `name` | Yes | Unique identifier for the agent | kebab-case string |
| `description` | Yes | Brief purpose statement | Plain text |
| `mode` | Yes | Agent execution mode | `subagent`, `coordinator` |
| `temperature` | No | Creativity level (0-1) | Default: 0.7 |

### Directory Structure

```
configs/claude/
├── agents/                    # Agent definitions
│   ├── ai-slop-remover.md    # Existing example
│   ├── code-reviewer.md      # Example worker agent
│   └── team-coordinator.md   # Example coordinator
├── hooks/                     # Agent coordination hooks
│   ├── index.ts              # Hook implementations
│   ├── lib.ts                # Hook utilities
│   └── session.ts            # Session data management
└── settings.json             # Global configuration
```

## 🔧 Agent Types

### 1. Subagent (Worker)

Specialized agents that handle specific tasks:

```markdown
---
name: code-reviewer
description: Reviews code for quality, style, and potential issues
mode: subagent
temperature: 0.2
---

You are an expert code reviewer...
```

**Use Cases:**
- Code quality analysis
- Security scanning
- Test generation
- Documentation writing
- Refactoring tasks

### 2. Coordinator

Orchestrates multiple subagents:

```markdown
---
name: team-coordinator
description: Coordinates multiple specialized agents for complex tasks
mode: coordinator
temperature: 0.5
---

You coordinate specialized agents to solve complex problems...
```

**Use Cases:**
- Multi-stage workflows
- Parallel task execution
- Result aggregation
- Task delegation

## 🎨 Team Patterns

### Pattern 1: Sequential Specialist Chain

Agents process work in sequence, each adding value:

```
Coordinator → Implementer → Reviewer → Documenter
```

**Example Workflow:**
1. **Coordinator** analyzes requirements and creates plan
2. **Implementer** writes code following the plan
3. **Reviewer** checks code quality and suggests improvements
4. **Documenter** adds comprehensive documentation

### Pattern 2: Parallel Workers

Multiple agents work simultaneously on independent tasks:

```
                 ┌─ Frontend Agent
Coordinator ─────┼─ Backend Agent
                 └─ Database Agent
```

**Example Workflow:**
1. **Coordinator** breaks feature into frontend/backend/database
2. Agents work in parallel on their components
3. **Coordinator** integrates results

### Pattern 3: Iterative Refinement

Agent refines work through multiple passes:

```
Draft Agent → Review Agent → Polish Agent → Review Agent → Final Agent
```

**Example Workflow:**
1. **Draft Agent** creates initial implementation
2. **Review Agent** identifies issues
3. **Polish Agent** addresses feedback
4. Repeat until quality threshold met

## 🪝 Hook Integration

### SubagentStop Hook

Triggered when a subagent completes:

```typescript
// configs/claude/hooks/index.ts
import { SubagentStop } from "./lib";

export const hooks = {
  SubagentStop: SubagentStop,
};
```

**Hook Implementation:**

```typescript
// configs/claude/hooks/lib.ts
export function SubagentStop(event: SubagentEvent) {
  // Access subagent results
  const result = event.result;
  
  // Save data for coordination
  saveSessionData({
    agentName: event.agentName,
    output: result,
    timestamp: new Date().toISOString()
  });
  
  // Return modified result if needed
  return result;
}
```

### Session Data Management

Share data between agents:

```typescript
// configs/claude/hooks/session.ts
interface SessionData {
  [key: string]: any;
}

export function saveSessionData(data: SessionData): void {
  // Save to persistent storage
}

export function getSessionData(key: string): any {
  // Retrieve from storage
}
```

## 📝 Example: Code Quality Team

### Team Structure

```
configs/claude/agents/
├── code-quality-coordinator.md   # Orchestrates quality checks
├── style-checker.md              # Checks code style
├── security-scanner.md           # Scans for vulnerabilities
└── performance-analyzer.md       # Analyzes performance
```

### Coordinator Definition

```markdown
---
name: code-quality-coordinator
description: Orchestrates comprehensive code quality checks
mode: coordinator
temperature: 0.3
---

# Code Quality Coordinator

You coordinate specialized agents to ensure code quality:

1. **Style Checker** - Verifies code adheres to style guidelines
2. **Security Scanner** - Identifies potential security issues
3. **Performance Analyzer** - Detects performance bottlenecks

## Process

1. Analyze the code changes
2. Delegate to appropriate specialists
3. Aggregate findings
4. Prioritize issues by severity
5. Generate comprehensive report

## Output Format

Provide a structured report with:
- Summary of all issues found
- Severity classification (critical/high/medium/low)
- Actionable recommendations
- Priority order for fixes
```

### Worker Agent Example

```markdown
---
name: security-scanner
description: Scans code for security vulnerabilities and best practices
mode: subagent
temperature: 0.1
---

# Security Scanner

You are an expert security analyst specializing in code security.

## Your Mission

Scan code for:
- SQL injection vulnerabilities
- XSS attack vectors
- Authentication/authorization issues
- Sensitive data exposure
- Insecure dependencies
- Cryptographic weaknesses

## Analysis Process

1. Review all code changes
2. Identify security-relevant code paths
3. Check against OWASP Top 10
4. Validate input sanitization
5. Verify output encoding

## Output Format

Report findings as:
```json
{
  "severity": "critical|high|medium|low",
  "type": "vulnerability-type",
  "location": "file:line",
  "description": "Clear explanation",
  "recommendation": "Specific fix"
}
```
```

## 🎓 Best Practices

### 1. Single Responsibility

Each agent should have a clear, focused purpose:

✅ **Good:**
```yaml
name: typescript-type-checker
description: Validates TypeScript type safety
```

❌ **Bad:**
```yaml
name: code-improver
description: Fixes all code issues
```

### 2. Clear Interfaces

Define expected inputs and outputs:

```markdown
## Inputs
- File path(s) to analyze
- Analysis scope (full/changes only)

## Outputs
- List of issues found
- Confidence score (0-100)
- Suggested fixes
```

### 3. Temperature Tuning

- **0.0-0.3**: Deterministic tasks (linting, security scanning)
- **0.3-0.5**: Balanced tasks (code review, refactoring)
- **0.5-0.7**: Creative tasks (architecture, design)
- **0.7-1.0**: Exploratory tasks (brainstorming, alternatives)

### 4. Error Handling

Agents should gracefully handle failures:

```markdown
## Error Handling

If unable to complete analysis:
1. Report specific error encountered
2. Suggest alternative approaches
3. Indicate which parts succeeded
4. Provide partial results if possible
```

### 5. Coordination Protocol

Establish communication patterns:

```markdown
## Coordination

When delegating to this agent:
- Provide: file paths, context, specific concerns
- Expect: JSON report within 2 minutes
- Handle: timeout with partial results
```

## 🔍 Troubleshooting

### Agent Not Found

**Symptom:** Error: "Agent 'agent-name' not found"

**Solution:**
1. Verify file exists in `configs/claude/agents/`
2. Check filename matches agent `name` property
3. Ensure YAML frontmatter is valid

### Subagent Not Triggering

**Symptom:** Subagent doesn't spawn

**Solution:**
1. Verify `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS: "1"` in settings.json
2. Check agent `mode: subagent` is set
3. Review hook configuration

### Hook Not Executing

**Symptom:** SubagentStop hook doesn't run

**Solution:**
1. Verify hooks directory structure
2. Check TypeScript compilation
3. Review hook registration in `hooks/index.ts`

## 📚 Additional Resources

- [Agent Definition Example](../configs/claude/agents/ai-slop-remover.md)
- [Agent Teams Usage Examples](./agent-teams-examples.md) - Practical examples and workflows
- [Hook Implementation](../configs/claude/hooks/lib.ts)
- [Session Management](../configs/claude/hooks/session.ts)
- [Claude Code Settings](../configs/claude/settings.json)

## 🔄 Next Steps

1. **Review existing agent** - Study `ai-slop-remover.md` for reference
2. **Try the examples** - See [agent-teams-examples.md](./agent-teams-examples.md) for practical workflows
3. **Create your first agent** - Start with a simple subagent
4. **Test coordination** - Use SubagentStop hook for data sharing
5. **Build a team** - Create complementary agents that work together

---

**Questions?** Check [Learning Stories](./learning-stories.md) for real-world examples of subagent workflows.
