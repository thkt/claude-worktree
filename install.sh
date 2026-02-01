#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${HOME}/.local/bin"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$INSTALL_DIR"
cp "$SCRIPT_DIR/bin/wt-core" "$INSTALL_DIR/wt-core"
chmod +x "$INSTALL_DIR/wt-core"

MARKER_BEGIN="# BEGIN claude-worktree"
MARKER_END="# END claude-worktree"

read -r -d '' SHELL_BLOCK <<'BLOCK' || true
# BEGIN claude-worktree
wt() {
  if [ "${1:-}" = "ls" ]; then
    wt-core "$@"
  else
    local output
    output="$(wt-core "$@")" || return $?
    [ -d "$output" ] || return 1
    cd "$output"
  fi
}
# END claude-worktree
BLOCK

detect_rc_file() {
  local shell_name
  shell_name="$(basename "${SHELL:-/bin/bash}")"
  case "$shell_name" in
    zsh)  echo "${HOME}/.zshrc" ;;
    bash) echo "${HOME}/.bashrc" ;;
    *)    echo "" ;;
  esac
}

RC_FILE="$(detect_rc_file)"

if [ -z "$RC_FILE" ]; then
  echo "▸ Unsupported shell: $SHELL"
  echo "▸ Add manually:"
  echo "$SHELL_BLOCK"
else
  if grep -q "$MARKER_BEGIN" "$RC_FILE" 2>/dev/null; then
    # Replace existing block
    tmp="$(mktemp)"
    awk -v begin="$MARKER_BEGIN" -v end="$MARKER_END" -v block="$SHELL_BLOCK" '
      $0 == begin { skip=1; print block; next }
      $0 == end { skip=0; next }
      !skip { print }
    ' "$RC_FILE" > "$tmp"
    mv "$tmp" "$RC_FILE"
    echo "▸ Updated wt() in $RC_FILE"
  else
    echo "" >> "$RC_FILE"
    echo "$SHELL_BLOCK" >> "$RC_FILE"
    echo "▸ Added wt() to $RC_FILE"
  fi
  echo "▸ Installed wt-core to $INSTALL_DIR"
  echo "▸ Run: source $RC_FILE"
fi
