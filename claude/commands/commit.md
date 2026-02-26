# Git Commit

Stage all changes, pull latest (merging any conflicts), commit, and push to remote.

Follow these steps exactly and in order. Do not skip steps or ask for confirmation unless a merge conflict requires a decision.

## Step 1 — Inspect current state

Run these in parallel:
- `git status` — identify untracked, modified, and deleted files
- `git log --oneline -5` — understand recent commit message style
- `git diff HEAD` — review all unstaged changes

Report a brief summary of what you find before continuing.

## Step 2 — Stage all changes

Run:
```
git add -A
```

Then run `git status` to confirm everything is staged. Warn the user if any sensitive-looking files (`.env`, credentials, secrets) are about to be committed and pause for confirmation before continuing.

## Step 3 — Pull latest from remote

Run:
```
git pull --no-rebase
```

If the pull succeeds cleanly, continue to Step 4.

**If merge conflicts occur:**
1. Run `git diff --diff-filter=U` to list conflicted files
2. Read each conflicted file
3. Resolve conflicts by keeping the most complete/correct version of each section — prefer incoming changes for new features, local changes for in-progress work
4. Stage the resolved files with `git add <file>`
5. Run `git status` to confirm all conflicts are resolved
6. Continue to Step 4

**If the pull fails for any other reason** (e.g. no remote, diverged history), report the error clearly and stop. Do not force-push or reset.

## Step 4 — Commit

Draft a commit message based on `git diff HEAD~1..HEAD` (to see what changed vs last commit) and the staged diff:
- Use conventional commit format: `type: short description`
- Valid types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`
- Keep the subject line under 72 characters
- Add a short body (2-4 bullets) if the change spans multiple concerns

Create the commit using a HEREDOC to preserve formatting:
```
git commit -m "$(cat <<'EOF'
<your message here>
EOF
)"
```

## Step 5 — Push

Run:
```
git push
```

If the push is rejected because the remote has new commits (non-fast-forward after a failed pull), report the error and stop — do not force-push.

## Step 6 — Report

Print a summary:
- Files staged
- Merge conflicts resolved (if any)
- Commit hash and message (`git log --oneline -1`)
- Push result
