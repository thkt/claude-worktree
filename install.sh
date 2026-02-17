#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${HOME}/.local/bin"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$INSTALL_DIR"
cp "$SCRIPT_DIR/bin/wt-core" "$INSTALL_DIR/wt-core"
chmod +x "$INSTALL_DIR/wt-core"

case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *) echo "▸ Warning: $INSTALL_DIR is not in PATH" >&2 ;;
esac

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
    [ -d "$output" ] || { echo "error: unexpected output: $output" >&2; return 1; }
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
    tmp="$(mktemp)"
    trap 'rm -f "$tmp"' EXIT
    MARKER_BEGIN="$MARKER_BEGIN" MARKER_END="$MARKER_END" SHELL_BLOCK="$SHELL_BLOCK" \
    awk '
      $0 == ENVIRON["MARKER_BEGIN"] { skip=1; print ENVIRON["SHELL_BLOCK"]; next }
      $0 == ENVIRON["MARKER_END"] { skip=0; next }
      !skip { print }
    ' "$RC_FILE" > "$tmp"
    [ -s "$tmp" ] || { rm -f "$tmp"; echo "error: failed to generate updated RC file" >&2; exit 1; }
    cp -p "$RC_FILE" "${RC_FILE}.bak"
    orig_perms="$(stat -f '%Lp' "$RC_FILE" 2>/dev/null)" || \
      orig_perms="$(stat -c '%a' "$RC_FILE" 2>/dev/null)" || \
      orig_perms="644"
    chmod "$orig_perms" "$tmp"
    mv "$tmp" "$RC_FILE"
    echo "▸ Updated wt() in $RC_FILE (backup: ${RC_FILE}.bak)"
  else
    echo "" >> "$RC_FILE"
    echo "$SHELL_BLOCK" >> "$RC_FILE"
    echo "▸ Added wt() to $RC_FILE"
  fi
  echo "▸ Installed wt-core to $INSTALL_DIR"
  echo "▸ Run: source $RC_FILE"
fi
