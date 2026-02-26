# Ship to UAT

**Purpose**: Create a pull request to merge `dev` branch into `uat` branch for User Acceptance Testing.

## Instructions

When this skill is invoked, perform the following steps:

### 1. Verify Current State

```bash
# Ensure we're working from the dev branch
git checkout dev
git pull origin dev

# Verify dev is ahead of uat
git fetch origin uat:uat
git log uat..dev --oneline --max-count=10
```

### 2. Gather Release Information

Collect information about the changes being shipped:
- Get the list of commits since last UAT merge
- Identify PRs merged to dev since last UAT deployment
- Note any breaking changes or migration requirements

### 3. Create PR to UAT

Create a pull request with the following details:

**Base branch**: `uat`
**Head branch**: `dev`
**Title format**: `release: Deploy to UAT - YYYY-MM-DD`

**PR Body Template**:
```markdown
## UAT Deployment - [DATE]

This PR merges all changes from `dev` into `uat` for User Acceptance Testing.

---

## Changes Included

[List of PRs merged to dev since last UAT deployment]

### Breaking Changes
[List any breaking changes, or state "None"]

### Database Migrations
[List any required migrations, or state "None"]

### Configuration Changes
[List any new environment variables or config changes, or state "None"]

---

## Pre-Deployment Checklist

- [ ] All CI checks passing on dev
- [ ] Database migrations reviewed
- [ ] Environment variables documented
- [ ] Rollback plan documented (if needed)

## UAT Testing Plan

[Brief description of what should be tested in UAT]

---

## Deployment Steps

1. Merge this PR to `uat`
2. Deploy `uat` branch to UAT environment
3. Run database migrations (if any)
4. Update environment variables (if any)
5. Verify deployment health checks
6. Begin UAT testing

## Rollback Plan

If issues are discovered:
1. Revert this merge commit on `uat`
2. Redeploy previous `uat` version
3. Create hotfix branch from `uat` if needed

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

### 4. Command to Execute

```bash
# Ensure on dev
git checkout dev
git pull origin dev

# Get commit log for PR body
git log uat..dev --oneline --pretty=format:"- %s (%h)" --max-count=20 > /tmp/uat-changes.txt

# Create the PR
gh pr create \
  --base uat \
  --head dev \
  --title "release: Deploy to UAT - $(date +%Y-%m-%d)" \
  --body "$(cat <<'EOF'
## UAT Deployment - $(date +%Y-%m-%d)

This PR merges all changes from dev into uat for User Acceptance Testing.

---

## Changes Included

$(cat /tmp/uat-changes.txt)

### Breaking Changes
[Auto-detect or prompt user]

### Database Migrations
[Auto-detect from alembic files or prompt user]

### Configuration Changes
[Auto-detect from docker-compose.yml changes or prompt user]

---

## Pre-Deployment Checklist

- [ ] All CI checks passing on dev
- [ ] Database migrations reviewed
- [ ] Environment variables documented
- [ ] Rollback plan documented (if needed)

## UAT Testing Plan

[Prompt user for testing focus areas]

---

## Deployment Steps

1. Merge this PR to uat
2. Deploy uat branch to UAT environment
3. Run database migrations (if any)
4. Update environment variables (if any)
5. Verify deployment health checks
6. Begin UAT testing

## Rollback Plan

If issues are discovered:
1. Revert this merge commit on uat
2. Redeploy previous uat version
3. Create hotfix branch from uat if needed

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

### 5. After PR Creation

- Display the PR URL
- Remind user to:
  - Review the changes
  - Verify CI checks pass
  - Coordinate with QA team for UAT testing
  - Merge to `uat` when ready

## Safety Checks

- ✅ Never create PRs targeting `main` directly
- ✅ Ensure `dev` branch is up to date
- ✅ Verify PR is targeting `uat` (not `main`)
- ✅ Include rollback plan in PR description

## Example Usage

```bash
/ship-to-uat
```

This will:
1. Switch to `dev` branch
2. Pull latest changes
3. Generate changelog from commits
4. Create PR to `uat` with comprehensive deployment information
5. Display PR URL for review
