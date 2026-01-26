# Context Check - Reference Documentation

## Context Window Limits

Claude Code sessions operate within a context window of approximately **200,000 tokens**. This limit includes:
- User messages
- Assistant responses
- Tool calls and results
- System prompts
- File contents read during the session

## Token Estimation

The `check-context.ts` script uses a simple approximation:

```
Estimated Tokens ≈ File Size (bytes) ÷ 4
```

This is a conservative estimate based on typical English text encoding. Actual token counts may vary depending on:
- Language and character distribution
- Code vs. prose content
- JSON structure overhead

## Usage Thresholds

### ✅ Healthy (< 50%)

**Usage**: 0 - 99,999 tokens
**Status**: Optimal operating range
**Action**: Continue working normally

At this level, you have plenty of context space for:
- Complex multi-step tasks
- Reading large files
- Exploring the codebase
- Multiple iterations of changes

### 📋 Moderate (50-75%)

**Usage**: 100,000 - 149,999 tokens
**Status**: Acceptable, plan ahead
**Action**: Consider planning for a handoff if task will continue

You still have room to work, but should:
- Be mindful of reading very large files
- Consider if the current task is near completion
- Plan for a handoff if starting a new major feature

### ⚠️ High (75-90%)

**Usage**: 150,000 - 179,999 tokens
**Status**: Approaching limits
**Action**: Recommend creating a handoff soon

At this level:
- Context is getting crowded
- Performance may begin to degrade
- Risk of hitting limits during complex operations
- **Recommended**: Complete current task and create handoff

### 🚨 Critical (> 90%)

**Usage**: 180,000+ tokens
**Status**: Urgent action required
**Action**: Create handoff immediately

At this level:
- Very high risk of context overflow
- Limited room for additional operations
- **Required**: Create handoff and start new session

## Handoff Workflow

When context threshold is exceeded:

1. **Create Handoff**:
   ```
   /handoffs <purpose>
   ```
   Example: `/handoffs Continue implementing user authentication feature`

2. **Start New Session**:
   - Close current Claude Code session
   - Open a new session in the same directory

3. **Resume Work**:
   ```
   /pickup <filename>
   ```
   Example: `/pickup .claude/handoffs/2025-12-30-authentication-feature.md`

## Automatic Detection

The context threshold hook (if configured) will automatically:
- Monitor transcript size before each user prompt
- Block interaction if critical threshold (90%) is exceeded
- Provide guidance to create a handoff
- Prevent context overflow issues

## Manual Checking

Use the `/context-check` skill anytime to:
- View current context usage
- Get threshold-based recommendations
- Decide when to create a handoff
- Monitor long-running sessions

## Best Practices

1. **Proactive Monitoring**: Check context before starting major new features
2. **Natural Breakpoints**: Create handoffs at logical task boundaries
3. **Descriptive Purposes**: Use clear handoff purposes for easy resume
4. **Regular Cleanup**: Complete and archive old handoffs
5. **Threshold Awareness**: Don't wait until critical - handoff at high usage
