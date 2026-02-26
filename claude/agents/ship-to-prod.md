# Ship to Production

**Purpose**: Create a pull request to merge `uat` branch into `main` (production) after successful UAT testing.

⚠️ **CRITICAL**: This deploys to production. Extra safety checks required.

## Instructions

When this skill is invoked, perform the following steps:

### 1. Pre-Flight Safety Checks

```bash
# Ensure we're working from the uat branch
git checkout uat
git pull origin uat

# Verify uat is ahead of main
git fetch origin main:main
git log main..uat --oneline --max-count=10

# Check if there are any uncommitted changes
git status --short

# Verify UAT testing is complete (prompt user)
```

**STOP and confirm with user:**
- ✅ Has UAT testing been completed and approved?
- ✅ Are all critical bugs resolved?
- ✅ Have stakeholders signed off on the release?
- ✅ Is the deployment window scheduled and communicated?
- ✅ Is the rollback plan documented and tested?

If ANY answer is "No", ABORT the process.

### 2. Gather Release Information

Collect comprehensive information:
- Get the list of commits since last production deployment
- Identify all PRs merged to uat since last production release
- Document breaking changes and migration requirements
- List new features, bug fixes, and improvements
- Note any performance impacts or infrastructure changes

### 3. Create Production Release PR

Create a pull request with the following details:

**Base branch**: `main`
**Head branch**: `uat`
**Title format**: `release: Production Deployment vX.Y.Z - YYYY-MM-DD`

**PR Body Template**:
```markdown
## 🚀 Production Release vX.Y.Z - [DATE]

This PR deploys the tested `uat` branch to production (`main`).

---

## ✅ UAT Sign-Off

- [x] UAT testing completed
- [x] All critical bugs resolved
- [x] Stakeholder approval received
- [x] Deployment window: [DATE/TIME]
- [x] On-call engineer assigned: [NAME]

---

## 📋 Changes Included

### New Features
[List new features from commit history]

### Bug Fixes
[List bug fixes from commit history]

### Improvements
[List improvements from commit history]

### Full Changelog
[List of all PRs merged to uat since last production deployment]

---

## ⚠️ Breaking Changes

[List any breaking changes, or state "None"]

**Impact Assessment:**
[Describe impact on existing users/systems]

**Migration Path:**
[Describe how to migrate from previous version]

---

## 🗄️ Database Migrations

[List any required migrations, or state "None"]

**Migration Commands:**
```bash
# Commands to run migrations
docker compose -p neurorep_v3 exec nr_metadata_service sh -c "cd /app/nr_metadata_service && alembic upgrade head"
```

**Estimated Downtime:** [X minutes, or "Zero-downtime"]

**Rollback Steps:**
```bash
# Commands to rollback migrations if needed
docker compose -p neurorep_v3 exec nr_metadata_service sh -c "cd /app/nr_metadata_service && alembic downgrade -1"
```

---

## ⚙️ Configuration Changes

[List any new environment variables or config changes, or state "None"]

### New Environment Variables
```env
# Add to .env or docker-compose.yml
NEW_VAR_NAME=default_value
```

### Modified Configuration
[List any changes to existing config]

---

## 📊 Performance Impact

[Describe expected performance impact]
- Database query performance: [Impact]
- API response times: [Impact]
- Memory usage: [Impact]
- CPU usage: [Impact]

---

## 🔍 Pre-Deployment Checklist

- [ ] All CI checks passing on uat
- [ ] UAT testing completed and signed off
- [ ] Database migrations reviewed and tested
- [ ] Database backups verified (< 24 hours old)
- [ ] Environment variables documented and ready
- [ ] Rollback plan documented and tested
- [ ] Monitoring alerts configured
- [ ] On-call engineer assigned and notified
- [ ] Deployment window communicated to stakeholders
- [ ] Post-deployment verification plan ready

---

## 🚀 Deployment Steps

### Pre-Deployment
1. **Backup Database** (< 1 hour before deployment)
   ```bash
   # Create database backup
   docker compose -p neurorep_v3 exec nr_postgres pg_dump -U postgres neurorep > backup_$(date +%Y%m%d_%H%M%S).sql
   ```

2. **Verify Services Healthy**
   ```bash
   docker compose -p neurorep_v3 ps
   curl http://localhost:8000/health
   curl http://localhost:8001/health
   ```

### Deployment
3. **Merge this PR to main**
4. **Pull main branch in production**
   ```bash
   git checkout main
   git pull origin main
   ```

5. **Run Database Migrations** (if any)
   ```bash
   docker compose -p neurorep_v3 exec nr_metadata_service sh -c "cd /app/nr_metadata_service && alembic upgrade head"
   ```

6. **Update Environment Variables** (if any)
   - Edit `.env` or `docker-compose.yml`
   - Add new variables
   - Update modified variables

7. **Rebuild and Restart Services**
   ```bash
   docker compose -p neurorep_v3 build
   docker compose -p neurorep_v3 up -d
   ```

8. **Wait for Services to Start** (2-5 minutes)
   ```bash
   docker compose -p neurorep_v3 logs -f
   ```

### Post-Deployment Verification
9. **Health Checks**
   ```bash
   curl http://localhost:8000/health
   curl http://localhost:8001/health
   curl http://localhost:3001  # Verify WebUI loads
   ```

10. **Smoke Tests**
    - [ ] User can log in
    - [ ] Workflows can be created
    - [ ] Incident detection is working
    - [ ] Analytics dashboard loads
    - [ ] Notifications are being sent

11. **Monitor for Errors**
    ```bash
    docker compose -p neurorep_v3 logs --tail=100 -f
    ```

12. **Verify Key Metrics**
    - API response times < 500ms
    - Database connections stable
    - No error spikes in logs
    - Memory/CPU usage normal

---

## 🔄 Rollback Plan

**IF CRITICAL ISSUES DISCOVERED:**

### Immediate Rollback (< 15 minutes)
1. **Revert Merge Commit**
   ```bash
   git checkout main
   git revert -m 1 <merge-commit-sha>
   git push origin main
   ```

2. **Rollback Database Migrations**
   ```bash
   docker compose -p neurorep_v3 exec nr_metadata_service sh -c "cd /app/nr_metadata_service && alembic downgrade <previous-version>"
   ```

3. **Restore Previous Environment Variables**
   - Revert `.env` or `docker-compose.yml` changes

4. **Rebuild and Restart Services**
   ```bash
   docker compose -p neurorep_v3 build
   docker compose -p neurorep_v3 up -d
   ```

5. **Verify Rollback Successful**
   ```bash
   curl http://localhost:8000/health
   docker compose -p neurorep_v3 logs --tail=50
   ```

### Database Restore (Last Resort)
```bash
# Restore from backup
docker compose -p neurorep_v3 exec -T nr_postgres psql -U postgres neurorep < backup_YYYYMMDD_HHMMSS.sql
```

---

## 📞 Communication Plan

### Before Deployment
- [ ] Email stakeholders: "Production deployment starting at [TIME]"
- [ ] Update status page: "Scheduled maintenance [TIME]-[TIME]"
- [ ] Notify on-call engineer

### During Deployment
- [ ] Status updates every 15 minutes
- [ ] Report any issues immediately

### After Deployment
- [ ] Email stakeholders: "Deployment complete and verified"
- [ ] Update status page: "All systems operational"
- [ ] Post-deployment summary in Slack/Teams

---

## 📝 Post-Deployment Tasks

- [ ] Monitor error rates for 1 hour
- [ ] Monitor performance metrics for 24 hours
- [ ] Create release notes for users
- [ ] Update CHANGELOG.md
- [ ] Tag release in GitHub
- [ ] Archive deployment runbook
- [ ] Conduct post-mortem (if issues occurred)

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)

**Production Deployment - Handle with Care** 🚀
```

