---
name: release-to-main
description: Use when the user wants to merge dev into main for a production release — covers rebasing dev from main if behind, automatic semantic versioning from conventional commits, merge commit, release tagging, and syncing dev back onto main.
---

# Release to Main

Promotes `dev` → `main` as a versioned production release.
Run this when `dev` is stable and ready to ship.

---

## Prerequisites: Ensure Both Branches Exist on Remote

```bash
git ls-remote --heads origin main
git ls-remote --heads origin dev
```

If either is missing, stop and tell the user — do not create them automatically.

---

## Workflow

Follow every step in order. Do not skip steps, do not reorder them.

### Step 1 — Fetch and assess state

```bash
git fetch origin
```

Capture two counts:

```bash
# How many commits main has that dev does not (dev is behind main)
BEHIND=$(git rev-list origin/dev..origin/main --count)

# How many commits dev has that main does not (the release payload)
AHEAD=$(git rev-list origin/main..origin/dev --count)

echo "dev is $BEHIND behind main, $AHEAD ahead of main"
```

- If `$AHEAD` is 0 — there is nothing to release. Stop and tell the user.
- If `$BEHIND` > 0 — dev must be rebased onto main before the merge (Step 2).
- If `$BEHIND` is 0 — skip Step 2 and go straight to Step 3.

---

### Step 2 — Rebase dev onto main (only if dev is behind)

Switch to dev and stash any uncommitted local work first:

```bash
git checkout dev

# Stash everything including untracked files
git stash --include-untracked

# Rebase dev onto the latest main
git rebase origin/main
```

If rebase produces conflicts:
1. Show conflicting files with `git status`.
2. Resolve obvious ones yourself. For non-obvious conflicts, use **AskUserQuestion**:
   ```
   AskUserQuestion(
     questions: [{
       question: "Rebase conflict in <files>. How would you like to proceed?",
       header: "Conflicts",
       options: [
         { label: "I'll resolve manually", description: "Pause — you fix the files, then tell me to continue" },
         { label: "Abort the rebase", description: "Run git rebase --abort and stop the workflow" }
       ]
     }]
   )
   ```
3. After resolution: `git add <resolved-files>` then `git rebase --continue`.
4. If unresolvable: `git rebase --abort` — stop and report to user.

After a clean rebase, restore stashed work and force-push dev:

```bash
git stash pop   # only if stash was created
git push --force-with-lease origin dev
```

---

### Step 3 — Determine the next version (automatic)

Get the most recent tag:

```bash
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
echo "Last release: $LAST_TAG"
```

Parse MAJOR, MINOR, PATCH from `$LAST_TAG` (strip leading `v`). Then scan commit subjects since that tag to determine the bump type:

```bash
git log "$LAST_TAG"..origin/dev --format="%s"
```

Apply conventional commit rules (in priority order):

| Pattern in any commit subject or body | Bump |
|---------------------------------------|------|
| `BREAKING CHANGE` in body, or `!:` in subject (e.g. `feat!:`) | **major** |
| Subject starts with `feat:` or `feat(` | **minor** |
| Anything else (`fix:`, `chore:`, `refactor:`, `docs:`, etc.) | **patch** |

Compute the three candidate versions (new_patch, new_minor, new_major) and present them via **AskUserQuestion**, pre-selecting the auto-detected bump:

```
AskUserQuestion(
  questions: [{
    question: "What version should this release be tagged as?",
    header: "Version",
    options: [
      { label: "vX.Y.Z+1", description: "Patch bump (auto-detected from commits) (Recommended)" },
      { label: "vX.Y+1.0", description: "Minor bump" },
      { label: "vX+1.0.0", description: "Major bump" }
    ]
  }]
)
```

Store the chosen version as `$VERSION`.

---

### Step 4 — Confirm the release

Show a summary panel to the user, then ask for confirmation via **AskUserQuestion**:

```
Release summary:
  From branch  : dev
  Into branch  : main
  Last release : $LAST_TAG
  New version  : $VERSION
  Commits      : $AHEAD commits

AskUserQuestion(
  questions: [{
    question: "Merge dev into main as $VERSION?",
    header: "Confirm",
    options: [
      { label: "Yes — ship it", description: "Proceed with merge, tag, and dev sync" },
      { label: "No — abort", description: "Stop the workflow without making any changes" }
    ]
  }]
)
```

If the user aborts, stop cleanly with no git changes made.

---

### Step 5 — Merge dev into main

```bash
git checkout main
```

Before pulling or merging, check whether local `main` has diverged from `origin/main`:

