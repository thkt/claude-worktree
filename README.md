# claude-worktree (wt)

Git worktree wrapper for parallel development. Create, switch, list, and remove worktrees with a single command.

## Install

```bash
./install.sh
source ~/.zshrc  # or ~/.bashrc for bash users
```

Requires: `git`, `zsh` (core script). The shell wrapper (`wt` function) works in both zsh and bash. Optionally `sk` or `fzf` for interactive selection.

Override the fuzzy finder with `WT_FUZZY_FINDER=<command>`.

## Usage

### Create a worktree

```bash
wt new feature-auth            # New branch from main
wt new feature-auth develop    # New branch from develop
wt new existing-branch         # Checkout existing branch
wt new --no-env feature-auth   # Skip .env file copy
```

Creates worktree at `../worktrees/<branch>/`, copies `.env*` files (with confirmation in interactive mode), and auto-runs dependency install based on lockfiles. Branch names with `/` are converted to `-` in directory names (e.g. `feature/auth` → `feature-auth`).

### Switch to a worktree

```bash
wt cd feature-auth    # Direct switch
wt cd                 # Interactive selection (sk/fzf)
```

### List worktrees

```bash
wt ls
```

```
  main            clean      ↑0 ↓0  chore: initial setup
★ feature-auth    3 changed  ↑2 ↓0  fix: add token validation
  bugfix-123      clean      ↑0 ↓3  refactor: simplify query
  feature-api     clean      ↑0 ↓0  feat: add REST endpoints
```

### Remove a worktree

```bash
wt rm feature-auth    # Remove worktree + local branch
wt rm                 # Interactive selection (sk/fzf)
```

Refuses to remove worktrees with uncommitted changes.

## Auto-detected setup

On `wt new`, the following are automatically executed based on files present:

| File                            | Command        |
| ------------------------------- | -------------- |
| `pnpm-lock.yaml`                | `pnpm install` |
| `package-lock.json`             | `npm install`  |
| `yarn.lock`                     | `yarn install` |
| `bun.lockb`                     | `bun install`  |
| `.mise.toml` / `.tool-versions` | `mise install` |
| `.envrc`                        | `direnv allow` |

## Directory layout

```
parent/
├── my-repo/              # Main repository
└── worktrees/
    ├── feature-auth/     # Worktree
    └── bugfix-123/       # Worktree
```

## License

MIT
