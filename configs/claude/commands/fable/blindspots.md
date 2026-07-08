# /blindspots - Find Unknown Unknowns

## Usage

```
/blindspots [task description]
```

Performs a comprehensive blind spot analysis before starting implementation to identify unknown unknowns, gotchas, and architectural considerations.

## What It Does

1. Analyzes the task and affected modules
2. Searches git history for relevant context
3. Reviews existing code patterns
4. Identifies potential gotchas
5. Generates clarifying questions
6. Recommends an approach

## Examples

### Example 1: New Feature

```
/blindspots Add webhook support for third-party integrations
```

**Agent Response**:
```
Blind Spot Analysis: Webhook Support

Context Sources Checked:
- Git history: 127 commits in /integrations, last 6 months
- Existing code: Found email notification system with similar pattern
- Tests: /tests/integrations/ has webhook simulation examples

Key Findings:

Architectural Patterns:
- Event system uses EventEmitter pattern (/core/events.ts)
- Webhooks should extend BaseIntegration abstract class
- Signature verification required for security (see /integrations/slack/)

Known Gotchas:
- Must implement retry logic (network failures common)
- Payload size limit: 1MB (nginx config)
- Webhook URLs must be HTTPS only (security requirement)
- Duplicate event handling needed (retries can cause duplicates)

Testing Requirements:
- Use webhook-test-server package (already in devDependencies)
- Must test: success, timeout, invalid signature, retry logic
- Integration tests in /tests/integrations/webhooks/

Questions Before Proceeding:

1. Which events should trigger webhooks? (all? specific?)
2. Should we support webhook payload templates/customization?
3. What's the retry strategy? (immediate? exponential backoff? max attempts?)
4. Do we need webhook delivery logs/history for users?
5. Should failed webhooks pause or just log error?

Recommended Approach:
Follow the Slack integration pattern (/integrations/slack/webhook.ts).
Implement as EventSubscriber that listens to specified events.
Use existing RetryQueue (/core/retry-queue.ts) for resilience.
Add webhook management UI in settings (follow /settings/integrations pattern).
```

### Example 2: Bug Fix

```
/blindspots Fix race condition in concurrent file uploads
```

**Agent Response**:
```
Blind Spot Analysis: Upload Race Condition

Context Sources Checked:
- Git history: 23 commits in /upload, found previous race condition fix
- GitHub issues: #456 reported similar issue (fixed 8 months ago)
- Code patterns: File locking mechanism exists in /storage/lock.ts

Key Findings:

Previous Similar Issue:
- Issue #456: Race condition in thumbnail generation (2025-11-15)
- Solution: Added distributed lock using Redis
- Pattern: storage/lock.ts provides withLock() helper

Current Architecture:
- Uploads use multipart chunking (/upload/chunked.ts)
- S3 finalizeMultipartUpload called after all chunks
- No locking around chunk assembly
- Multiple processes can finalize same upload

Known Gotchas:
- Redis locks have 30s timeout (see config/redis.ts)
- Must release locks in finally block (even on error)
- Lock keys must be unique per upload (use upload_id)
- S3 ETags required for chunk validation

Testing Requirements:
- Reproduce with concurrent upload simulation
- Use test/fixtures/large-file.bin (10MB multi-chunk file)
- Test: successful concurrent, failed chunk, timeout scenarios

Questions Before Proceeding:

1. Should we lock per upload or per chunk?
2. What happens if lock acquisition times out?
3. Should we queue finalization or reject concurrent attempts?
4. Do we need to handle distributed race (multiple servers)?

Recommended Approach:
Use withLock() from storage/lock.ts with upload_id as key.
Lock before chunk assembly and finalize.
If lock busy, queue finalization (use existing JobQueue).
Add lock acquisition metrics for monitoring.
```

### Example 3: Refactoring

```
/blindspots Refactor authentication to support multiple providers
```

**Agent Response**:
```
Blind Spot Analysis: Multi-Provider Auth Refactor

Context Sources Checked:
- Current auth: Single OAuth provider (GitHub)
- Git history: Auth module rewritten 3 months ago
- Dependencies: passport, passport-github, express-session
- Tests: 45 auth tests, mostly unit tests

Key Findings:

Current Architecture:
- Tightly coupled to GitHub (auth/github.ts, 487 lines)
- Session management in auth/session.ts (reusable)
- Config stored in config/github.ts (hardcoded)

Refactoring Precedents:
- Payment providers refactor (commit ef789ab, 2025-09-12)
- Created BaseProvider abstract class
- Plugin pattern with provider registry
- Each provider in /payments/providers/[name]/

Known Gotchas:
- Sessions store provider_type (schema migration needed)
- Existing users must not lose access (data migration)
- Provider-specific scopes differ (normalize or store raw?)
- Callback URLs change per provider (update in all provider dashboards)

Migration Complexity:
- ~15,000 active user sessions
- Sessions referenced in 7 other tables (foreign keys)
- Downtime required? (or rolling migration?)

Testing Requirements:
- Cannot break existing GitHub auth during migration
- Need parallel auth paths during transition
- Test mixed provider users (if supporting multiple per user)

Questions Before Proceeding:

1. Should users link multiple providers or pick one?
2. Do we migrate existing users or grandfather them?
3. Which providers to support initially? (roadmap?)
4. Should provider choice be per-user or per-org?
5. How do we handle provider-specific features (GitHub: repos, Google: Drive)?
6. What's acceptable downtime for migration?

Recommended Approach:
1. Create BaseOAuthProvider abstract class (like payment providers)
2. Extract session management (already mostly separated)
3. Implement Provider Registry pattern (/auth/registry.ts)
4. Migrate GitHub to new pattern first (validate abstraction)
5. Add second provider (Google) to prove multi-provider works
6. Data migration: add provider_type column, backfill 'github'
7. Rolling deployment: support both old/new paths during transition

Breaking this into 3 PRs:
1. PR1: Extract abstraction + refactor GitHub (no behavior change)
2. PR2: Add provider registry + Google provider
3. PR3: UI for provider selection + data migration

Estimated complexity: High (touches auth core, requires migration)
Risks: Session invalidation, existing user lockout
Mitigation: Feature flag, staged rollout, easy rollback path
```

## When to Use

- Before starting unfamiliar or complex work
- When spec is high-level without details
- When touching critical infrastructure
- When unsure of existing patterns
- Before architectural decisions

## What It Provides

1. **Context**: Relevant history and patterns
2. **Gotchas**: Known issues and edge cases
3. **Questions**: Clarifications to gather
4. **Recommendation**: Suggested approach

## Integration

Works well with:
- `/interview-me` - Follow up with interview for remaining unknowns
- `/map-from` - Provide reference implementation
- Implementation logging - Track how analysis helped

## Under the Hood

Reads @skills/blindspot-pass/SKILL.md for execution guidance.

Searches:
- Git history (`git log`, `git grep`)
- Code patterns (`ripgrep`)
- Tests and documentation
- Related modules

## Tips

1. Be specific: "Add OAuth" vs "Add GitHub OAuth integration"
2. Include context: "in the user auth flow" helps scope the search
3. Mention concerns: "worried about performance" focuses the analysis
4. Reference modules: "in /api/upload" targets search area

## Related Commands

- `/interview-me` - Clarify spec gaps
- `/map-from` - Learn from example code
- `/plan` - Create implementation plan (after blind spot analysis)
