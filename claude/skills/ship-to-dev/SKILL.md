---
name: ship-to-dev
description: Use when the user wants to ship current working changes through a feature branch PR into the DEV branch — covers pulling latest, staging, committing, pushing, PR creation, merge, branch cleanup, and syncing DEV locally.
---

# Ship to DEV

Automates the full feature-branch → DEV merge workflow for this repository.
Run this whenever you have uncommitted work ready to integrate into DEV.

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

```bash
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

`gh pr merge --squash` switches the local working tree to `dev` and deletes the local feature branch as a side-effect of the merge. Both operations must therefore be **conditional** to avoid errors when they've already occurred:

```bash
# Switch to dev only if not already there
CURRENT=$(git branch --show-current)
[ "$CURRENT" != "dev" ] && git checkout dev

# Delete local branch only if it still exists
git branch --list "$BRANCH" | grep -q . && git branch -d "$BRANCH"

# Pull to ensure dev is up to date
git pull origin dev

git log --oneline -5
```

If `-d` refuses with "not fully merged", use `-D` only after confirming the remote PR state in Step 7 returned `"MERGED"`.

---

## Quick Reference

```
1. Ensure DEV exists on remote (create from main if missing)
2. Fetch + pull only if behind             git fetch origin && [check BEHIND count] && git stash / pull / pop
3. Stage all changes                        git add --all
4. Create feature branch + commit           git checkout -b $BRANCH && git commit
5. Push                                     git push -u origin $BRANCH
6. Open PR into DEV                         gh pr create --base dev
7. Merge PR (squash) + delete remote        gh pr merge --squash --delete-branch
8 & 9. Conditional cleanup + sync DEV       [if not on dev] checkout dev; [if branch exists] branch -d; git pull
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
