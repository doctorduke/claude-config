# Detailed Git Examples

## Table of Contents

1. [Complex Interactive Rebase](#complex-interactive-rebase)
2. [Bisect Debugging Session](#bisect-debugging-session)
3. [Resolving Complex Merge Conflicts](#resolving-complex-merge-conflicts)
4. [Recovering Lost Work](#recovering-lost-work)
5. [Repository History Surgery](#repository-history-surgery)
6. [Parallel Development with Worktrees](#parallel-development-with-worktrees)
7. [Feature Branch Workflow](#feature-branch-workflow)
8. [Release Management](#release-management)
9. [Hotfix Management](#hotfix-management)
10. [Post-Deployment Issue Recovery](#post-deployment-issue-recovery)

## Complex Interactive Rebase

### Scenario: Clean Up 10 Commits Before PR

You've been working on a feature branch with many commits. Before creating a PR, you want to:

1. Reorder commits logically
2. Squash related work
3. Fix a commit message
4. Remove debug commits

**Initial commits:**

```
abc123 Add database schema
def456 Fix schema typo
ghi789 Add migration
jkl012 WIP: debug output
mno345 Add indexes
pqr678 Fix index definition
stu901 Add tests
vwx234 Fix test typo
yza345 Update docs
bcd456 Fix doc formatting
```

**Rebase command:**

```bash
git rebase -i HEAD~10
```

**Editor shows:**

```bash
pick abc123 Add database schema
squash def456 Fix schema typo
pick ghi789 Add migration
drop jkl012 WIP: debug output
pick mno345 Add indexes
squash pqr678 Fix index definition
pick stu901 Add tests
fixup vwx234 Fix test typo
reword yza345 Update docs
fixup bcd456 Fix doc formatting
```

**After save, Git starts rebase:**

1. **abc123 + def456** - Prompts to edit combined message
   ```
   Add database schema

   Fixed typo in schema definition
   ```

2. **ghi789** - No prompt (simple pick)

3. **mno345 + pqr678** - Prompts to edit combined message
   ```
   Add indexes to frequently queried columns

   Fixed index definition
   ```

4. **stu901 + vwx234** - No prompt (fixup auto-discards message)

5. **yza345 + bcd456** - Prompts to edit (reword), fixup applied
   ```
   Update documentation with schema details
   ```

**Result:**

```
abc123 Add database schema
def456 Add migration
ghi789 Add indexes to frequently queried columns
jkl012 Add tests
klm345 Update documentation with schema details
```

## Bisect Debugging Session

### Scenario: Find Regression Introduced After v2.5.0

Your test suite fails on main but passed on v2.5.0. You need to find which commit introduced the regression.

```bash
# Start bisect
git bisect start

# Mark current as bad
git bisect bad

# Mark last release as good
git bisect good v2.5.0

# Git checks out a commit in the middle
# Current: 10 revisions to test (binary search)
```

**Manual testing:**

```bash
# Test 1: Git checked out commit xyz123
npm test
# FAIL - this is bad
git bisect bad

# Current: 5 revisions to test
# Git checks out commit abc456

# Test 2
npm test
# PASS - this is good
git bisect good

# Current: 2 revisions to test
# Git checks out commit def789

# Test 3
npm test
# PASS - this is good
git bisect good

# Bisect complete: ghi012 is the first bad commit
# That's the commit we're looking for!

# View the culprit commit
git show ghi012
```

**With automated script:**

```bash
# Create test script
cat > test-script.sh << 'EOF'
#!/bin/bash
# Exit 0 = good, 1 = bad, 125 = skip this commit
npm test --silent
exit $?
EOF

chmod +x test-script.sh

# Run bisect with script
git bisect start HEAD v2.5.0
git bisect run ./test-script.sh

# Git automatically finds the culprit
```

## Resolving Complex Merge Conflicts

### Scenario: Merge Feature Branch with Multiple Conflicts

```bash
# Feature branch has 3 commits from different authors
# main has commits that conflict with feature branch
git merge feature/complex-feature

# Conflicts in: config.json, app.js, database.js

# Check conflict status
git status
```

**Manual conflict resolution:**

```bash
# View conflict in app.js
cat app.js

# See all three versions
git show :1:app.js   # Common ancestor
git show :2:app.js   # Current (main)
git show :3:app.js   # Incoming (feature)

# Decide: use mergetool for interactive resolution
git mergetool app.js

# For config.json, merge manually
# Edit config.json, resolve by hand

# For database.js, keep our version
git checkout --ours database.js

# Stage resolved files
git add app.js config.json database.js

# Complete merge
git merge --continue
```

**If merge goes wrong:**

```bash
# Abort and start over
git merge --abort

# Try with different strategy
git merge -X theirs feature/complex-feature
# (This prefers their changes in conflicts)

# Or rebase instead
git rebase feature/complex-feature
```

## Recovering Lost Work

### Scenario: Accidentally Did `git reset --hard HEAD~5`

You realized those 5 commits were important.

```bash
# View reflog
git reflog

# Output:
# abc123 HEAD@{0}: reset: moving to HEAD~5
# def456 HEAD@{1}: commit: Add tests
# ghi789 HEAD@{2}: commit: Fix bug in parser
# jkl012 HEAD@{3}: commit: Add configuration
# mno345 HEAD@{4}: commit: Update dependencies
# pqr678 HEAD@{5}: commit: Add new feature

# The commits before the reset are at HEAD@{1}..HEAD@{5}
# These are the commits we want: def456 through pqr678

# Option 1: Reset to pre-reset state
git reset --hard HEAD@{5}

# Option 2: Create new branch from lost commits
git branch recovery-branch HEAD@{1}

# Option 3: Cherry-pick specific commits
git cherry-pick def456..pqr678

# Verify recovery
git log --oneline -10
```

## Repository History Surgery

### Scenario: Extract Subdirectory as New Repository

You want to split `libs/auth` into a separate repository while preserving its history.

```bash
# Clone fresh copy
git clone <original-repo> temp-repo
cd temp-repo

# Keep only libs/auth directory, remove everything else
git filter-repo --path libs/auth --force

# Now the repository contains only the auth library's history

# Create new remote and push
git remote add origin <new-repo-url>
git push -u origin main

# Back in original repo, remove the extracted directory
cd <original-repo>
git filter-repo --path libs/auth --invert-paths --force

# Remove the old directory
git rm -r libs/auth
git commit -m "Remove auth library (moved to separate repo)"
```

### Scenario: Rewrite All Commits with New Author

All commits show wrong author, need to fix across entire history.

```bash
# Rewrite all commits with different author
git filter-repo --mailmap-file <(echo "New Author <new@email.com> <old@email.com>")

# Or for all commits
git filter-repo --name-callback 'return b"New Author"'
git filter-repo --email-callback 'return b"new@email.com"'

# Force push
git push --force --all
```

## Parallel Development with Worktrees

### Scenario: Work on Feature While Reviewing PR

Main worktree is on `main` branch, but you need to:

1. Keep working on current feature
2. Switch to a PR branch for review
3. Go back to feature work

```bash
# Create second worktree for PR review
git worktree add ../review-pr-123 pr/feature-request

# Now you have two directories:
# ./project/           <- main worktree on current branch
# ./review-pr-123/     <- separate worktree on pr/feature-request

# In main worktree, continue your work
cd ../project
git add . && git commit -m "Feature: add caching"

# In review worktree, review code
cd ../review-pr-123
cat README.md  # Read documentation
npm test       # Run tests
npm start      # Try it locally

# Go back to main work
cd ../project

# When PR review is done
cd ../review-pr-123
git worktree remove ../review-pr-123
```

## Feature Branch Workflow

### Scenario: Complete Feature Development Lifecycle

```bash
# 1. Create feature branch from latest main
git checkout main
git pull
git checkout -b feat/user-authentication

# 2. Make changes (multiple commits)
git add .
git commit -m "feat: add login form component"

git add .
git commit -m "feat: add authentication API client"

git add .
git commit -m "test: add authentication tests"

# 3. Rebase on latest main to catch up
git fetch origin
git rebase origin/main

# If conflicts occur, resolve them
git add <resolved-files>
git rebase --continue

# 4. Push to remote
git push -u origin feat/user-authentication

# 5. Create PR (on GitHub)

# 6. After review, make requested changes
git add .
git commit -m "fix: address code review feedback"

# 7. Squash commits for clean history (optional)
git rebase -i origin/main
# mark commits as 'squash' to combine them

# 8. Force push updated branch
git push --force-with-lease

# 9. After approval and merge, clean up
git checkout main
git pull
git branch -d feat/user-authentication
git push origin --delete feat/user-authentication
```

## Release Management

### Scenario: Release v2.0.0

```bash
# 1. Create release branch
git checkout -b release/2.0.0 develop

# 2. Bump version
npm version minor  # Updates package.json, tags commit

# 3. Update changelog
# Edit CHANGELOG.md with new features

git add CHANGELOG.md
git commit -m "docs: update changelog for v2.0.0"

# 4. Final testing
npm test
npm run build

# 5. Merge to main
git checkout main
git merge --no-ff release/2.0.0
git tag -a v2.0.0 -m "Release version 2.0.0"

# 6. Merge back to develop
git checkout develop
git merge --no-ff release/2.0.0

# 7. Push everything
git push origin main develop
git push origin v2.0.0

# 8. Delete release branch
git branch -d release/2.0.0
git push origin --delete release/2.0.0

# 9. Create release on GitHub
# Use v2.0.0 tag and add release notes
```

## Hotfix Management

### Scenario: Security Fix Needed in Production

```bash
# 1. Branch from main (production)
git checkout -b hotfix/security-fix main

# 2. Make fix
# Edit vulnerable code
git add .
git commit -m "fix: patch security vulnerability"

# 3. Test thoroughly
npm test
npm run security-audit

# 4. Bump patch version
npm version patch

# 5. Merge to main
git checkout main
git merge --no-ff hotfix/security-fix
git tag -a v1.0.1 -m "Security hotfix 1.0.1"

# 6. Merge to develop
git checkout develop
git merge --no-ff hotfix/security-fix

# 7. Push
git push origin main develop
git push origin v1.0.1

# 8. Deploy
# Trigger deployment from main

# 9. Cleanup
git branch -d hotfix/security-fix
git push origin --delete hotfix/security-fix
```

## Post-Deployment Issue Recovery

### Scenario: Wrong Commit Deployed to Production

Production is running the wrong commit. Need to:

1. Identify what's deployed
2. Find the correct commit
3. Revert to correct state

```bash
# 1. Check what's currently deployed
# Get deployed version from production logs
# E.g., v1.5.3 with commit abc123

# 2. Check local git status
git log --oneline | head -20

# 3. Identify bad commit
# Suppose commit def456 is deployed but shouldn't be

# 4. Revert the bad commit
git revert def456
git push

# 5. Deploy reverted version
# Trigger deployment from main

# 6. Alternative: reset to good commit
git reset --hard abc123  # Last known good
git push --force-with-lease

# 7. Document incident
# Add incident notes to git log or issue tracker
```

## Advanced: Combining Multiple Patterns

### Scenario: Recover Lost Commits, Rebase, Clean Up, Release

After an accidental force push that deleted commits, you:

1. Recover the lost commits from reflog
2. Rebase them onto current main
3. Clean up duplicate commits
4. Create a new release

```bash
# 1. Check reflog for lost commits
git reflog
# Find lost commits in output

# 2. Create recovery branch
git checkout -b recover-lost-commits abc123

# 3. Rebase on current main
git rebase main

# 4. Fix conflicts and duplicate commits
git rebase -i origin/main
# Remove duplicate commits, fix conflicts

# 5. Review result
git log --oneline origin/main..HEAD

# 6. Merge to main
git checkout main
git merge --no-ff recover-lost-commits

# 7. Tag and release
git tag -a v1.5.4 -m "Recovery release"
git push origin main
git push origin v1.5.4

# 8. Cleanup
git branch -d recover-lost-commits
```
