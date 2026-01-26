#!/usr/bin/env bun

/**
 * Context Advisor
 * Analyzes session context and provides strategic recommendations
 * Complements the built-in /context command with actionable guidance
 */

import { statSync } from 'fs';
import { resolve } from 'path';

const CONTEXT_LIMIT = 200_000; // 200k tokens

interface ContextReport {
  filePath: string;
  fileSizeMB: number;
  estimatedTokens: number;
  usagePercentage: number;
  status: 'healthy' | 'moderate' | 'high' | 'critical';
  icon: string;
  recommendation: string;
  strategicAdvice: string[];
  nextSteps: string[];
}

interface StatusInfo {
  status: ContextReport['status'];
  icon: string;
  recommendation: string;
  strategicAdvice: string[];
  nextSteps: string[];
}

function getStatusAndRecommendation(percentage: number): StatusInfo {
  if (percentage < 50) {
    return {
      status: 'healthy',
      icon: '✅',
      recommendation: 'Context usage is healthy. You have plenty of room to continue working.',
      strategicAdvice: [
        'This is the optimal operating range for complex tasks',
        'Feel free to explore the codebase, read large files, and iterate on changes',
        'No immediate action needed regarding context management'
      ],
      nextSteps: [
        'Continue your current work normally',
        'Use /context for detailed breakdown if needed'
      ]
    };
  } else if (percentage < 75) {
    return {
      status: 'moderate',
      icon: '📋',
      recommendation: 'Context usage is moderate. Consider planning ahead if this is a long-running task.',
      strategicAdvice: [
        'You still have comfortable working room, but should be mindful',
        'Avoid reading very large files unless necessary',
        'Consider if the current task is near completion'
      ],
      nextSteps: [
        'Continue working, but monitor context as you progress',
        'If starting a new major feature, consider creating a handoff at a natural breakpoint',
        'Use /context to see what\'s consuming the most tokens'
      ]
    };
  } else if (percentage < 90) {
    return {
      status: 'high',
      icon: '⚠️',
      recommendation: 'Context usage is high. Recommend creating a handoff soon.',
      strategicAdvice: [
        'You\'re approaching context limits - plan your exit strategy',
        'Complete your current task and create a handoff before starting new work',
        'Limited room for exploring large codebases or reading many files'
      ],
      nextSteps: [
        'Finish your current task',
        'Run: /handoffs <purpose> to create a handoff document',
        'Start a new session and use /pickup <filename> to continue',
        'Use /context to identify what\'s using the most tokens'
      ]
    };
  } else {
    return {
      status: 'critical',
      icon: '🚨',
      recommendation: 'Context usage is critical! Create a handoff immediately.',
      strategicAdvice: [
        'URGENT: You are at or beyond context limits',
        'Risk of context overflow and degraded performance',
        'Cannot safely continue complex operations'
      ],
      nextSteps: [
        'IMMEDIATE: Run /handoffs <purpose>',
        'Close this session and start a new one',
        'Run /pickup <filename> in the new session to resume',
        'Do NOT attempt to read more files or start new tasks'
      ]
    };
  }
}

function generateProgressBar(percentage: number, width: number = 40): string {
  // Clamp percentage to valid range for display
  const displayPercentage = Math.max(0, Math.min(percentage, 100));
  const filled = Math.round((displayPercentage / 100) * width);
  const empty = Math.max(0, width - filled);

  let color: string;
  if (percentage < 50) color = '🟢';
  else if (percentage < 75) color = '🟡';
  else if (percentage < 90) color = '🟠';
  else color = '🔴';

  return `${color} [${'█'.repeat(filled)}${' '.repeat(empty)}] ${percentage.toFixed(1)}%`;
}

function analyzeContext(transcriptPath: string): ContextReport {
  const resolvedPath = resolve(transcriptPath);

  try {
    const stats = statSync(resolvedPath);
    const fileSizeMB = stats.size / (1024 * 1024);
    const estimatedTokens = Math.round(stats.size / 4); // Approximate: bytes ÷ 4 = tokens
    const usagePercentage = (estimatedTokens / CONTEXT_LIMIT) * 100;

    const { status, icon, recommendation, strategicAdvice, nextSteps } = getStatusAndRecommendation(usagePercentage);

    return {
      filePath: resolvedPath,
      fileSizeMB,
      estimatedTokens,
      usagePercentage,
      status,
      icon,
      recommendation,
      strategicAdvice,
      nextSteps,
    };
  } catch (error) {
    if (error instanceof Error) {
      throw new Error(`Failed to analyze transcript: ${error.message}`);
    }
    throw error;
  }
}

function formatReport(report: ContextReport): string {
  const sections = [
    '═══════════════════════════════════════════════',
    '           CONTEXT ADVISOR REPORT',
    '═══════════════════════════════════════════════',
    '',
    `📊 Estimated Usage: ${report.estimatedTokens.toLocaleString()} / ${CONTEXT_LIMIT.toLocaleString()} tokens`,
    '',
    generateProgressBar(report.usagePercentage),
    '',
    `Status: ${report.icon} ${report.status.toUpperCase()}`,
    '',
    '───────────────────────────────────────────────',
    '💡 RECOMMENDATION',
    '───────────────────────────────────────────────',
    report.recommendation,
    '',
    '───────────────────────────────────────────────',
    '📋 STRATEGIC ADVICE',
    '───────────────────────────────────────────────',
    ...report.strategicAdvice.map(advice => `  • ${advice}`),
    '',
    '───────────────────────────────────────────────',
    '🎯 NEXT STEPS',
    '───────────────────────────────────────────────',
    ...report.nextSteps.map((step, index) => `  ${index + 1}. ${step}`),
    '',
    '───────────────────────────────────────────────',
    '💭 TIP: Use /context for detailed token breakdown',
    '═══════════════════════════════════════════════',
  ];

  return sections.join('\n');
}

function main() {
  const transcriptPath = process.env.CLAUDE_TRANSCRIPT_PATH || process.argv[2];

  if (!transcriptPath) {
    console.error('Error: Transcript path not provided.');
    console.error('Usage: bun check-context.ts <transcript-path>');
    console.error('   or: Set CLAUDE_TRANSCRIPT_PATH environment variable');
    process.exit(1);
  }

  try {
    const report = analyzeContext(transcriptPath);
    console.log(formatReport(report));
  } catch (error) {
    console.error(`Error: ${error instanceof Error ? error.message : 'Unknown error'}`);
    process.exit(1);
  }
}

main();
