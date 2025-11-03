# Advanced Git Patterns

## Table of Contents

1. [Interactive Rebase](#interactive-rebase)
2. [Worktree Workflows](#worktree-workflows)
3. [Bisect for Bug Hunting](#bisect-for-bug-hunting)
4. [Advanced Conflict Resolution](#advanced-conflict-resolution)
5. [Commit Surgery](#commit-surgery)
6. [Submodule Management](#submodule-management)
7. [Reflog Recovery](#reflog-recovery)
8. [Git Hooks](#git-hooks)
9. [Repository Cleanup](#repository-cleanup)
10. [Branching Strategies](#branching-strategies)

## Interactive Rebase

### Clean Up Feature Branch Before Merging

```bash
# Start interactive rebase on last 5 commits
git rebase -i HEAD~5

# In editor, reorder/edit commits:
# pick abc123 Add feature
# squash def456 Fix typo          <- Combine into previous
# edit ghi789 Update docs          <- Stop to modify
# drop jkl012 Debug code           <- Remove entirely
# reword mno345 Add tests          <- Change message

# After 'edit', make changes:
git add modified_files
git rebase --continue

# If conflicts occur:
git status                         # See conflicts
# Fix conflicts in files
git add fixed_files
git rebase --continue
```

### Pro Tips

- Use `fixup` instead of `squash` to auto-discard commit message
- `exec` to run tests after each commit: `exec npm test`
- `break` to pause rebase for manual intervention
- `--autosquash` automatically applies fixup/squash commits

```bash
# Auto-squash with fixups
git commit --fixup abc123
git commit --fixup abc123
git rebase -i --autosquash HEAD~10
```

### Abort If Things Go Wrong

```bash
# During rebase, if things go sideways
git rebase --abort

# Or reset to pre-rebase state
git reflog                         # Find the pre-rebase commit
git reset --hard HEAD@{n}
```

## Worktree Workflows

### Work on Multiple Branches Simultaneously

```bash
# Create worktree for hotfix (parallel to main worktree)
git worktree add ../myproject-hotfix hotfix-branch

# Now you have:
# ./myproject/           <- Main worktree on 'main' branch
# ./myproject-hotfix/    <- Second worktree on 'hotfix-branch'

# Work in hotfix, commits go to hotfix-branch
cd ../myproject-hotfix
# Make changes, commit
git add . && git commit -m "Fix critical bug"

# Switch back to main work
cd ../myproject

# When done, clean up
git worktree remove ../myproject-hotfix
```

### Use Cases

- Long-running feature branches without stashing
- Hotfixes without disrupting current work
- Reviewing PRs locally
- Running CI/tests on different branches simultaneously

### Advanced Worktree Operations

```bash
# List all worktrees
git worktree list

# Repair broken worktree
git worktree repair

# Remove stale worktree (if directory was deleted)
git worktree prune

# Lock worktree (prevent accidental removal)
git worktree lock ../myproject-hotfix

# With reason
git worktree lock --reason "PR review in progress" ../myproject-hotfix

# Unlock
git worktree unlock ../myproject-hotfix
```

## Bisect for Bug Hunting

### Find the Commit That Introduced a Bug

```bash
# Start bisect
git bisect start

# Mark current commit as bad
git bisect bad

# Mark last known good commit (e.g., last release)
git bisect good v1.2.0

# Git checks out middle commit - test it
npm test

# Tell git if this commit is good or bad
git bisect good    # Bug not present
# or
git bisect bad     # Bug present

# Repeat until git finds the culprit commit
# Git will say: "abc123 is the first bad commit"

# View details of first bad commit
git show abc123

# Clean up
git bisect reset
```

### Automated Bisect

```bash
# Let Git auto-bisect using test script
git bisect start HEAD v1.2.0
git bisect run npm test

# Git will automatically test each commit and find the bad one
# Exit code 0 = good, exit code 1 = bad, 125 = skip
```

### Custom Bisect Script

```bash
# bisect-test.sh
#!/bin/bash
# Return 0 if tests pass (good), 1 if fail (bad), 125 if skip
npm test --silent
```

Then use:

```bash
git bisect start HEAD v1.2.0
git bisect run ./bisect-test.sh
```

## Advanced Conflict Resolution

### Understanding Three-Way Merge

```bash
# Check conflict sources
git status                          # Shows conflicted files
git diff                            # Shows conflict markers

# View all three versions
git show :1:file.txt                # Common ancestor version
git show :2:file.txt                # Our version (HEAD)
git show :3:file.txt                # Their version (merging branch)

# Accept one side entirely
git checkout --ours file.txt        # Keep our version
git checkout --theirs file.txt      # Keep their version

# After resolving all conflicts
git add .
git rebase --continue               # If rebasing
git merge --continue                # If merging
```

### Using Merge Tools

```bash
# Interactive merge tool
git mergetool

# Common tools:
# vimdiff, meld, kdiff3, tortoisemerge, p4merge

# Configure default
git config --global merge.tool vimdiff
git config --global merge.vimdiff.cmd 'vimdiff -c "wincmd l" -d "$BASE" "$LOCAL" "$REMOTE" "$MERGED"'
```

### Conflict Prevention with Rerere

```bash
# Enable rerere (reuse recorded resolution)
git config --global rerere.enabled true

# Git will remember how you resolved conflicts and auto-apply
# Useful for long-running feature branches with repeated merges
```

## Commit Surgery

### Modify Old Commits Without Full Rebase

```bash
# Create fixup commits
git commit --fixup <old-commit-hash>
# Make your changes
git add .
git commit --fixup <old-commit-hash>

# Auto-squash fixups into original commits
git rebase -i --autosquash <base-commit>
```

### Edit Specific Commit in History

```bash
git rebase -i <commit-before-target>^
# Change 'pick' to 'edit' for target commit
# Make changes, then:
git commit --amend
git rebase --continue
```

### Change Commit Message

```bash
# Last commit
git commit --amend

# Old commit
git rebase -i HEAD~10
# Change 'pick' to 'reword'
git rebase --continue
```

## Submodule Management

### Add Submodule

```bash
git submodule add https://github.com/user/lib.git libs/lib
git commit -m "Add lib submodule"
```

### Clone with Submodules

```bash
# Clone repo with submodules
git clone --recurse-submodules https://github.com/user/project.git

# Or if already cloned without submodules
git submodule update --init --recursive
```

### Update Submodules

```bash
# Update all submodules to latest
git submodule update --remote

# Update specific submodule
cd libs/lib
git checkout main
git pull
cd ../..
git add libs/lib
git commit -m "Update lib submodule"

# Update and merge
git submodule update --remote --merge
```

### Remove Submodule

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

### Workflow for Submodule Development

```bash
# Make changes in submodule
cd libs/lib
git checkout -b feature/new-feature
# Make changes, commit
git push -u origin feature/new-feature
cd ../..

# Update parent to point to new commit
git add libs/lib
git commit -m "Update lib with new feature"

# Merge submodule PR, update parent
git submodule update --remote
git add libs/lib
git commit -m "Update lib submodule"
```

## Reflog Recovery

### Recover Lost Commits

```bash
# View reflog (journal of HEAD movements)
git reflog

# Output shows:
# abc123 HEAD@{0}: reset: moving to HEAD~3
# def456 HEAD@{1}: commit: Add feature
# ghi789 HEAD@{2}: commit: Update docs

# Recover lost commit
git checkout def456                  # Or: git reset --hard def456

# Create branch from lost commit
git branch recovery HEAD@{1}

# Reflog for specific branch
git reflog show feature-branch
```

### Reflog Expiration

- Reflog entries expire after 90 days by default
- Can recover anything within that window
- Configure expiration: `git config gc.reflogExpireUnreachable 90`

## Git Hooks

### Common Hooks

- `pre-commit` - Run before creating commit
- `commit-msg` - Validate commit message
- `pre-push` - Run before pushing
- `post-commit` - Run after successful commit
- `post-merge` - Run after merge

### Pre-commit Hook Example

```bash
#!/bin/bash
# Prevent commits to main branch
branch=$(git rev-parse --abbrev-ref HEAD)
if [ "$branch" = "main" ]; then
  echo "Error: Direct commits to main are not allowed!"
  exit 1
fi

# Run linter
npm run lint || exit 1

# Run tests
npm test || exit 1
```

### Commit-msg Hook Example

```bash
#!/bin/bash
# Enforce commit message format: "type: description"
commit_msg=$(cat "$1")
pattern="^(feat|fix|docs|style|refactor|test|chore): .+"

if ! echo "$commit_msg" | grep -qE "$pattern"; then
  echo "Error: Commit message must match format: type: description"
  echo "Valid types: feat, fix, docs, style, refactor, test, chore"
  exit 1
fi
```

### Make Hooks Executable and Shared

```bash
# Make executable
chmod +x .git/hooks/pre-commit
chmod +x .git/hooks/commit-msg

# Store in version control
mkdir -p hooks
cp .git/hooks/pre-commit hooks/
cp .git/hooks/commit-msg hooks/

# Setup script
#!/bin/bash
cp hooks/* .git/hooks/
chmod +x .git/hooks/*

# Or use tools like husky (Node.js)
npm install husky
npx husky install
```

## Repository Cleanup

### Find Largest Files

```bash
# Find largest objects in history
git rev-list --objects --all |
  git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' |
  sed -n 's/^blob //p' |
  sort --numeric-sort --key=2 |
  tail -n 10
```

### Remove Large Files from History

```bash
# DESTRUCTIVE! Requires force push

# Remove specific file
git filter-repo --path large-file.bin --invert-paths

# Or use BFG Repo Cleaner (faster)
bfg --delete-files "*.log" --strip-blobs-bigger-than 10M
bfg --strip-blobs-bigger-than 10M

# Force push
git push --force --all

# Coordinate with team - they must re-clone!
```

### Run Garbage Collection

```bash
git gc --prune=now --aggressive
```

**Warning**: History rewriting breaks existing clones. Coordinate with team!

## Branching Strategies

### Git Flow

```bash
# Main branches
main        # Production
develop     # Integration

# Supporting branches
feature/*   # New features
release/*   # Release prep
hotfix/*    # Production fixes

# Example workflow
git checkout -b feature/new-feature develop
# Work on feature...
git checkout develop
git merge --no-ff feature/new-feature

# Release
git checkout -b release/1.0.0 develop
# Bump version, fix bugs...
git checkout main
git merge --no-ff release/1.0.0
git tag v1.0.0
git checkout develop
git merge --no-ff release/1.0.0
```

### Trunk-Based Development

```bash
# Single main branch with short-lived feature branches
main        # Always deployable

# Feature branches live <1 day
git checkout -b feat/quick-feature main
# Work...
git checkout main
git merge --no-ff feat/quick-feature
git push
```

### GitHub Flow

```bash
# main is always deployable

# Create feature branch
git checkout -b feature/description main

# Push and create PR
git push -u origin feature/description

# After review and approval
git merge --squash feature/description
git push
```
