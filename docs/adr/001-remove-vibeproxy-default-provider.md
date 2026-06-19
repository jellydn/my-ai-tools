# 1. Remove Vibeproxy as Pi Default Provider

Date: 2026-06-20

## Status

Accepted

## Context

Vibeproxy was configured as a Pi provider for multi-account rotation and local model routing, routing through Google Antigravity and Anthropic accounts via a local proxy on port `51200`. Over time, several issues emerged:

1. **Stability concerns** — Vibeproxy proved unreliable in practice, with frequent connection drops and inconsistent model availability.
2. **Maintenance burden** — Keeping the vibeproxy provider configuration in sync with upstream changes required constant attention.
3. **Model duplication** — Vibeproxy models (`claude-opus-4-6-thinking`, `gemini-3-flash-agent`, `gemini-pro-agent`) overlapped with models available through other more stable providers (`commandcode`, `google-antigravity`).
4. **User confusion** — Having both `vibeproxy` and `google-antigravity` as options with overlapping model sets created ambiguity about which provider to use.

The `commandcode` provider offered a more reliable alternative with access to the same class of models (DeepSeek, MiniMax, Kimi) through a stable API, plus direct access to `cursor/auto` and `cursor/composer-2.5` models.

## Decision

1. **Remove vibeproxy** from Pi's `enabledModels` and `models.json` entirely.
2. **Switch default provider** from `xiaomi-token-plan-sgp` to `commandcode` with `deepseek/deepseek-v4-pro` as the default model.
3. **Remove the Vibeproxy section** from the README, replacing it with a Pi Antigravity Rotator section that covers only the stable `pi-antigravity-rotator` tool.
4. **Update tests** to reflect the new defaults and remove vibeproxy-related test assertions.

The full set of enabled models after the change:

| Provider              | Models                                                                   |
| --------------------- | ------------------------------------------------------------------------ |
| github-copilot        | `gpt-5-mini`, `gpt-4.1`, `gpt-5.4`                                       |
| commandcode           | `moonshotai/Kimi-K2.6`, `xiaomi/mimo-v2.5-pro`                           |
|                       | `deepseek/deepseek-v4-pro`, `deepseek/deepseek-v4-flash`                 |
|                       | `MiniMaxAI/MiniMax-M3`, `MiniMaxAI/MiniMax-M2.7`                         |
| ollama                | `minimax-m2.5:cloud`                                                     |
| openrouter            | `openrouter/owl-alpha`                                                   |
| google                | `gemini-3.5-flash`                                                       |
| cursor                | `auto`, `composer-2.5`                                                   |

## Consequences

### 📋 Positive

- **Simpler provider matrix** — One fewer provider to maintain, test, and document.
- **More reliable defaults** — `commandcode`/`deepseek` is more stable than the vibeproxy proxy setup.
- **Clearer documentation** — README no longer references an unstable tool as a recommended path.
- **Reduced CI surface** — Fewer model assertions to maintain in tests.

### 📋 Negative

- **Loss of multi-account rotation** — Users relying on vibeproxy for account rotation lose that capability. The `pi-antigravity-rotator` remains as an alternative for Google Antigravity rotation.
- **No Anthropic models via proxy** — `claude-opus-4-6-thinking` and `claude-sonnet-4-6` were accessible through vibeproxy. These are no longer available through the Pi config by default.
