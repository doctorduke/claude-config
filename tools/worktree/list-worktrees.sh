#!/bin/bash

# Script to list all active worktrees

echo "Active worktrees:"
echo "=================="
git worktree list --porcelain | grep -E "^worktree|^branch" | paste - - | while read -r worktree branch; do
    worktree_path=$(echo "$worktree" | cut -d' ' -f2)
    branch_name=$(echo "$branch" | cut -d' ' -f2 | sed 's/refs\/heads\///')
    echo "📁 $worktree_path"
    echo "   └─ 🌿 $branch_name"
    echo ""
done