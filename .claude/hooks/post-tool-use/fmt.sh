#!/usr/bin/env bash
set -euo pipefail

TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
FILE_PATH="${CLAUDE_FILE_PATH:-}"

if [[ "$TOOL_NAME" != "Edit" && "$TOOL_NAME" != "Write" ]]; then
  exit 0
fi

if [[ "$FILE_PATH" != *.tf ]]; then
  exit 0
fi

if ! command -v terraform &>/dev/null; then
  exit 0
fi

ENV_DIR=$(dirname "$FILE_PATH")
terraform -chdir="$ENV_DIR" fmt -write=true
echo "✅ terraform fmt applied to $ENV_DIR"