```bash
LOCAL_AHEAD=$(git rev-list origin/main..HEAD --count)
LOCAL_BEHIND=$(git rev-list HEAD..origin/main --count)
echo "local main is $LOCAL_AHEAD ahead, $LOCAL_BEHIND behind origin/main"
```

Act on the result:

| State | Action |
|-------|--------|
| `LOCAL_AHEAD=0, LOCAL_BEHIND=0` | In sync — proceed |
| `LOCAL_AHEAD=0, LOCAL_BEHIND>0` | Pull only: `git pull origin main` |
| `LOCAL_AHEAD>0, LOCAL_BEHIND=0` | Local main has unpushed commits — use **AskUserQuestion** (see below) |
| Both > 0 (diverged) | **STOP** — local and remote main have diverged; do not merge. Report to user and abort |

**When local main is ahead of origin/main**, use **AskUserQuestion**:

```
AskUserQuestion(
  questions: [{
    question: "Local main has $LOCAL_AHEAD commit(s) not on origin/main:\n<git log --oneline origin/main..HEAD>\nHow should these be handled?",
    header: "Local commits",
    options: [
      { label: "Push them to origin/main first", description: "Publish the local commits, then continue the release merge" },
      { label: "Abort — I need to review these commits", description: "Stop the workflow without making any changes" }
    ]
  }]
)
```

- If **Push first**: `git push origin main`, then continue.
- If **Abort**: stop cleanly.

Once local and remote main are in sync, perform the merge:

```bash
git merge --no-ff origin/dev -m "release: $VERSION"
git push origin main
```

`--no-ff` creates a merge commit that preserves the full dev history on main.

---

### Step 6 — Tag and publish the release

```bash
git tag "$VERSION"
git push origin "$VERSION"
```

Confirm the tag is visible:

```bash
git tag --list "$VERSION"
```

Then **publish a GitHub Release** from the tag. This is required for any repo using
`/releases/latest` API (e.g. install.ps1 remote installers). A bare git tag is NOT
sufficient — the API returns 404 until a Release is published.

Summarise commits since the previous tag to generate release notes:

```bash
PREV_TAG=$(git describe --tags --abbrev=0 "$VERSION^" 2>/dev/null || echo "")
NOTES=$(git log "${PREV_TAG:+$PREV_TAG..}$VERSION" --format="- %s" 2>/dev/null)
```

Create the release:

```bash
gh release create "$VERSION" \
  --title "$VERSION" \
  --notes "$NOTES"
```

Confirm:

```bash
gh release view "$VERSION" --json tagName,publishedAt --jq '"Released: \(.tagName) at \(.publishedAt)"'
```

---

### Step 7 — Sync dev from main and push

After the merge, main has a new merge commit that dev does not. Bring dev forward so it includes that commit and the two branches stay in sync:

```bash
git checkout dev
git rebase origin/main   # replays dev's commits on top of main's new HEAD
git push --force-with-lease origin dev
```

Because dev was just merged into main, this rebase is typically a fast-forward and produces no conflicts.

If rebase conflicts arise here (rare — just merged), use the same **AskUserQuestion** conflict pattern from Step 2.

---

### Step 8 — Show final state

```bash
git log --oneline -5 origin/main
echo "---"
git log --oneline -3 origin/dev
```

Report: PR complete, version tagged, dev synced.

---

## Quick Reference

```
1. Ensure main and dev exist on remote
2. git fetch origin — check BEHIND / AHEAD counts
3. [if BEHIND > 0] Rebase dev onto main + force-push dev
4. Determine next version from conventional commits
5. Confirm release with user (AskUserQuestion)
6. git merge --no-ff origin/dev -m "release: $VERSION" → push main
7. git tag $VERSION → push tag
8. Rebase dev onto main + force-push dev
9. Show final log
```

---

## Error Recovery

| Situation | Recovery |
|---|---|
| `$AHEAD` is 0 | Nothing to release — stop and tell user |
| Rebase conflict (Step 2 or 7) | Use AskUserQuestion: resolve manually or abort |
| Local main ahead of origin/main | Use **AskUserQuestion**: push local commits first, or abort |
| Local main diverged from origin/main | **STOP** — do not merge; report to user and abort |
| Push to main rejected | `git pull --rebase origin main` then retry — never force-push main |
| Tag already exists | Use **AskUserQuestion**: pick a different version or abort |
| `gh` not authenticated | `gh auth login` — pause until authenticated |
| dev ahead count wrong after rebase | Re-run `git fetch origin` and recount before proceeding |
