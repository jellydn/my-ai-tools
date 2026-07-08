# /map-from - Learn from Reference Code

## Usage

```
/map-from [reference description, file path, or URL]
```

Analyzes reference implementation to extract patterns, intentions, and structure, then adapts them to the current codebase context. Helps bridge the gap between "existing patterns" and "new implementation."

## What It Does

1. Accepts a reference — could be a file path, a described pattern, or an existing module
2. Analyzes the reference for:
   - Key abstractions and their relationships
   - Error handling patterns
   - Testing approach
   - Configuration and integration points
   - Architectural decisions embedded in the code
3. Maps each finding to the current codebase context
4. Produces an implementation plan that follows the reference's intent while fitting local conventions

## When to Use

- **New patterns**: Adding functionality that follows an existing pattern (e.g., "add a provider like the existing OAuth one")
- **Migration**: Porting code from another project or framework
- **Learning**: Understanding complex code by examining reference implementations
- **Consistency**: Ensuring new code follows established patterns

## Examples

### Example 1: Pattern from Existing Code

```
/map-from configs/claude/commands/fable/blindspots.md
```

**Agent Response**:
```
Reference Analysis: blindspots.md

Pattern identified:
- Markdown command format with Usage, What It Does, Examples
- Structured output format with analysis sections
- Integration with other discovery tools

Mapping to new command:
- Follow same markdown structure
- Use consistent section headers
- Match output format for compatibility
```

### Example 2: Cross-Cutting Pattern

```
/map-from Need to add a new API endpoint like the existing /users endpoint
```

**Agent Response**:
```
Reference: /users endpoint

Key patterns:
1. Route definition in routes/users.ts
2. Validation via Zod schema in schemas/user.ts
3. Service layer in services/user-service.ts
4. Tests mirror controller structure

Mapping to new endpoint:
- Create routes/[entity].ts (follow /users pattern)
- Create schemas/[entity].ts (validate request/response)
- Add service methods (follow existing CRUD)
- Add test file (match test structure)
```

## Tips

- Be specific about which aspects to focus on: "Map the error handling pattern from X"
- If the reference is large, ask for specific sections: "Map the auth middleware pattern"
- Use with `/blindspots` before starting for maximum effectiveness
- Combine with implementation logging to track where your adaptation differs from the reference

## Related

- `/blindspots` - Find unknown unknowns before starting
- `/interview-me` - Clarify spec gaps
- Implementation logging - Track deviations from plan
