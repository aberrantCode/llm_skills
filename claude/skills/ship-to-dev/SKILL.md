---
name: ship-to-dev
description: Use when the user wants to ship current working changes through a feature branch PR into the DEV branch — covers pulling latest, staging, committing, pushing, PR creation, merge, branch cleanup, and syncing DEV locally.
---

# Ship to DEV

Automates the full feature-branch → DEV merge workflow for this repository.
Run this whenever you have uncommitted work ready to integrate into DEV, **or**
when you already have a committed feature branch that just needs to be pushed,
PR'd, and merged.

---

## Prerequisites: Ensure DEV Exists

Before starting the main workflow, confirm `dev` exists on the remote.
If it does not, create it from `main` now:

```bash
# Check whether dev exists on origin
git ls-remote --heads origin dev

# If nothing was returned — create it:
git fetch origin main
git checkout -b dev origin/main
git push -u origin dev
git checkout main   # return to main (or wherever you were)
```

> If `dev` already exists, skip this block entirely.

---

## Workflow

Follow every step in order. Do not skip steps, do not reorder them.

### Step 0 — Detect context and resolve the repo root

Before anything else, determine where you are and whether the work is already committed.

**Resolve the repo root** — all git/gh commands in Steps 5–9 must run from the repo root,
never from inside a worktree subdirectory:

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
echo "Repo root: $REPO_ROOT"
```

**Check for an active worktree** — if the current directory is inside a git worktree that
is *not* the primary checkout, record the worktree path for cleanup in Step 9:

```bash
WORKTREE_PATH=$(git rev-parse --show-toplevel)
PRIMARY_ROOT=$(git worktree list --porcelain | awk 'NR==1{print $2}')
# If they differ, we are inside a secondary worktree
[ "$WORKTREE_PATH" != "$PRIMARY_ROOT" ] && IN_WORKTREE=true || IN_WORKTREE=false
echo "In secondary worktree: $IN_WORKTREE"
```

**Detect pre-committed branch** — if the current branch already has commits ahead of `dev`
and is not `dev` itself, the work is already committed. Skip Steps 1–4 and jump to Step 5:

```bash
CURRENT_BRANCH=$(git branch --show-current)
AHEAD=$(git rev-list origin/dev..HEAD --count 2>/dev/null || echo 0)
echo "Current branch: $CURRENT_BRANCH  Commits ahead of dev: $AHEAD"
```

- If `$CURRENT_BRANCH` is not `dev` and `$AHEAD > 0` → set `$BRANCH=$CURRENT_BRANCH`,
  infer `$MSG` from the most recent commit subject (`git log -1 --format=%s`), then
  **skip to Step 5**.
- Otherwise → continue to Step 1 as normal.

---

### Step 1 — Ask the user for a branch name and commit message

Before touching git, collect `$BRANCH` and `$MSG`.

If the user has already provided both in their message, use those values directly — do not ask again.

Otherwise, infer up to two suggested values each from the staged/unstaged diff and recent commits, then use **AskUserQuestion** with those suggestions as options (the tool automatically appends an "Other" option for free-text input):

```
AskUserQuestion(
  questions: [
    {
      question: "What should the feature branch be called?",
      header: "Branch name",
      options: [
        { label: "fix/autologon-reboot-privacy-screen", description: "Inferred from changes" },
        { label: "feat/my-feature", description: "Alternative suggestion" }
      ]
    },
    {
      question: "What is the commit message?",
      header: "Commit msg",
      options: [
        { label: "fix: reboot instead of logoff and suppress OOBE privacy screen", description: "Inferred from changes" },
        { label: "feat: describe the change", description: "Alternative suggestion" }
      ]
    }
  ]
)
```

Branch format: `<type>/<short-slug>` — types mirror conventional commits (`feat`, `fix`, `refactor`, `docs`, `chore`).
Commit format: conventional commit (`feat:`, `fix:`, `refactor:`, etc.).

Store answers as `$BRANCH` and `$MSG` for the rest of the steps.

---

### Step 2 — Pull latest on the current branch (only if behind)

First fetch and check whether the current branch is behind its remote — skip the pull entirely if there is nothing to integrate:

```bash
git fetch origin
BEHIND=$(git rev-list HEAD..origin/$(git branch --show-current) --count 2>/dev/null || echo 0)
echo "Commits behind remote: $BEHIND"
```

**If `$BEHIND` is 0** — nothing to pull. Skip the rest of this step and continue to Step 3.

**If `$BEHIND` > 0** — stash everything (tracked and untracked), pull, then restore:

```bash
git stash --include-untracked
git pull --rebase
git stash pop
```

If rebase produces conflicts after the pull:
1. Show the conflicting files with `git status`.
2. Resolve obvious ones (whitespace, generated files) yourself. For non-obvious conflicts, use **AskUserQuestion**:
   ```
   AskUserQuestion(
     questions: [{
       question: "There are merge conflicts in <files>. How would you like to proceed?",
       header: "Conflicts",
       options: [
         { label: "I'll resolve manually", description: "Pause here — you fix the files, then tell me to continue" },
         { label: "Abort the rebase", description: "Run git rebase --abort and stop the workflow" }
       ]
     }]
   )
   ```
3. After resolution: `git add <resolved-files>` then `git rebase --continue`.
4. If the rebase is unresolvable, abort with `git rebase --abort` and stop.

---

### Step 3 — Stage all changes

```bash
git add --all
```

Show a summary to the user before continuing:

```bash
git status --short
git diff --cached --stat
```

If the staging area is empty (nothing to commit), stop and tell the user there is nothing to ship.

---

### Step 4 — Create the feature branch and commit

```bash
git checkout -b $BRANCH
git commit -m "$MSG"
```

Verify the commit was created:

```bash
git log --oneline -1
```

---

### Step 5 — Push the feature branch to origin

```bash
git push -u origin $BRANCH
```

---

### Step 6 — Create a PR targeting DEV

```bash
gh pr create \
  --base dev \
  --head $BRANCH \
  --title "$MSG" \
  --body "$(cat <<'EOF'
