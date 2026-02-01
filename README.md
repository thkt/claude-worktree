# claude-worktree (wt)

Git worktree wrapper for parallel development. Create, switch, list, and remove worktrees with a single command.

## Install

```bash
./install.sh
source ~/.zshrc
```

Requires: `git`, `bash`, `zsh` or `bash` (shell wrapper auto-detected). Optionally `sk` or `fzf` for interactive selection.

Override the fuzzy finder with `WT_FUZZY_FINDER=<command>`.

## Usage

### Create a worktree

```bash
wt new feature-auth            # New branch from main
wt new feature-auth develop    # New branch from develop
wt new existing-branch         # Checkout existing branch
```

Creates worktree at `../worktrees/<repo>/<branch>/`, copies `.env*` files, and auto-runs dependency install based on lockfiles.

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
★ feature-auth    3 changed  ↑2 ↓0  fix: add token validation
  bugfix-123      clean      ↑0 ↓3  refactor: simplify query
  main            clean      ↑0 ↓0  chore: update deps
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
├── my-repo/                    # Main repository
└── worktrees/
    └── my-repo/
        ├── feature-auth/       # Worktree
        └── bugfix-123/         # Worktree
```

## License

MIT
