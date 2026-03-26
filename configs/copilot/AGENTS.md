# 🤖 GitHub Copilot CLI Agent Guidelines

## General Practices

- Follow my software development practice @~/.ai-tools/best-practices.md
- Read @~/.ai-tools/MEMORY.md first - Understand when and how to use qmd for knowledge management
- Follow git safety guidelines @~/.ai-tools/git-guidelines.md
- Keep responses concise and actionable.
- Never run destructive commands.
- Use our conventions for file names, tests, and commands.

## Code Quality

- Keep your code clean and organized. Do not over-engineer solutions or overcomplicate things unnecessarily.
- Write clear and concise code. Avoid unnecessary complexity and redundancy.
- Use meaningful variable and function names.
- Prefer self-documenting code. Write comments and documentation where necessary.
- Keep your code modular and reusable. Avoid tight coupling and excessive dependencies.
- Run typecheck, lint and biome on js/ts file changes after finish.
- Prefer to use Bun to run scripts if possible, otherwise use tsx to run ts files.

## Planning & Workflow

- Always propose a plan before edits. Use `/plan` for complex multi-file changes, new feature implementations, and refactoring with many touch points.
- Follow the explore → plan → code → commit workflow for best results on complex tasks:
  - **Explore**: Read relevant files before writing any code.
  - **Plan**: Use `/plan` to create a structured implementation plan with checkboxes.
  - **Review**: Check the plan and suggest modifications before proceeding.
  - **Implement**: Proceed with the approved plan.
  - **Verify**: Run tests and fix any failures.
  - **Commit**: Commit changes with a descriptive message.
- Use `/clear` or `/new` between unrelated tasks to reset context and improve response quality.
- Use `/compact` to manually trigger context compaction when needed (usually automatic).

## Model Selection

Use `/model` to select the best model for the task:

- **Claude Opus 4.5** (default) — Complex architecture, difficult debugging, nuanced refactoring.
- **Claude Sonnet 4.5** — Day-to-day coding, most routine tasks; fast and cost-effective.
- **GPT-5.2 Codex** — Code generation, code review, and reviewing code produced by other models.

## Delegation & Parallelism

- Use `/delegate` to offload tangential tasks (documentation, refactoring separate modules) to Copilot coding agent in the cloud.
- Use `/fleet` at the start of a prompt to break large tasks into parallel subtasks run by subagents.
- Use `/add-dir` to expand access to other repositories when making cross-cutting changes.

## Security

- Require explicit approval before any potentially destructive operations.
- Review all proposed changes before accepting.
- Never commit secrets or credentials — always verify even when Copilot avoids it by design.
