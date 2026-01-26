---
name: context-check
description: Get strategic advice on context usage with threshold-based recommendations - complements /context with actionable guidance
allowed-tools: Bash(/Users/huynhdung/.claude/skills/context-check/scripts/check-context.ts:*), Read(*)
---

# Context Advisor

Strategic guidance for managing Claude Code session context. This skill complements the built-in `/context` command by providing actionable recommendations based on usage thresholds.

## Quick Start

```bash
/context-check
```

This will analyze your current session and provide:
- 📊 **Usage estimate** - Token count vs. 200k limit
- 💡 **Recommendation** - Threshold-based guidance
- 📋 **Strategic advice** - Context-aware suggestions
- 🎯 **Next steps** - Specific actions to take

## When to Use This

### Use `/context-check` when you want to:
- Get actionable advice on context management
- Understand if you should create a handoff
- Receive strategic recommendations for your workflow
- See threshold-based guidance (healthy/moderate/high/critical)

### Use `/context` when you want to:
- See detailed breakdown by category (tools, agents, memory, etc.)
- Understand what's consuming the most tokens
- Diagnose context issues
- Get precise per-item token counts

## How It Works

The advisor uses file-size estimation to approximate token usage:
```
Estimated Tokens ≈ Transcript File Size (bytes) ÷ 4
```

Then applies threshold-based logic to provide strategic recommendations.

## Thresholds & Guidance

| Usage | Status | What It Means |
|-------|--------|---------------|
| < 50% | ✅ Healthy | Optimal range - continue normally |
| 50-75% | 📋 Moderate | Be mindful - plan ahead for long tasks |
| 75-90% | ⚠️ High | Approaching limits - create handoff soon |
| > 90% | 🚨 Critical | Immediate action - handoff required |

## Example Output

```
═══════════════════════════════════════════════
           CONTEXT ADVISOR REPORT
═══════════════════════════════════════════════

📊 Estimated Usage: 34,000 / 200,000 tokens

🟢 [████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░] 17.0%

Status: ✅ HEALTHY

───────────────────────────────────────────────
💡 RECOMMENDATION
───────────────────────────────────────────────
Context usage is healthy. You have plenty of room to continue working.

───────────────────────────────────────────────
📋 STRATEGIC ADVICE
───────────────────────────────────────────────
  • This is the optimal operating range for complex tasks
  • Feel free to explore the codebase, read large files, and iterate
  • No immediate action needed regarding context management

───────────────────────────────────────────────
🎯 NEXT STEPS
───────────────────────────────────────────────
  1. Continue your current work normally
  2. Use /context for detailed breakdown if needed

───────────────────────────────────────────────
💭 TIP: Use /context for detailed token breakdown
═══════════════════════════════════════════════
```

## Integration with Handoffs

When thresholds are exceeded, the advisor guides you through the handoff workflow:

1. **Create handoff**: `/handoffs <purpose>`
2. **Start new session**: Close and reopen Claude Code
3. **Resume work**: `/pickup <filename>`

See [reference.md](reference.md) for:
- Detailed threshold explanations
- Handoff workflow details
- Token estimation methodology
- Best practices for context management

## Automatic Detection

For automatic threshold detection, see the `context-threshold.ts` hook configured in your settings. The advisor skill is designed for **manual, on-demand consultation**.

### Hook Interactive Menu

When the context threshold (90%) is reached, the `context-threshold.ts` hook will block your prompt and present an interactive menu:

```
⚠️ Context Threshold Alert ⚠️

Choose an action:

1. **Auto-handoff**: Reply with your handoff purpose (e.g., "implement-auth") and I'll create a handoff automatically
2. **Manual**: Run /handoffs <purpose> yourself for full control
3. **Continue**: Type 'continue' to proceed anyway (not recommended)
```

- **Auto-handoff**: Simply reply with a brief purpose and Claude will create the handoff for you
- **Manual**: Use the `/handoffs <purpose>` command for full control over the handoff content
- **Continue**: Override the threshold warning and proceed (not recommended)
