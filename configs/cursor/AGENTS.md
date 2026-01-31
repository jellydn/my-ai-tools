# Agent Guidelines for Cursor

## General Principles

1. **Keep it simple** - Prefer straightforward solutions over complex abstractions
2. **Match the codebase** - Follow existing patterns and conventions
3. **Test-driven** - Write tests before implementation when appropriate
4. **Incremental changes** - Make small, focused commits
5. **Clear communication** - Explain your reasoning and decisions

## Code Quality

- Remove unnecessary comments that state the obvious
- Avoid excessive defensive programming (null checks, try/catch everywhere)
- Use appropriate type safety without resorting to `any`
- Follow the existing code style and naming conventions
- Keep functions small and focused on a single responsibility

## Error Handling

- Handle errors at appropriate boundaries
- Use consistent error patterns across the codebase
- Don't catch errors just to re-throw them
- Provide meaningful error messages

## Testing

- Write tests that validate behavior, not implementation
- Follow the Testing Trophy approach (more integration tests than unit tests)
- Test edge cases and error conditions
- Keep tests readable and maintainable

## Performance

- Optimize only when needed (measure first)
- Prefer readability over premature optimization
- Be mindful of unnecessary re-renders (React)
- Use appropriate data structures

## Best Practices

- Kent Beck's "Tidy First?" - make tidying commits separate from behavior changes
- YAGNI (You Aren't Gonna Need It) - don't add features until needed
- DRY (Don't Repeat Yourself) - but don't over-abstract too early
- SOLID principles - especially Single Responsibility

## AI Assistant Guidelines

When using Cursor's AI features:

1. **Review suggestions carefully** - AI can make mistakes
2. **Understand before accepting** - Don't blindly accept code changes
3. **Test after changes** - Always verify AI-generated code works
4. **Refactor AI output** - Clean up verbose or over-engineered suggestions
5. **Learn from patterns** - Use AI to learn better patterns, not as a crutch

## References

- [@configs/best-practices.md](../best-practices.md) - Comprehensive development guidelines
- [@MEMORY.md](../../MEMORY.md) - Project-specific memory and context
