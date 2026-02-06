# Claude Code Teams

Teams allow you to coordinate multiple specialized agents to work together on complex tasks. Each team has a coordinator agent and member agents with specific roles.

## Team Structure

Each team configuration file defines:

- **name**: Unique identifier for the team
- **description**: What the team does
- **coordinator**: The main agent that orchestrates the team
- **members**: List of specialized agent roles
- **workflow**: How agents work (parallel or sequential)

## Available Teams

### Code Review Team
**Purpose**: Comprehensive code reviews  
**Members**: Code quality reviewer, security auditor, documentation reviewer  
**Workflow**: Parallel - all reviewers work simultaneously  
**Use when**: You need thorough review of code changes

### Development Team
**Purpose**: Full-cycle feature development  
**Members**: Architect, developer, tester, technical writer  
**Workflow**: Sequential - members work in order  
**Use when**: Building new features from scratch

## Creating Custom Teams

Create a new markdown file in `~/.claude/teams/` with frontmatter:

```markdown
---
name: my-team
description: What this team does
coordinator: lead-agent
members:
  - specialist-1
  - specialist-2
workflow: parallel  # or sequential
---

# Team documentation here
```

## Usage

Teams are typically invoked through commands or skills that leverage the team structure. The coordinator agent delegates tasks to team members and synthesizes their output.

Example invocation patterns:
- `/review-team` - Invoke code review team
- `/dev-team` - Invoke development team
- Custom commands can reference teams by name
