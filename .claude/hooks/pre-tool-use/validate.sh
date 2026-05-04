#!/usr/bin/env bash
set -euo pipefail

TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
FILE_PATH="${CLAUDE_FILE_PATH:-}"

if [[ "$TOOL_NAME" != "Edit" && "$TOOL_NAME" != "Write" ]]; then
  exit 0
fi

if [[ "$FILE_PATH" != *"/accounts/"* ]] || [[ "$FILE_PATH" != *.tf ]]; then
  exit 0
fi

if ! command -v terraform &>/dev/null; then
  echo "terraform not found in PATH — skipping fmt check" >&2
  exit 0
fi

ENV_DIR=$(dirname "$FILE_PATH")

echo "Running terraform fmt -check in $ENV_DIR..."
if ! terraform -chdir="$ENV_DIR" fmt -check -diff 2>&1; then
  echo "❌ Formatting errors found. Run 'terraform fmt' to fix." >&2
  exit 1
fi

echo "✅ terraform fmt check passed"
