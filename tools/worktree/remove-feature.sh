#!/bin/bash

# Script to remove a feature worktree

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <feature-name>"
    echo "Example: $0 user-authentication"
    exit 1
fi

FEATURE_NAME=$1
WORKTREE_PATH="../umemee-$FEATURE_NAME"
BRANCH_NAME="feature/$FEATURE_NAME"

if [ ! -d "$WORKTREE_PATH" ]; then
    echo "Error: Worktree not found at $WORKTREE_PATH"
    exit 1
fi

echo "Removing worktree for feature '$FEATURE_NAME'..."

# Remove the worktree
git worktree remove "$WORKTREE_PATH"

# Optionally delete the branch
read -p "Delete the branch '$BRANCH_NAME'? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git branch -d "$BRANCH_NAME" 2>/dev/null || git branch -D "$BRANCH_NAME"
    echo "✅ Branch '$BRANCH_NAME' deleted"
fi

echo "✅ Worktree removed successfully"