### 4. Command to Execute

```bash
# CRITICAL: Confirm with user first
echo "⚠️  PRODUCTION DEPLOYMENT ⚠️"
echo "This will create a PR to deploy UAT to PRODUCTION."
echo ""
echo "Pre-flight checks:"
echo "1. Has UAT testing been completed and approved?"
echo "2. Are all critical bugs resolved?"
echo "3. Have stakeholders signed off?"
echo "4. Is the deployment window scheduled?"
echo "5. Is the rollback plan ready?"
echo ""
read -p "Proceed? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Production deployment cancelled."
    exit 1
fi

# Ensure on uat
git checkout uat
git pull origin uat

# Get version number from user
read -p "Enter version number (e.g., 1.2.3): " version

# Get commit log for PR body
git log main..uat --oneline --pretty=format:"- %s (%h)" --max-count=50 > /tmp/prod-changes.txt

# Create the PR
gh pr create \
  --base main \
  --head uat \
  --title "release: Production Deployment v${version} - $(date +%Y-%m-%d)" \
  --body "[Generated comprehensive deployment plan]"
```

### 5. After PR Creation

- Display the PR URL with **CRITICAL WARNING**
- Remind user to:
  - **DO NOT MERGE without final approval**
  - Review ALL changes carefully
  - Verify all pre-deployment checklist items
  - Schedule deployment window
  - Assign on-call engineer
  - Create database backup before merge
  - Test rollback plan before deployment

## Critical Safety Checks

- ✅ Require explicit user confirmation before proceeding
- ✅ Never auto-merge production PRs
- ✅ Ensure database backup exists and is recent
- ✅ Verify UAT testing is complete
- ✅ Document rollback plan comprehensively
- ✅ Include post-deployment verification steps
- ✅ Assign on-call engineer for monitoring

## Example Usage

```bash
/ship-to-prod
```

This will:
1. **STOP** and ask for confirmation
2. Verify UAT testing is complete
3. Switch to `uat` branch
4. Pull latest changes
5. Prompt for version number
6. Generate comprehensive changelog
7. Create PR to `main` with full deployment runbook
8. **WAIT for manual review and approval**
9. Display PR URL with critical warnings

## Post-Merge Reminders

After merging to production:
```bash
# Tag the release
git checkout main
git pull origin main
git tag -a v${version} -m "Production release v${version}"
git push origin v${version}

# Update CHANGELOG.md
# Monitor production for 1-24 hours
# Send deployment summary email
```
