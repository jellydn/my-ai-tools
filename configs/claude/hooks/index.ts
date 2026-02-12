#!/usr/bin/env bun

/**
 * Claude Code Hooks - Git Guard
 *
 * PreToolUse hook that blocks dangerous git commands from being executed.
 * Based on: https://github.com/johnlindquist/claude-hooks
 */

import { checkGitCommand } from './git-guard'

// Type definitions for Claude Code hooks

export interface PreToolUsePayload {
  session_id: string
  transcript_path: string
  hook_event_name: 'PreToolUse'
  tool_name: string
  tool_input: Record<string, unknown>
}

export interface PreToolUseResponse {
  permissionDecision?: 'allow' | 'deny' | 'ask'
  permissionDecisionReason?: string
}

export type PreToolUseHandler = (
  payload: PreToolUsePayload,
) => Promise<PreToolUseResponse> | PreToolUseResponse

export interface HookHandlers {
  preToolUse?: PreToolUseHandler
}

// PreToolUse handler - called before Claude uses any tool
const preToolUse: PreToolUseHandler = async (payload) => {
  // Check git commands for Bash tool
  if (payload.tool_name === 'Bash' && payload.tool_input && 'command' in payload.tool_input) {
    const command = (payload.tool_input as { command: string }).command
    const result = checkGitCommand(command)

    if (!result.allowed) {
      console.error(`🛡️ Git Guard: ${result.reason}`)
      console.error(`Command: ${command}`)
      console.error('This command has been blocked to prevent potential data loss.')

      return {
        permissionDecision: 'deny',
        permissionDecisionReason: result.reason,
      }
    }
  }

  // Allow all other tools
  return {}
}

// Main hook runner
function runHook(handlers: HookHandlers): void {
  const hook_type = process.argv[2] as string

  process.stdin.on('data', async (data: Buffer) => {
    try {
      const inputData = JSON.parse(data.toString()) as PreToolUsePayload

      if (hook_type === 'PreToolUse' && handlers.preToolUse) {
        const response = await handlers.preToolUse(inputData as PreToolUsePayload)
        console.log(JSON.stringify(response))
      } else {
        console.log(JSON.stringify({}))
      }
    } catch (error) {
      console.error('Hook error:', error)
      console.log(JSON.stringify({}))
    }
  })
}

// Run the hook with our handlers
runHook({ preToolUse })
