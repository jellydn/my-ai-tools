# Claude Code Permissions Model

> **Overview**: Understanding Claude Code's permission system and the security implications of `defaultMode: "plan"`.

---

## What is the Permissions System?

Claude Code uses a permission system to control which tools and operations Claude can perform autonomously versus those requiring user approval.

---

## Permission Modes

| Mode | Description | Use Case |
|------|-------------|----------|
| `allow` | Tool runs autonomously without approval | Safe, trusted operations |
| `ask` | User prompted for approval before each use | Sensitive operations |
| `deny` | Tool cannot be used | Security restriction |
| `plan` (default) | Requires plan-mode approval | Unlisted tools |

---

## Our Configuration

**File**: `~/.claude/settings.json`

```json
{
  "permissions": {
    "allow": [
      "mcp__sequential-thinking__sequentialthinking",
      "WebSearch",
      "Bash(bash:*)",
      "WebFetch(domain:github.com)",
      "mcp__qmd__query",
      "mcp__qmd__get",
      "mcp__qmd__search",
      "mcp__qmd__vsearch",
      "mcp__qmd__multi_get",
      "mcp__qmd__status",
      "Bash($HOME/.config/opencode/skill/qmd-knowledge/scripts/record.sh:*)",
      "Bash($HOME/.claude/skills/qmd-knowledge/scripts/record.sh:*)",
      "Bash(qmd:*)"
    ],
    "defaultMode": "plan"
  }
}
```

---

## Why `defaultMode: "plan"`?

### Security by Default

With `defaultMode: "plan"`, **any tool not explicitly listed in the `allow` array** requires plan-mode approval. This means:

- ✅ Knowledge tools (qmd) work autonomously
- ✅ Common operations (bash, web search) work autonomously
- ⚠️ New or unspecified tools require explicit approval

### Trade-offs

| Approach | Pros | Cons |
|----------|------|------|
| `defaultMode: "plan"` | Secure by default, prevents accidental actions | More prompts for new tools |
| `defaultMode: "allow"` | Fewer interruptions, more autonomy | Higher risk of unintended actions |
| `defaultMode: "ask"` | Full control over every operation | Very verbose, disrupts flow |

---

## Permission Categories

### 1. Always Allowed (Autonomous)

These tools work without any prompts:

**MCP Servers (Knowledge & Reasoning):**
- `mcp__sequential-thinking__sequentialthinking` - Multi-step reasoning
- `mcp__qmd__*` - All qmd knowledge tools

**Web & Research:**
- `WebSearch` - Web search capabilities
- `WebFetch(domain:github.com)` - Fetch from GitHub

**Shell Operations:**
- `Bash(bash:*)` - General bash commands
- `Bash(qmd:*)` - Direct qmd CLI access

**Knowledge Recording:**
- `Bash($HOME/.config/opencode/skill/qmd-knowledge/scripts/record.sh:*)`
- `Bash($HOME/.claude/skills/qmd-knowledge/scripts/record.sh:*)`

### 2. Requires Plan Approval

Any tool **not** in the `allow` list requires plan-mode approval, including:

- File operations outside project directory
- Network requests to non-whitelisted domains
- MCP servers not explicitly allowed
- System-level operations

### 3. Denied

Tools marked as `deny` cannot be used at all.

---

## Changing the Default Mode

### To More Permissive (`allow`)

If you find plan-mode too restrictive:

```json
{
  "permissions": {
    "allow": [
      // ... existing tools ...
    ],
    "defaultMode": "allow"
  }
}
```

**⚠️ Warning**: This allows Claude to use **any** tool without approval. Only use if you fully trust the context.

### To More Restrictive (`ask`)

For maximum security:

```json
{
  "permissions": {
    "allow": [],
    "defaultMode": "ask"
  }
}
```

This requires approval for **every** tool use.

---

## Adding New Permissions

To allow a new tool to work autonomously:

### Step 1: Identify the tool

Try using the tool - Claude will tell you the permission string if it's blocked.

### Step 2: Add to the `allow` array

```json
{
  "permissions": {
    "allow": [
      "WebFetch(domain:api.github.com)",  // Add this
      // ... existing tools ...
    ]
  }
}
```

### Step 3: Restart Claude Code

Settings are reloaded on restart.

---

## Example Scenarios

### Scenario 1: Knowledge Management Works Freely

```text
User: Record what we learned about MCP servers

Claude: I'll record that learning.
[Autonomously runs record.sh - no approval needed]

✓ Saved to knowledge base
```

### Scenario 2: New MCP Server Needs Approval

```text
User: Use the new weather MCP server

Claude: I need to use the weather MCP server.
[Plan mode activated - user sees the plan first]

Plan:
1. Call mcp__weather__getForecast for location

User: Approve

Claude: [Proceeds with the plan]
```

### Scenario 3: File Write Outside Project

```text
User: Write a config file to ~/.config/myapp/

Claude: I need to write to ~/.config/myapp/config.json
[This may require approval depending on context]

User: Approve

Claude: [Writes the file]
```

---

## Security Considerations

### Why Not `defaultMode: "allow"`?

1. **Prevents accidental system changes** - Claude won't modify system files without review
2. **Protects against prompt injection** - Malicious inputs can't trigger arbitrary tool use
3. **Audit trail** - You see what Claude plans to do before it happens

### When to Relax Permissions

Consider `defaultMode: "allow"` for:
- Trusted sandboxed environments
- Repetitive automation tasks
- Development environments where rollback is easy

### When to Tighten Permissions

Consider `defaultMode: "ask"` for:
- Production systems
- Systems with sensitive data
- Multi-user environments

---

## Verifying Your Permissions

To see what permissions are currently active:

```bash
# Check current settings
cat ~/.claude/settings.json | jq '.permissions'

# List all available tools (in Claude Code session)
# Ask Claude: "What tools are available?"
```

---

## Troubleshooting

### "Tool not permitted" Error

This means a tool isn't in the `allow` list and `defaultMode` requires approval.

**Solution**: Either approve in plan mode or add to `allow` list.

### Too Many Approval Prompts

You may need to add more tools to your `allow` list.

**Solution**: Identify which tools you use frequently and add them.

### Something Won't Run Autonomously

Check if the tool is in the `allow` list.

**Solution**: Add the specific permission string for that tool.

---

## Best Practices

1. **Start restrictive** - Use `defaultMode: "plan"` initially
2. **Add incrementally** - Allow tools as you trust them
3. **Review periodically** - Audit your `allow` list
4. **Use wildcards carefully** - `Bash(bash:*)` allows all bash commands
5. **Scope tightly** - Prefer `WebFetch(domain:github.com)` over `WebFetch(*)`

---

## Resources

- [Claude Code Settings](https://claude.com/claude-code/settings)
- [Permissions Documentation](https://support.claude.com/en/articles/permissions)
- [Security Best Practices](https://support.claude.com/en/articles/security)

---

## Summary

| Setting | Value | Reason |
|---------|-------|--------|
| `defaultMode` | `"plan"` | Secure by default, prevents accidental actions |
| Knowledge tools | Allowed | Core workflow should work autonomously |
| Bash commands | Allowed | Development requires terminal access |
| Other tools | Plan approval | Review new tools before use |
