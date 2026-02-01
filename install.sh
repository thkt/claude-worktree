#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${HOME}/.local/bin"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$INSTALL_DIR"
cp "$SCRIPT_DIR/bin/wt-core" "$INSTALL_DIR/wt-core"
chmod +x "$INSTALL_DIR/wt-core"

SHELL_FUNC='wt() { if [ "${1:-}" = "ls" ]; then wt-core "$@"; else local output; output="$(wt-core "$@")" || return $?; [[ "$output" =~ ^cd\ ]] || return 1; eval "$output"; fi; }'
ZSHRC="${HOME}/.zshrc"

if ! grep -q 'wt()' "$ZSHRC" 2>/dev/null; then
  echo "" >> "$ZSHRC"
  { echo "# claude-worktree"; echo "$SHELL_FUNC"; } >> "$ZSHRC"
  echo "▸ Added wt() to $ZSHRC"
else
  echo "▸ wt() already exists in $ZSHRC"
fi

echo "▸ Installed wt-core to $INSTALL_DIR"
echo "▸ Run: source $ZSHRC"
