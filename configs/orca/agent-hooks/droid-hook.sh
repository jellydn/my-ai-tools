#!/bin/sh

if [ -n "$ORCA_AGENT_HOOK_ENDPOINT" ] && [ -r "$ORCA_AGENT_HOOK_ENDPOINT" ]; then
  . "$ORCA_AGENT_HOOK_ENDPOINT" 2>/dev/null || :
fi

if [ -z "$ORCA_AGENT_HOOK_PORT" ] || [ -z "$ORCA_AGENT_HOOK_TOKEN" ] || [ -z "$ORCA_PANE_KEY" ]; then
  exit 0
fi

payload=$(cat)
if [ -z "$payload" ]; then
  exit 0
fi

curl -sS -X POST "http://127.0.0.1:${ORCA_AGENT_HOOK_PORT}/hook/droid" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "X-Orca-Agent-Hook-Token: ${ORCA_AGENT_HOOK_TOKEN}" \
  --data-urlencode "paneKey=${ORCA_PANE_KEY}" \
  --data-urlencode "tabId=${ORCA_TAB_ID}" \
  --data-urlencode "worktreeId=${ORCA_WORKTREE_ID}" \
  --data-urlencode "env=${ORCA_AGENT_HOOK_ENV}" \
  --data-urlencode "version=${ORCA_AGENT_HOOK_VERSION}" \
  --data-urlencode "payload=${payload}" >/dev/null 2>&1 || true

exit 0