## Summary
Automated feature branch PR targeting DEV.

## Changes
See commit diff for details.

## Test plan
- [ ] Smoke-tested locally before shipping
EOF
)"
```

Capture and display the PR URL from the output.

---

### Step 7 — Merge the PR (squash merge)

**Important:** `gh pr merge` will attempt to switch the local working tree to `dev`
after merging. If `dev` is already checked out in a primary worktree and you are
running from a secondary worktree, this will fail with
`fatal: 'dev' is already used by worktree`. Always run this command from
`$REPO_ROOT` (the primary checkout), not from a worktree subdirectory:

```bash
cd "$REPO_ROOT"
gh pr merge $BRANCH \
  --squash \
  --delete-branch \
  --subject "$MSG"
```

`--delete-branch` removes the **remote** feature branch automatically.
Wait for the merge to complete — confirm with:

```bash
gh pr view $BRANCH --json state --jq '.state'
# Expected: "MERGED"
```

---

### Steps 8 & 9 — Cleanup and sync DEV

All cleanup runs from `$REPO_ROOT`. `gh pr merge --squash` may have already switched
the local working tree to `dev` and deleted the local feature branch; both operations
must be **conditional** to avoid errors:

```bash
cd "$REPO_ROOT"

# Switch to dev only if not already there
CURRENT=$(git branch --show-current)
[ "$CURRENT" != "dev" ] && git checkout dev

# Delete local branch only if it still exists
git branch --list "$BRANCH" | grep -q . && git branch -d "$BRANCH"
```

If `-d` refuses with "not fully merged", use `-D` only after confirming the remote
PR state in Step 7 returned `"MERGED"`.

**Worktree cleanup** — if `$IN_WORKTREE` was `true` in Step 0, the worktree directory
must be removed. Run from `$REPO_ROOT`:

```bash
if [ "$IN_WORKTREE" = "true" ]; then
  # Prune stale worktree refs (handles the case where the directory is already gone)
  git worktree prune

  # Remove the physical directory if it still exists
  [ -d "$WORKTREE_PATH" ] && rm -rf "$WORKTREE_PATH" && echo "Worktree directory removed: $WORKTREE_PATH"
fi
```

**Sync dev:**

```bash
git pull origin dev
git log --oneline -5
```

---

## Quick Reference

```
0. Detect context (worktree? already committed?)  git rev-parse --show-toplevel; git branch; git rev-list
1. Ask for $BRANCH and $MSG (skip if already committed on feature branch)
2. Fetch + pull only if behind             git fetch origin && [check BEHIND count] && git stash / pull / pop
3. Stage all changes                        git add --all
4. Create feature branch + commit           git checkout -b $BRANCH && git commit
5. Push                                     git push -u origin $BRANCH
6. Open PR into DEV                         gh pr create --base dev
7. Merge PR (squash) from REPO_ROOT         cd $REPO_ROOT && gh pr merge --squash --delete-branch
8 & 9. Conditional cleanup + sync DEV       [if not on dev] checkout dev; [if branch exists] branch -d;
                                            [if worktree] git worktree prune && rm -rf $WORKTREE_PATH;
                                            git pull origin dev
```

---

## Error Recovery

| Situation | Recovery |
|---|---|
| Rebase conflict can't be resolved | `git rebase --abort` — stop and tell user |
| Push rejected (non-fast-forward) | `git pull --rebase origin $BRANCH` then retry push |
| PR merge fails (status checks) | Show failure reason with `gh pr checks $BRANCH` — do not force merge |
| `gh` not authenticated | `gh auth login` — pause workflow until authenticated |
| Feature branch already exists | Use **AskUserQuestion**: options "Reuse existing branch" / "Choose a different name" — if "different name", loop back to Step 1 |
| `fatal: 'dev' is already used by worktree` | `cd $REPO_ROOT` before running `gh pr merge` — never merge from inside a secondary worktree |
| `cannot delete branch '…' used by worktree` | Remove the worktree first: `git worktree prune && rm -rf $WORKTREE_PATH`, then `git branch -d $BRANCH` |
| PR already merged (second `gh pr merge` attempt) | Verify with `gh pr view $BRANCH --json state --jq '.state'`; if `"MERGED"`, skip to cleanup |
