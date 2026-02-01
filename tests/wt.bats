#!/usr/bin/env bats

setup() {
  TEST_DIR="$(cd "$(mktemp -d)" && pwd -P)"
  export PATH="$BATS_TEST_DIRNAME/../bin:$PATH"
  export GIT_CONFIG_NOSYSTEM=1

  cd "$TEST_DIR"
  git init -b main test-repo
  cd test-repo
  git config user.email "test@test.com"
  git config user.name "Test"
  git commit --allow-empty -m "init"

  REPO_DIR="$TEST_DIR/test-repo"
  WT_BASE="$TEST_DIR/worktrees/test-repo"
}

teardown() {
  cd /
  [ -n "${TEST_DIR:-}" ] && rm -rf "$TEST_DIR"
}

@test "T-01: wt new creates worktree at correct path" {
  cd "$REPO_DIR"
  run wt-core new feature-x
  [ "$status" -eq 0 ]
  [ -d "$WT_BASE/feature-x" ]
  [[ "$output" == *"$WT_BASE/feature-x"* ]]
}

@test "T-02: wt new with existing branch checks it out" {
  cd "$REPO_DIR"
  git branch existing-branch
  run wt-core new existing-branch
  [ "$status" -eq 0 ]
  [ -d "$WT_BASE/existing-branch" ]
  local branch
  branch="$(git -C "$WT_BASE/existing-branch" rev-parse --abbrev-ref HEAD)"
  [ "$branch" = "existing-branch" ]
}

@test "T-03: wt new with explicit base branch" {
  cd "$REPO_DIR"
  git branch develop
  git checkout develop
  git commit --allow-empty -m "develop commit"
  git checkout main

  run wt-core new feature-from-dev develop
  [ "$status" -eq 0 ]
  [ -d "$WT_BASE/feature-from-dev" ]

  local msg
  msg="$(git -C "$WT_BASE/feature-from-dev" log -1 --format='%s')"
  [ "$msg" = "develop commit" ]
}

@test "T-04: auto-detects main as base branch" {
  cd "$REPO_DIR"
  run wt-core new feature-auto
  [ "$status" -eq 0 ]
  [ -d "$WT_BASE/feature-auto" ]
}

@test "T-04b: auto-detects develop when main absent" {
  cd "$REPO_DIR"
  git branch develop
  git branch -M notmain
  run wt-core new feature-dev-base
  [ "$status" -eq 0 ]
  [ -d "$WT_BASE/feature-dev-base" ]
}

@test "T-04c: auto-detects master when main and develop absent" {
  cd "$REPO_DIR"
  git branch -M master
  run wt-core new feature-master-base
  [ "$status" -eq 0 ]
  [ -d "$WT_BASE/feature-master-base" ]
}

@test "T-04d: error when no base branch found" {
  cd "$REPO_DIR"
  git branch -M something-else
  run wt-core new feature-nobase
  [ "$status" -ne 0 ]
  [[ "$output" == *"base branch not found"* ]]
}

@test "T-04e: error when explicit base branch is invalid" {
  cd "$REPO_DIR"
  run wt-core new feature-bad-base nonexistent
  [ "$status" -ne 0 ]
  [[ "$output" == *"branch not found: nonexistent"* ]]
}

@test "T-05: env files copied to new worktree" {
  cd "$REPO_DIR"
  echo "SECRET=abc" > .env
  echo "LOCAL=xyz" > .env.local
  run wt-core new feature-env
  [ "$status" -eq 0 ]
  [ -f "$WT_BASE/feature-env/.env" ]
  [ -f "$WT_BASE/feature-env/.env.local" ]
  [ "$(cat "$WT_BASE/feature-env/.env")" = "SECRET=abc" ]
}

@test "T-06: detects pnpm from lockfile" {
  cd "$REPO_DIR"
  touch pnpm-lock.yaml
  git add -A && git commit -m "add lockfile"

  local mock_dir="$TEST_DIR/mock-bin"
  mkdir -p "$mock_dir"
  cat > "$mock_dir/pnpm" <<'EOF'
#!/usr/bin/env bash
echo "pnpm-mock called" >&2
EOF
  chmod +x "$mock_dir/pnpm"
  export PATH="$mock_dir:$PATH"

  run wt-core new feature-pnpm
  [ "$status" -eq 0 ]
  [[ "$output" == *"pnpm install"* ]]
}

@test "T-06b: detects npm from lockfile" {
  cd "$REPO_DIR"
  touch package-lock.json
  git add -A && git commit -m "add lockfile"

  local mock_dir="$TEST_DIR/mock-bin"
  mkdir -p "$mock_dir"
  cat > "$mock_dir/npm" <<'EOF'
#!/usr/bin/env bash
echo "npm-mock called" >&2
EOF
  chmod +x "$mock_dir/npm"
  export PATH="$mock_dir:$PATH"

  run wt-core new feature-npm
  [ "$status" -eq 0 ]
  [[ "$output" == *"npm install"* ]]
}

@test "T-07: error outside git repo" {
  cd "$TEST_DIR"
  mkdir not-a-repo
  cd not-a-repo
  run wt-core new feature-x
  [ "$status" -ne 0 ]
  [[ "$output" == *"not a git repository"* ]]
}

