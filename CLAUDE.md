# CLAUDE.md

## Worktree-Only Workflow (Enforced)

**All file modifications are blocked in the main checkout.** A PreToolUse hook (`enforce-worktree.sh`) rejects Edit, Write, and NotebookEdit operations targeting files outside a worktree. There are no opt-outs. Do not use Bash to write files in the main checkout either (e.g., `echo >`, `sed -i`, `tee`, `cp`) — the hook cannot intercept shell commands, so this rule is instruction-enforced.

Before writing any code, create a worktree:

```bash
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@refs/remotes/origin/@@')
DEFAULT_BRANCH=${DEFAULT_BRANCH:-main}
git fetch origin "$DEFAULT_BRANCH"
git worktree add .worktrees/<name> -b <branch-name> "origin/$DEFAULT_BRANCH"
```

Then work inside `.worktrees/<name>/` for the rest of the session.

**Naming:** Use a task slug (e.g., `.worktrees/fix-auth-timeout`) or today's date (e.g., `.worktrees/2026-04-01`).

**The hook allows modifications only when:**

1. The file is inside a git worktree (detected via `git rev-parse --git-dir` returning a path under `.git/worktrees/`)
2. Running in a CI/automated context where the checkout is already isolated
**Why this matters:** Working directly on the main checkout causes cross-contamination between sessions — uncommitted changes, wrong branches, and dirty state leak into unrelated work. Worktrees eliminate this entirely.

See the `/worktree` and `/start` skills for full conventions and flags.

## What this gem is

`standard_id-provider` is the **OpenID Connect Identity Provider addon** for `standard_id`: ID tokens, consent grants, an access-token revocation denylist, and the OIDC discovery document.

It is **not** "scaffolding for building provider plugins" — that description was wrong and is corrected here. `standard_id-apple` and `standard_id-google` are social-login provider plugins with no relationship to this gem beyond the name.

See `AGENTS.md` for the engine surface and `README.md` for the coupling this gem asks a consumer to accept.

## Consumers

**None yet.** No app in the rarebit-one workspace consumes it.

If this gem gains consumers, document them here and add it to the consumer matrix in the workspace-level `/rollout-gem` skill's `SKILL.md` (one directory above this repo).
