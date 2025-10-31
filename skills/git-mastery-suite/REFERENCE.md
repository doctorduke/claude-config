# Git Command Reference

## Table of Contents

1. [History Viewing](#history-viewing)
2. [Uncommitted Work (Stash)](#uncommitted-work-stash)
3. [Branch Management](#branch-management)
4. [Remote Operations](#remote-operations)
5. [Rebase Operations](#rebase-operations)
6. [Merge Operations](#merge-operations)
7. [Worktree Management](#worktree-management)
8. [Bisect Operations](#bisect-operations)
9. [Reflog & Recovery](#reflog--recovery)
10. [Filter & Cleanup](#filter--cleanup)
11. [Git Aliases](#git-aliases)

## History Viewing

### Basic Logging

```bash
# Simple oneline log
git log --oneline

# With branch graph
git log --oneline --graph --all --decorate

# Full graph view (all branches)
git log --graph --pretty=format:'%C(yellow)%h%Creset -%C(auto)%d%Creset %s %C(green)(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --all
```

### Search and Filter

```bash
# Search commits by message
git log --grep="bug fix"

# Search commits by code change
git log -S"function_name"      # Commits changing lines with this text
git log -p -- file.txt        # Show changes to specific file

# Show commits by author
git log --author="Alice"

# Commits between branches
git log branch1..branch2       # In branch1 but not branch2
git log branch1...branch2      # In either but not both

# Last N commits
git log -5                     # Last 5 commits
git log --since="2 weeks ago"
git log --until="2023-01-01"
```

### Detailed Views

```bash
# Show last commit with statistics
git log -1 HEAD --stat

# Show changes with diff
git log -p -1                  # Show last commit with full diff

# Show commit ancestry path
git log --ancestry-path commit1..commit2

# Show commits affecting specific file
git log --follow -- filename
```

### Viewing Differences

```bash
# Unstaged changes
git diff

# Staged changes
git diff --cached

# All changes (staged + unstaged)
git diff HEAD

# Between branches
git diff branch1..branch2

# Between commits
git diff abc123 def456

# Show stat only (no actual diff)
git diff --stat

# Show names and status
git diff --name-status
```

## Uncommitted Work (Stash)

### Stashing

```bash
# Stash with message
git stash push -m "WIP: feature"

# Stash including untracked files
git stash -u

# Stash specific files
git stash push -- file1.txt file2.txt

# Stash with description
git stash push -m "working on feature X"
```

### Retrieving Stash

```bash
# List stashes
git stash list

# Apply stash without dropping
git stash apply stash@{0}

# Apply and drop stash
git stash pop

# Apply specific stash
git stash apply stash@{2}

# Show stash contents
git stash show stash@{0}
git stash show -p stash@{0}   # With full diff
```

### Stash Management

```bash
# Create branch from stash
git stash branch new-feature stash@{0}

# Delete stash
git stash drop stash@{0}

# Delete all stashes
git stash clear

# View stash diff
git stash show -p
```

## Branch Management

### Creating and Switching

```bash
# Create branch
git branch feature-branch

# Create and switch
git checkout -b feature-branch
git switch -c feature-branch   # Newer syntax

# Switch to branch
git checkout feature-branch
git switch feature-branch       # Newer syntax

# Create from specific commit
git checkout -b recovery-branch abc123
```

### Listing Branches

```bash
# List local branches
git branch

# List remote branches
git branch -r

# List all branches
git branch -a

# List with tracking info
git branch -vv

# List merged branches
git branch --merged main

# List unmerged branches
git branch --no-merged
```

### Renaming and Deleting

```bash
# Rename branch locally
git branch -m old-name new-name

# Delete local branch
git branch -d feature-branch    # Safe (requires fully merged)
git branch -D feature-branch    # Force delete

# Delete remote branch
git push origin --delete feature-branch
git push -d origin feature-branch  # Shorthand

# Prune deleted remote branches
git fetch --prune
git branch -r --prune
```

### Branch Tracking

```bash
# Set upstream branch
git branch -u origin/feature-branch

# Show branch tracking
git branch -vv

# Unset upstream
git branch --unset-upstream
```

## Remote Operations

### Fetching and Pulling

```bash
# Fetch (no merge)
git fetch origin

# Fetch specific branch
git fetch origin feature-branch

# Fetch all remotes
git fetch --all

# Prune deleted remote branches
git fetch --prune
git fetch --prune --all

# Pull with merge
git pull origin main

# Pull with rebase
git pull --rebase
git pull -r

# Pull with specific strategy
git pull -X theirs
```

### Pushing

```bash
# Push to default remote
git push

# Push to specific remote/branch
git push origin feature-branch

# Push new branch and set upstream
git push -u origin feature-branch
git push --set-upstream origin feature-branch

# Push all branches
git push --all

# Push all tags
git push --tags

# Push with force (DANGEROUS)
git push --force                      # Force overwrite (bad!)
git push --force-with-lease           # Safe force (checks lease)

# Delete remote branch
git push origin --delete feature-branch
git push -d origin feature-branch

# Push specific commit
git push origin abc123:refs/heads/new-branch
```

### Remote Configuration

```bash
# Show remote details
git remote show origin

# List remotes
git remote -v

# Add remote
git remote add upstream https://github.com/user/repo.git

# Remove remote
git remote remove upstream

# Rename remote
git remote rename origin upstream

# Change remote URL
git remote set-url origin https://new-url.git
```

## Rebase Operations

### Basic Rebase

```bash
# Rebase current branch on main
git rebase main

# Rebase specific commit range
git rebase main..feature-branch

# Rebase onto specific commit
git rebase abc123

# Interactive rebase last 5 commits
git rebase -i HEAD~5

# Interactive rebase on main
git rebase -i main
```

### Interactive Rebase Commands

During `git rebase -i`, use these commands in editor:

```bash
pick abc123 Commit message       # Use commit
reword abc123 Commit message     # Use commit, edit message
edit abc123 Commit message       # Use commit, pause for changes
squash abc123 Commit message     # Combine with previous
fixup abc123 Commit message      # Combine, discard message
drop abc123 Commit message       # Remove commit
exec npm test                    # Run command after this commit
break                            # Pause rebase here
```

### Rebase Management

```bash
# Continue after resolving conflicts
git rebase --continue

# Skip current commit during rebase
git rebase --skip

# Abort rebase
git rebase --abort

# Autosquash fixup commits
git rebase -i --autosquash origin/main
```

## Merge Operations

### Merge Strategies

```bash
# Default merge (recursive)
git merge feature-branch

# Create merge commit (even if fast-forward possible)
git merge --no-ff feature-branch

# Fast-forward only (fail if non-FF)
git merge --ff-only feature-branch

# Squash commits before merging
git merge --squash feature-branch

# Merge with different strategy
git merge -X theirs feature-branch      # Prefer their changes in conflicts
git merge -X ours feature-branch        # Prefer our changes in conflicts
```

### Conflict Resolution

```bash
# Check conflicted files
git status

# View conflicts
git diff

# Use merge tool
git mergetool

# Accept one side
git checkout --ours file.txt
git checkout --theirs file.txt

# Abort merge
git merge --abort

# Continue merge after resolution
git merge --continue
```

## Worktree Management

### Creating and Removing

```bash
# Create worktree
git worktree add ../hotfix hotfix-branch

# Create worktree on new branch
git worktree add -b new-branch ../new-dir origin/main

# Create from detached HEAD
git worktree add --detach ../temp abc123

# List worktrees
git worktree list

# Show worktree details
git worktree list --porcelain
```

### Worktree Operations

```bash
# Remove worktree
git worktree remove ../hotfix

# Force remove
git worktree remove -f ../hotfix

# Lock worktree (prevent removal)
git worktree lock ../hotfix

# Lock with reason
git worktree lock --reason "PR review in progress" ../hotfix

# Unlock
git worktree unlock ../hotfix

# Repair broken worktrees
git worktree repair

# Prune stale worktrees
git worktree prune
```

## Bisect Operations

### Basic Bisect

```bash
# Start bisect
git bisect start

# Mark current as bad
git bisect bad

# Mark commit as good
git bisect good abc123

# Mark as bad/good in steps
git bisect bad
git bisect good
# Git shows: "remaining X revisions to test"

# When complete
git bisect reset
```

### Automated Bisect

```bash
# Bisect with test script
git bisect start HEAD main
git bisect run ./test-script.sh

# Script exit codes:
# 0 = good commit
# 1 = bad commit
# 125 = skip this commit
```

### Bisect Results

```bash
# See first bad commit
git bisect log

# View the culprit
git show                    # Shows first bad commit

# Return to normal state
git bisect reset
```

## Reflog & Recovery

### View Reflog

```bash
# View HEAD reflog
git reflog

# View reflog for specific branch
git reflog show feature-branch

# View detailed reflog
git reflog --all

# Pretty print reflog
git reflog --format="%h %gd %gs"
```

### Recovery Using Reflog

```bash
# Reset to previous state
git reset --hard HEAD@{n}      # n = number in reflog

# Create branch from lost commit
git branch recovery HEAD@{1}

# Checkout lost commit
git checkout abc123            # From reflog output

# Show commit details
git show HEAD@{0}
```

### Reflog Configuration

```bash
# Set reflog expiration (days)
git config gc.reflogExpireUnreachable 90

# Disable reflog for specific branch
git reflog expire --expire=now --all

# Clear all reflog
git reflog expire --expire=now --all
```

## Filter & Cleanup

### Finding Issues

```bash
# Find largest files
git rev-list --objects --all |
  git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' |
  sed -n 's/^blob //p' |
  sort --numeric-sort --key=2 |
  tail -n 10

# Find specific file in history
git log --all --full-history -- lost-file.txt

# Show commits that deleted file
git log --diff-filter=D --summary | grep delete
```

### History Rewriting

```bash
# Remove file from history
git filter-repo --path file-to-remove.txt --invert-paths

# Remove directory
git filter-repo --path directory --invert-paths

# Remove by pattern
git filter-repo --strip-blobs-bigger-than 10M

# Rewrite author (needs mailmap file)
git filter-repo --mailmap-file mailmap
```

### Cleanup

```bash
# Run garbage collection
git gc

# Aggressive cleanup
git gc --aggressive

# Prune unreachable objects
git gc --prune=now

# Remove local branches tracking deleted remote
git branch -vv | grep 'gone' | awk '{print $1}' | xargs git branch -D
```

## Git Aliases

Add to `~/.gitconfig`:

```ini
[alias]
  # Shortcuts
  st = status -sb
  co = checkout
  br = branch
  ci = commit
  unstage = reset HEAD --

  # Logging
  lg = log --oneline --graph --all --decorate
  lol = log --graph --pretty=format:'%C(yellow)%h%Creset -%C(auto)%d%Creset %s %C(green)(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --all

  # History
  last = log -1 HEAD --stat
  undo = reset --soft HEAD~1
  amend = commit --amend --no-edit

  # Cleanup
  cleanup = "!git branch --merged main | grep -v 'main' | xargs -n 1 git branch -d"

  # Find
  find-merge = "!sh -c 'commit=$0 && branch=${1:-HEAD} && (git rev-list $commit..$branch --ancestry-path | cat -n; git rev-list $commit..$branch --first-parent | cat -n) | sort -k2 -s | uniq -f1 -d | sort -n | tail -1 | cut -f2'"

  # Submodules
  sdiff = !git diff && git submodule foreach 'git diff'
  spush = push --recurse-submodules=on-demand
  supdate = submodule update --remote --merge
```

### Install Aliases

```bash
# Copy to config
git config --global alias.st "status -sb"
git config --global alias.co checkout
git config --global alias.lg "log --oneline --graph --all --decorate"
```
