#!/usr/bin/env bun

import { checkGitCommand } from "./git-guard";
import type {
  NotificationHandler,
  PostToolUseHandler,
  PreCompactHandler,
  PreToolUseHandler,
  SessionStartHandler,
  StopHandler,
  SubagentStopHandler,
  UserPromptSubmitHandler,
} from "./lib";
import { runHook } from "./lib";
import { saveSessionData } from "./session";

const sessionStart: SessionStartHandler = async (payload) => {
  await saveSessionData("SessionStart", {
    ...payload,
    hook_type: "SessionStart",
  } as const);

  console.log(`Session started from: ${payload.source}`);

  return {};
};

const preToolUse: PreToolUseHandler = async (payload) => {
  await saveSessionData("PreToolUse", {
    ...payload,
    hook_type: "PreToolUse",
  } as const);

  if (payload.tool_input && "command" in payload.tool_input) {
    const command = (payload.tool_input as { command: string }).command;

    const gitCheck = checkGitCommand(command);
    if (!gitCheck.allowed) {
      console.error(`❌ ${gitCheck.reason}`);
      return {
        permissionDecision: "deny",
        permissionDecisionReason: gitCheck.reason,
      };
    }

    if (command.includes("rm -rf /") || command.includes("rm -rf ~")) {
      console.error("❌ Dangerous command detected! Blocking execution.");
      return {
        permissionDecision: "deny",
        permissionDecisionReason: `Dangerous command detected: ${command}`,
      };
    }
  }

  return {};
};

const postToolUse: PostToolUseHandler = async (payload) => {
  await saveSessionData("PostToolUse", {
    ...payload,
    hook_type: "PostToolUse",
  } as const);

  return {};
};

const notification: NotificationHandler = async (payload) => {
  await saveSessionData("Notification", {
    ...payload,
    hook_type: "Notification",
  } as const);

  return {};
};

const stop: StopHandler = async (payload) => {
  await saveSessionData("Stop", { ...payload, hook_type: "Stop" } as const);

  return {};
};

const subagentStop: SubagentStopHandler = async (payload) => {
  await saveSessionData("SubagentStop", {
    ...payload,
    hook_type: "SubagentStop",
  } as const);

  return {};
};

const userPromptSubmit: UserPromptSubmitHandler = async (payload) => {
  await saveSessionData("UserPromptSubmit", {
    ...payload,
    hook_type: "UserPromptSubmit",
  } as const);

  const contextFiles: string[] = [];
  if (payload.prompt.includes("delete all")) {
    console.error("⚠️  Dangerous prompt detected! Blocking.");
    return {
      decision: "block",
      reason: 'Prompts containing "delete all" are not allowed',
    };
  }

  return contextFiles.length > 0 ? { contextFiles } : {};
};

const preCompact: PreCompactHandler = async (payload) => {
  await saveSessionData("PreCompact", {
    ...payload,
    hook_type: "PreCompact",
  } as const);

  return {};
};

// Run the hook with our handlers
runHook({
  sessionStart,
  preToolUse,
  postToolUse,
  notification,
  stop,
  subagentStop,
  userPromptSubmit,
  preCompact,
});
