/**
 * Git Guard - Dangerous Git Command Detection
 *
 * This module provides pattern matching to detect potentially dangerous git commands.
 * Based on: https://www.aihero.dev/this-hook-stops-claude-code-running-dangerous-git-commands
 */

export interface DangerousPattern {
  pattern: RegExp
  reason: string
}

export interface GitCheckResult {
  allowed: boolean
  reason?: string
}

// Dangerous git command patterns
export const DANGEROUS_PATTERNS: DangerousPattern[] = [
  // Force push variations
  { pattern: /git\s+push\s+.*--force(?!-with-lease\b)/i, reason: 'force push without --force-with-lease' },
  { pattern: /git\s+push\s+(?:.*\s)?-f(?:\s|$)/i, reason: 'force push (-f) without lease' },

  // Hard reset
  { pattern: /git\s+reset\s+--hard/i, reason: 'hard reset (destroys uncommitted changes)' },

  // Clean untracked files
  { pattern: /git\s+clean\s+.*-[a-z]*f/i, reason: 'clean -f (removes untracked files)' },
  { pattern: /git\s+clean\s+.*-[a-z]*d/i, reason: 'clean -d (removes untracked directories)' },

  // Force delete branch
  { pattern: /git\s+branch\s+.*-D/i, reason: 'force delete branch (-D)' },

  // Rewrite history commands
  { pattern: /git\s+rebase\s+.*-i/i, reason: 'interactive rebase (can rewrite history)' },
  { pattern: /git\s+filter-branch/i, reason: 'filter-branch (rewrites history)' },
  { pattern: /git\s+reflog\s+expire/i, reason: 'reflog expire (removes recovery points)' },

  // Aggressive garbage collection
  { pattern: /git\s+gc\s+.*--prune=now/i, reason: 'aggressive garbage collection' },

  // Checkout force
  { pattern: /git\s+checkout\s+.*--force/i, reason: 'force checkout (discards local changes)' },
  { pattern: /git\s+checkout\s+.*-f(?:\s|$)/i, reason: 'force checkout (-f)' },

  // Stash drop/clear
  { pattern: /git\s+stash\s+drop/i, reason: 'stash drop (permanently removes stash)' },
  { pattern: /git\s+stash\s+clear/i, reason: 'stash clear (removes all stashes)' },

  // Update-ref delete
  { pattern: /git\s+update-ref\s+-d/i, reason: 'update-ref -d (deletes references)' },

  // Replace
  { pattern: /git\s+replace/i, reason: 'replace (creates replacement objects)' },
]

/**
 * Check if a git command is dangerous
 * @param command - The command string to check
 * @returns Object indicating if the command is allowed and optionally why
 */
export function checkGitCommand(command: string): GitCheckResult {
  if (!command || typeof command !== 'string') {
    return { allowed: true }
  }

  // Normalize whitespace
  const normalizedCommand = command.trim().replace(/\s+/g, ' ')

  // Check if it's a git command
  if (!normalizedCommand.match(/\bgit\b/i)) {
    return { allowed: true }
  }

  // Check against dangerous patterns
  for (const { pattern, reason } of DANGEROUS_PATTERNS) {
    if (pattern.test(normalizedCommand)) {
      return {
        allowed: false,
        reason: `Blocked dangerous git command: ${reason}`,
      }
    }
  }

  // Command is safe
  return { allowed: true }
}
