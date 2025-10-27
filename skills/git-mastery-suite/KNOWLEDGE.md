# Git Knowledge & Learning Resources

## Table of Contents

1. [Core Concepts](#core-concepts)
2. [Official Documentation](#official-documentation)
3. [Essential Resources](#essential-resources)
4. [Git Object Model](#git-object-model)
5. [Ref Types](#ref-types)

## Core Concepts

### Git Object Model

```
Commit -> Tree -> Blob
   |
   v
Parent Commit(s)
```

Every commit points to a tree (directory structure), which contains blobs (files) and other trees (subdirectories). Understanding this is critical for advanced operations.

The Git object model consists of:

- **Blob** - File contents (immutable)
- **Tree** - Directory listing (maps names to blobs/trees)
- **Commit** - Snapshot of the repository with metadata
- **Tag** - Named reference to a commit

### Ref Types

- **Branches** - Movable pointers to commits (`refs/heads/main`)
- **Tags** - Fixed pointers to commits (`refs/tags/v1.0.0`)
- **Remote-tracking** - Copies of remote branches (`refs/remotes/origin/main`)
- **HEAD** - Pointer to current commit (usually via branch)
- **Reflog** - Journal of where HEAD has been

### Three-Way Merge

When resolving conflicts, Git provides three versions:

- `:1` - Common ancestor (merge base)
- `:2` - Our version (HEAD, typically main branch)
- `:3` - Their version (branch being merged in)

This context is essential for understanding conflict markers and manual resolution.

## Official Documentation

### Primary Resources

- **[Git Book](https://git-scm.com/book/en/v2)** - Comprehensive Git reference covering basics to advanced topics
- **[Git Internals](https://git-scm.com/book/en/v2/Git-Internals-Plumbing-and-Porcelain)** - Understanding Git's architecture and storage
- **[Git Workflows](https://git-scm.com/book/en/v2/Distributed-Git-Distributed-Workflows)** - Team workflow patterns and collaboration strategies
- **[Interactive Rebase](https://git-scm.com/book/en/v2/Git-Tools-Rewriting-History)** - History manipulation and commit editing
- **[Git Reference Manual](https://git-scm.com/docs)** - Official command reference

### Topic-Specific Docs

- **Submodules** - https://git-scm.com/book/en/v2/Git-Tools-Submodules
- **Hooks** - https://git-scm.com/docs/githooks
- **Filter-Repo** - https://htmlpreview.github.io/?https://github.com/newren/git-filter-repo/blob/docs/html/git-filter-repo.html

## Essential Resources

### Problem-Solving Guides

- **[Oh Shit, Git!?!](https://ohshitgit.com/)** - Fixing common Git mistakes with straightforward solutions
- **[Git Flight Rules](https://github.com/k88hudson/git-flight-rules)** - Solutions to specific Git problems organized by scenario
- **[Git Pretty](http://justinhileman.info/article/git-pretty/)** - Visual recovery flowchart for common mistakes

### Interactive Learning

- **[Learn Git Branching](https://learngitbranching.js.org/)** - Interactive Git visualization and sandbox
- **[Atlassian Git Tutorials](https://www.atlassian.com/git/tutorials)** - Practical guides with detailed explanations

### Quick References

- **[GitHub Git Cheat Sheet](https://education.github.com/git-cheat-sheet-education.pdf)** - Quick reference of common commands
- **[Awesome Git](https://github.com/dictcp/awesome-git)** - Curated list of Git resources

## Mental Models

### Think in Commits, Not Files

Git tracks changes as complete snapshots (commits), not file-level deltas. This affects how you understand:

- History is immutable (rebasing creates new commits)
- Commits include context (author, timestamp, message)
- References (branches, tags) are just pointers to commits

### Staging Area is Critical

The staging area (index) is between your working directory and the commit:

- `git add` moves changes from working directory to staging area
- `git commit` creates a commit from staged changes
- `git diff` shows working vs staging area
- `git diff --cached` shows staging area vs HEAD

### Rebasing Rewrites History

When rebasing:

- Old commits are left unchanged
- New commits with the same changes are created
- References (branches) point to new commits
- This breaks shared branches (only rebase local/feature branches)

### Merging Preserves History

When merging:

- Both parent histories are preserved
- A merge commit ties the histories together
- History shows full context of parallel development
- Safe for shared/public branches

## Learning Path

### Beginner to Intermediate

1. Understand the three areas (working directory, staging area, repository)
2. Master branches and basic workflow (checkout, merge, rebase)
3. Learn to read git log and understand history
4. Practice conflict resolution

### Intermediate to Advanced

1. Understand Git internals (objects, refs, reflog)
2. Master interactive rebase for history manipulation
3. Learn worktrees for parallel development
4. Understand when to use merge vs rebase

### Advanced Topics

1. Repository archaeology (bisect, blame, reflog)
2. Advanced branching strategies (git flow, trunk-based development)
3. Submodule management and workflows
4. Repository optimization and cleanup

## Historical Context

Git was created by Linus Torvalds in 2005 to manage Linux kernel development. Understanding this history helps appreciate design decisions:

- **Distributed** - Each clone is a full repository backup
- **Content-addressed** - Objects identified by SHA-1 hash of contents
- **Immutable** - Objects cannot be changed (rebasing creates new objects)
- **Flexible** - Designed for large teams with different workflows
