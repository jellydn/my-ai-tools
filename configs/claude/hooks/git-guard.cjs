#!/usr/bin/env node

/**
 * Git Guard Hook for Claude Code
 * 
 * This hook prevents dangerous git commands from being executed by Claude Code.
 * It checks the command in the tool input and blocks operations that could:
 * - Rewrite history (force push, reset --hard, rebase -i, filter-branch)
 * - Delete data (clean -fd, branch -D, reflog expire)
 * - Cause destructive changes (gc --prune=now)
 * 
 * Usage: Add to PreToolUse hooks for Bash tool in Claude Code settings.json
 * 
 * Based on: https://www.aihero.dev/this-hook-stops-claude-code-running-dangerous-git-commands
 */

const DANGEROUS_PATTERNS = [
  // Force push variations
  { pattern: /git\s+push\s+.*--force(?!-with-lease\b)/i, reason: "force push without --force-with-lease" },
  { pattern: /git\s+push\s+(?:.*\s)?-f(?:\s|$)/i, reason: "force push (-f) without lease" },
  
  // Hard reset
  { pattern: /git\s+reset\s+--hard/i, reason: "hard reset (destroys uncommitted changes)" },
  
  // Clean untracked files
  { pattern: /git\s+clean\s+.*-[a-z]*f/i, reason: "clean -f (removes untracked files)" },
  { pattern: /git\s+clean\s+.*-[a-z]*d/i, reason: "clean -d (removes untracked directories)" },
  
  // Force delete branch
  { pattern: /git\s+branch\s+.*-D/i, reason: "force delete branch (-D)" },
  
  // Rewrite history commands
  { pattern: /git\s+rebase\s+.*-i/i, reason: "interactive rebase (can rewrite history)" },
  { pattern: /git\s+filter-branch/i, reason: "filter-branch (rewrites history)" },
  { pattern: /git\s+reflog\s+expire/i, reason: "reflog expire (removes recovery points)" },
  
  // Aggressive garbage collection
  { pattern: /git\s+gc\s+.*--prune=now/i, reason: "aggressive garbage collection" },
  
  // Checkout force
  { pattern: /git\s+checkout\s+.*--force/i, reason: "force checkout (discards local changes)" },
  { pattern: /git\s+checkout\s+.*-f(?:\s|$)/i, reason: "force checkout (-f)" },
  
  // Stash drop/clear
  { pattern: /git\s+stash\s+drop/i, reason: "stash drop (permanently removes stash)" },
  { pattern: /git\s+stash\s+clear/i, reason: "stash clear (removes all stashes)" },
  
  // Update-ref delete
  { pattern: /git\s+update-ref\s+-d/i, reason: "update-ref -d (deletes references)" },
  
  // Replace
  { pattern: /git\s+replace/i, reason: "replace (creates replacement objects)" },
];

// Commands that are allowed (safe git operations)
const SAFE_PATTERNS = [
  /git\s+status/i,
  /git\s+log/i,
  /git\s+diff/i,
  /git\s+show/i,
  /git\s+branch(?!\s+.*-D)/i,  // branch listing/creation (not -D)
  /git\s+add/i,
  /git\s+commit/i,
  /git\s+push/i,  // push without force
  /git\s+pull/i,
  /git\s+fetch/i,
  /git\s+checkout(?!\s+.*(-f|--force))/i,  // checkout without force
  /git\s+merge/i,
  /git\s+rebase(?!\s+.*-i)/i,  // rebase without interactive
  /git\s+stash(?!\s+(drop|clear))/i,  // stash without drop/clear
  /git\s+tag/i,
  /git\s+remote/i,
  /git\s+config/i,
  /git\s+clone/i,
  /git\s+init/i,
];

function checkGitCommand(command) {
  if (!command || typeof command !== 'string') {
    return { allowed: true };
  }

  // Normalize whitespace
  const normalizedCommand = command.trim().replace(/\s+/g, ' ');

  // Check if it's a git command
  if (!normalizedCommand.match(/\bgit\b/i)) {
    return { allowed: true };
  }

  // Check against dangerous patterns
  for (const { pattern, reason } of DANGEROUS_PATTERNS) {
    if (pattern.test(normalizedCommand)) {
      return {
        allowed: false,
        reason: `Blocked dangerous git command: ${reason}`,
        command: normalizedCommand
      };
    }
  }

  // If it's a git command, ensure it matches a safe pattern
  const isSafe = SAFE_PATTERNS.some(pattern => pattern.test(normalizedCommand));
  
  if (!isSafe && normalizedCommand.match(/\bgit\b/i)) {
    // It's a git command but not in our safe list
    // Log a warning but allow it (conservative approach)
    console.error(`⚠️  Warning: Unfamiliar git command - please review carefully: ${normalizedCommand}`);
  }

  return { allowed: true };
}

// Read input from stdin
let input = '';

process.stdin.on('data', chunk => {
  input += chunk;
});

process.stdin.on('end', () => {
  try {
    if (!input.trim()) {
      // No input, allow
      process.exit(0);
    }

    // Parse the tool input JSON
    const toolInput = JSON.parse(input);
    
    // Extract the command from the tool input
    // The command could be in different places depending on the tool
    const command = toolInput.command || toolInput.tool_input?.command || '';

    // Check the command
    const result = checkGitCommand(command);

    if (!result.allowed) {
      // Write reason to stderr (becomes Claude's feedback)
      console.error(`Blocked: ${result.reason}`);
      console.error(`Command: ${result.command}`);
      console.error('This command has been blocked to prevent potential data loss.');
      console.error('If you need to run this command, please do so manually in your terminal.');
      
      // Exit with code 2 to block the action (per Claude Code hooks spec)
      process.exit(2);
    }

    // Command is safe, allow execution (exit 0)
    process.exit(0);

  } catch (error) {
    // If there's an error parsing or processing, log it but allow the command
    // (fail open to avoid blocking legitimate operations)
    console.error(`⚠️  Git guard hook error: ${error.message}`);
    process.exit(0);
  }
});