@test "T-08: error on duplicate worktree" {
  cd "$REPO_DIR"
  run wt-core new feature-dup
  [ "$status" -eq 0 ]
  run wt-core new feature-dup
  [ "$status" -ne 0 ]
  [[ "$output" == *"worktree already exists"* ]]
}

@test "T-09: wt cd outputs cd command for existing worktree" {
  cd "$REPO_DIR"
  run wt-core new feature-cd
  [ "$status" -eq 0 ]

  run wt-core cd feature-cd
  [ "$status" -eq 0 ]
  [[ "$output" == *"$WT_BASE/feature-cd"* ]]
}

@test "T-10: wt cd without args fails without fuzzy finder" {
  cd "$REPO_DIR"
  run wt-core new feature-fzf
  [ "$status" -eq 0 ]

  WT_FUZZY_FINDER="__nonexistent_fuzzy_finder__" run wt-core cd
  [ "$status" -ne 0 ]
}

@test "T-11: wt cd error on nonexistent worktree" {
  cd "$REPO_DIR"
  run wt-core cd nonexistent
  [ "$status" -ne 0 ]
  [[ "$output" == *"worktree not found"* ]]
}

@test "T-12: wt ls shows worktree list" {
  cd "$REPO_DIR"
  run wt-core new feature-ls
  [ "$status" -eq 0 ]

  cd "$REPO_DIR"
  run wt-core ls
  [ "$status" -eq 0 ]
  [[ "$output" == *"feature-ls"* ]]
}

@test "T-12b: wt ls shows star for current worktree" {
  cd "$REPO_DIR"
  run wt-core new feature-star
  [ "$status" -eq 0 ]

  cd "$WT_BASE/feature-star"
  run wt-core ls
  [ "$status" -eq 0 ]
  local current_line
  current_line="$(echo "$output" | grep "feature-star")"
  [[ "$current_line" == *"★"* ]]
}

@test "T-12c: wt ls shows dirty status" {
  cd "$REPO_DIR"
  run wt-core new feature-dirty
  [ "$status" -eq 0 ]

  echo "dirty" > "$WT_BASE/feature-dirty/dirty.txt"

  cd "$REPO_DIR"
  run wt-core ls
  [ "$status" -eq 0 ]
  local dirty_line
  dirty_line="$(echo "$output" | grep "feature-dirty")"
  [[ "$dirty_line" == *"changed"* ]]
}

@test "T-13: wt rm removes worktree and branch" {
  cd "$REPO_DIR"
  run wt-core new feature-rm
  [ "$status" -eq 0 ]
  [ -d "$WT_BASE/feature-rm" ]

  cd "$REPO_DIR"
  run wt-core rm feature-rm
  [ "$status" -eq 0 ]
  [ ! -d "$WT_BASE/feature-rm" ]
  run git branch --list feature-rm
  [ -z "$output" ]
}

@test "T-14: wt rm refuses dirty worktree" {
  cd "$REPO_DIR"
  run wt-core new feature-rm-dirty
  [ "$status" -eq 0 ]

  echo "uncommitted" > "$WT_BASE/feature-rm-dirty/file.txt"

  cd "$REPO_DIR"
  run wt-core rm feature-rm-dirty
  [ "$status" -ne 0 ]
  [[ "$output" == *"uncommitted changes"* ]]
  [ -d "$WT_BASE/feature-rm-dirty" ]
}

@test "T-15: wt rm refuses when inside target worktree" {
  cd "$REPO_DIR"
  run wt-core new feature-rm-inside
  [ "$status" -eq 0 ]

  cd "$WT_BASE/feature-rm-inside"
  run wt-core rm feature-rm-inside
  [ "$status" -ne 0 ]
  [[ "$output" == *"cannot remove current worktree"* ]]
}

@test "T-16: branch with slash works for new/cd/ls/rm" {
  cd "$REPO_DIR"
  run wt-core new feature/auth
  [ "$status" -eq 0 ]
  [[ "$output" == *"feature/auth"* ]]

  cd "$REPO_DIR"
  run wt-core cd feature/auth
  [ "$status" -eq 0 ]
  [[ "$output" == *"feature/auth"* ]]

  cd "$REPO_DIR"
  run wt-core ls
  [ "$status" -eq 0 ]
  [[ "$output" == *"feature/auth"* ]]

  cd "$REPO_DIR"
  run wt-core rm feature/auth
  [ "$status" -eq 0 ]
}

@test "T-17: shell wrapper rejects non-directory output" {
  # Define the wrapper function inline (same as install.sh)
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

  cd "$REPO_DIR"
  # wt new should succeed and cd into the worktree
  wt new feature-wrapper
  [ -d "$WT_BASE/feature-wrapper" ]
  [[ "$(pwd -P)" == *"feature-wrapper"* ]]
}

@test "T-18: commands work when run from inside a worktree" {
  cd "$REPO_DIR"
  run wt-core new feature-inner
  [ "$status" -eq 0 ]
  run wt-core new feature-other
  [ "$status" -eq 0 ]

  cd "$WT_BASE/feature-inner"
  run wt-core ls
  [ "$status" -eq 0 ]
  [[ "$output" == *"feature-inner"* ]]
  [[ "$output" == *"feature-other"* ]]

  run wt-core cd feature-other
  [ "$status" -eq 0 ]
  [[ "$output" == *"feature-other"* ]]
}
