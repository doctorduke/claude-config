# Common Git Gotchas & Recovery

## Table of Contents

1. [Detached HEAD](#detached-head)
2. [Force Push Dangers](#force-push-dangers)
3. [Merge vs Rebase](#merge-vs-rebase)
4. [Lost Commits](#lost-commits)
5. [Submodule Hell](#submodule-hell)
6. [Hooks Not Running](#hooks-not-running)
7. [Line Ending Issues](#line-ending-issues)
8. [Large File Bloat](#large-file-bloat)
9. [Merge Conflicts](#merge-conflicts)
10. [Committed to Wrong Branch](#committed-to-wrong-branch)
11. [Wrong Author](#wrong-author)
12. [Sensitive Data Pushed](#sensitive-data-pushed)
13. [Undo Last Push](#undo-last-push)

## Detached HEAD

### Symptoms

```
HEAD detached at abc123
```

You're on a specific commit rather than a branch.

### Why It Happens

- Checking out a commit directly: `git checkout abc123`
- Checking out a tag: `git checkout v1.0.0`
- Rebasing and pausing at an 'edit' step
- Checking out a remote-tracking branch

### The Danger

Commits made in detached HEAD state are not pointed to by any branch. If you checkout another branch, those commits become unreachable and will be garbage collected after 30 days.

### Recovery

```bash
# Save current work immediately
git branch recovery-branch

# Or if you already switched away, use reflog
git reflog
# Find the commit you want
git branch recovery-branch abc123
```

### Prevention

```bash
# Always create a branch when checking out specific commits
git checkout -b my-work-branch abc123

# Use 'git switch' which prevents accidental detached HEAD
git switch main                  # Safe
git switch --detach main         # Requires --detach flag
```

## Force Push Dangers

### The Problem

`git push --force` overwrites remote history, potentially destroying others' work:

```bash
# DANGEROUS - overwrites remote history
git push --force

# SAFE - only pushes if remote hasn't changed
git push --force-with-lease
```

### Why It Happens

- Rebasing local changes and needing to update remote
- Cleaning up commit history
- Squashing commits before merge

### The Right Way

```bash
# Always use --force-with-lease
git push --force-with-lease

# If someone else pushed in the meantime, it will fail
# This prevents accidentally overwriting their work
```

### If Disaster Strikes

```bash
# On remote, recover from reflog (if available)
# This is why CI/CD should have hooks to prevent force pushes to main

# Locally, warn team members
# They need to rebase on top of new history
```

## Merge vs Rebase

### The Choice

- **Merge**: Preserves complete history, creates merge commits
- **Rebase**: Creates linear history, rewrites commits (dangerous for public branches)

### The Rule

- **Merge**: Public/shared branches (main, develop)
- **Rebase**: Personal/feature branches only

### Why It Matters

```bash
# Merge - preserves history
A-B-C-main
     \
      D-E-feature
# After merge
A-B-C-M-main (M is merge commit)
     \ /
      D-E

# Rebase - rewrites history
A-B-C-main
     \
      D-E-feature
# After rebase to main
A-B-C-D'-E'-feature (D' and E' are new commits)
```

If you rebase a public branch, anyone with the old history must rebase too. This breaks their workflow.

### Common Mistake

```bash
# DON'T DO THIS
git checkout main
git rebase develop    # Rewrites main's history!

# DO THIS INSTEAD
git checkout develop
git rebase main       # Rebase your feature on latest main
git checkout main
git merge develop     # Fast-forward merge
```

## Lost Commits

### The Myth

Rebasing/resetting doesn't actually delete commits - they become unreachable.

### How to Recover

```bash
# View reflog (journal of HEAD movements)
git reflog

# Output:
# abc123 HEAD@{0}: reset: moving to HEAD~3
# def456 HEAD@{1}: commit: Add feature
# ghi789 HEAD@{2}: commit: Update docs

# Recover lost commit
git checkout def456
git branch recovery-branch       # Save it on a branch

# Or reset directly
git reset --hard def456
```

### Prevention

The reflog is your safety net. It keeps entries for 90 days by default.

```bash
# View reflog for specific branch
git reflog show feature-branch

# Configure reflog expiration (default is 90 days)
git config gc.reflogExpireUnreachable 90
```

## Submodule Hell

### Common Issues

1. Submodules don't auto-update with parent repo
2. You checkout parent without updating submodules
3. You push parent but forget to push submodule
4. Submodule points to unpushed commit on server

### Solutions

#### After Cloning

```bash
# Clone with submodules
git clone --recurse-submodules https://github.com/user/project.git

# Or if already cloned
git submodule update --init --recursive
```

#### After Switching Branches

```bash
# Parent branch requires different submodule state
git checkout another-branch
git submodule update              # Update to parent's required version
```

#### Updating Submodules

```bash
# Update to latest of each submodule's branch
git submodule update --remote

# Or specific submodule
cd libs/lib
git checkout main
git pull
cd ../..
git add libs/lib
git commit -m "Update lib submodule"
```

#### Removing Submodule (Complex!)

```bash
# Deinit
git submodule deinit -f libs/lib

# Remove from tracking
git rm -f libs/lib

# Clean up internal files
rm -rf .git/modules/libs/lib

# Commit removal
git commit -m "Remove lib submodule"
```

### The Gotcha

Submodules point to **specific commits**, not branches. A simple `git pull` in parent doesn't update submodules.

```bash
# This does NOT update submodules to latest
git pull

# You must explicitly update
git pull && git submodule update --remote
```

## Hooks Not Running

### Symptoms

Hook scripts aren't executing during git operations.

### Causes and Fixes

```bash
# Cause 1: Hooks not executable
chmod +x .git/hooks/pre-commit

# Cause 2: Shebang line missing or wrong
# First line must be: #!/bin/bash

# Cause 3: Hook returning non-zero exit code (intentional block)
# Check hook script - it might be preventing the operation

# Cause 4: Skipping hooks (your choice)
git commit --no-verify              # Skip pre-commit and commit-msg hooks
git push --no-verify                # Skip pre-push hooks
```

### Prevention

```bash
# Always include shebang
#!/bin/bash

# Always make executable
chmod +x .git/hooks/hook-name

# Test hook manually
./.git/hooks/pre-commit
echo $?                             # Should be 0 if passing
```

## Line Ending Issues

### The Problem

Windows uses CRLF (`\r\n`), Unix uses LF (`\n`). This creates false diffs:

```
git diff shows "file.txt changed" but content looks identical
```

### Configuration

```bash
# Set once globally
git config --global core.autocrlf true  # Windows
git config --global core.autocrlf input # Mac/Linux

# Or per-repo with .gitattributes
* text=auto
*.js text eol=lf
*.json text eol=lf
*.sh text eol=lf
```

### Recovery

```bash
# Normalize existing repo
git config core.safecrlf false
git add --renormalize .
git commit -m "Normalize line endings"
git config core.safecrlf true
```

## Large File Bloat

### The Problem

Accidentally committed large files (binaries, logs, datasets) bloat the repository permanently.

### Prevention

```bash
# Configure .gitignore to prevent large files
*.log
*.iso
*.zip
node_modules/
.DS_Store

# Use pre-commit hook to prevent large files
#!/bin/bash
MAX_SIZE=10485760  # 10MB
for file in $(git diff --cached --name-only); do
  size=$(git cat-file -s :0:"$file" 2>/dev/null)
  if [ "$size" -gt "$MAX_SIZE" ]; then
    echo "Error: $file is too large ($size bytes)"
    exit 1
  fi
done
```

### After the Fact

```bash
# Find largest files in history
git rev-list --objects --all |
  git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' |
  sed -n 's/^blob //p' |
  sort --numeric-sort --key=2 |
  tail -n 10

# Remove from history (DESTRUCTIVE!)
# This requires force push - coordinate with team
git filter-repo --path large-file.bin --invert-paths
git push --force --all

# Or use BFG Repo Cleaner (faster)
bfg --delete-files "*.log" --strip-blobs-bigger-than 10M
bfg --strip-blobs-bigger-than 10M
git push --force --all
```

## Merge Conflicts

### Understanding Conflict Markers

```
Our version
Their version
```

### Viewing All Three Versions

```bash
# Common ancestor version (merge base)
git show :1:file.txt

# Our version (HEAD)
git show :2:file.txt

# Their version (incoming)
git show :3:file.txt
```

### Resolution Strategies

```bash
# Use merge tool (interactive)
git mergetool

# Accept one side entirely
git checkout --ours file.txt     # Keep our version
git checkout --theirs file.txt   # Keep their version

# Manual resolution
# Edit file, remove markers
git add file.txt
git rebase --continue    # If rebasing
git merge --continue     # If merging
```

### Prevention with Rerere

```bash
# Enable rerere (reuse recorded resolution)
git config --global rerere.enabled true

# Git remembers how you resolved conflicts
# Auto-applies same resolution in future
```

## Committed to Wrong Branch

### Symptoms

Realized you made commits to main when you meant to use feature branch.

### Recovery

```bash
# Create branch from current location (keeps commits)
git branch feature-branch

# Move current branch back
git reset --hard HEAD~3          # Move back 3 commits

# Verify feature branch has commits
git log feature-branch

# Switch to feature branch
git checkout feature-branch
```

## Wrong Author

### Fix Last Commit

```bash
git commit --amend --author="Name <email@example.com>"
```

### Fix Old Commits

```bash
git rebase -i HEAD~5
# Change 'pick' to 'edit' for commits to fix

# At each stop:
git commit --amend --author="Name <email@example.com>" --no-edit
git rebase --continue
```

## Sensitive Data Pushed

### URGENT: Immediate Response

```bash
# Remove from history
git filter-repo --path secrets.env --invert-paths

# Force push to all branches
git push --force --all

# Important steps:
# 1. Tell team to re-clone repo
# 2. Rotate any exposed credentials immediately!
# 3. Check git logs to see who accessed the credentials
# 4. Update secrets management system
```

### Prevention

```bash
# Pre-commit hook to catch secrets
#!/bin/bash
if git diff --cached | grep -E 'password|secret|token|key'; then
  echo "Error: Credentials found in commit"
  exit 1
fi

# Use .gitignore for sensitive files
.env
secrets.json
credentials.json
```

## Undo Last Push

### If No One Else Has Pulled

```bash
# Safe to rewrite history
git reset --hard HEAD~1
git push --force-with-lease
```

### If Others Have Pulled

```bash
# Revert instead (safe, creates new commit)
git revert HEAD
git push

# This undoes the changes without rewriting history
```

### Full Recovery With Reflog

```bash
# If refs are lost on remote
# This is rare, but possible with certain Git server setups

# View what was pushed recently
git reflog

# Push recovery
git push --force-with-lease origin <commit>:refs/heads/main
```
