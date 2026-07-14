#!/bin/bash
set -euo pipefail

export GIT_TERMINAL_PROMPT=0

if [ -z "${CURSOR_API_KEY:-}" ]; then
  echo "FATAL: CURSOR_API_KEY environment variable is missing."
  exit 1
fi

if [ -z "${REPO_URL:-}" ]; then
  echo "FATAL: REPO_URL environment variable is missing."
  exit 1
fi

if [ -n "${GIT_TOKEN:-}" ]; then
  git config --global credential.helper "!f() { echo username=oauth2; echo password=$GIT_TOKEN; }; f"
fi

REPO_DIR="/workspace/repo"
if [ ! -d "$REPO_DIR/.git" ]; then
  git clone "$REPO_URL" "$REPO_DIR"
fi

cd "$REPO_DIR"

AGENT_BIN=$(command -v agent || find /root -name agent -type f | head -n 1)
if [ -z "$AGENT_BIN" ]; then
  echo "FATAL: Could not find the Cursor 'agent' binary."
  exit 1
fi

exec "$AGENT_BIN" worker start \
  --api-key "$CURSOR_API_KEY" \
  --management-addr ":${PORT:-8080}" \
  --pool \
  --idle-release-timeout "${CURSOR_WORKER_IDLE_RELEASE_TIMEOUT:-600}" \
  "$@"
