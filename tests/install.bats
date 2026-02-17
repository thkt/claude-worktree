#!/usr/bin/env bats

setup() {
  TEST_DIR="$(cd "$(mktemp -d)" && pwd -P)"
  export FAKE_HOME="$TEST_DIR/home"
  mkdir -p "$FAKE_HOME/.local/bin"
  export INSTALL_SCRIPT="$BATS_TEST_DIRNAME/../install.sh"
}

teardown() {
  cd /
  if [ -n "${TEST_DIR:-}" ] && [ -d "$TEST_DIR" ]; then
    case "$TEST_DIR" in
      /tmp/*|/private/*|/var/folders/*) rm -rf "$TEST_DIR" ;;
      *) echo "WARNING: refusing to rm unexpected TEST_DIR: $TEST_DIR" >&2 ;;
    esac
  fi
}

@test "I-01: install adds wt block to zshrc" {
  touch "$FAKE_HOME/.zshrc"
  HOME="$FAKE_HOME" SHELL="/bin/zsh" bash "$INSTALL_SCRIPT"
  grep -q "# BEGIN claude-worktree" "$FAKE_HOME/.zshrc"
  grep -q "# END claude-worktree" "$FAKE_HOME/.zshrc"
  grep -q "wt()" "$FAKE_HOME/.zshrc"
}

@test "I-02: install is idempotent (no duplicate blocks)" {
  touch "$FAKE_HOME/.zshrc"
  HOME="$FAKE_HOME" SHELL="/bin/zsh" bash "$INSTALL_SCRIPT"
  HOME="$FAKE_HOME" SHELL="/bin/zsh" bash "$INSTALL_SCRIPT"
  local count
  count="$(grep -c '# BEGIN claude-worktree' "$FAKE_HOME/.zshrc")"
  [ "$count" -eq 1 ]
}

@test "I-03: install preserves existing content in RC file" {
  echo 'export FOO=bar' > "$FAKE_HOME/.zshrc"
  HOME="$FAKE_HOME" SHELL="/bin/zsh" bash "$INSTALL_SCRIPT"
  grep -q 'export FOO=bar' "$FAKE_HOME/.zshrc"
  grep -q '# BEGIN claude-worktree' "$FAKE_HOME/.zshrc"
}

@test "I-04: update creates backup file" {
  touch "$FAKE_HOME/.zshrc"
  HOME="$FAKE_HOME" SHELL="/bin/zsh" bash "$INSTALL_SCRIPT"
  HOME="$FAKE_HOME" SHELL="/bin/zsh" bash "$INSTALL_SCRIPT"
  [ -f "$FAKE_HOME/.zshrc.bak" ]
}

@test "I-05: install detects bashrc for bash shell" {
  touch "$FAKE_HOME/.bashrc"
  HOME="$FAKE_HOME" SHELL="/bin/bash" bash "$INSTALL_SCRIPT"
  grep -q '# BEGIN claude-worktree' "$FAKE_HOME/.bashrc"
}

@test "I-06: wt-core binary is copied to install dir" {
  touch "$FAKE_HOME/.zshrc"
  HOME="$FAKE_HOME" SHELL="/bin/zsh" bash "$INSTALL_SCRIPT"
  [ -x "$FAKE_HOME/.local/bin/wt-core" ]
}
