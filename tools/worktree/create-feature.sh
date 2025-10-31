#!/bin/bash

# Script to create a new feature branch in a worktree

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <feature-name> [base-branch]"
    echo "Example: $0 user-authentication trunk"
    exit 1
fi

FEATURE_NAME=$1
BASE_BRANCH=${2:-trunk}
BRANCH_NAME="feature/$FEATURE_NAME"
# Use .trees/ directory for worktrees (relative to repo root)
REPO_ROOT=$(git rev-parse --show-toplevel)
WORKTREE_PATH="$REPO_ROOT/.trees/$FEATURE_NAME"

echo "Creating worktree for feature '$FEATURE_NAME'..."

# Create the branch and worktree
git worktree add -b "$BRANCH_NAME" "$WORKTREE_PATH" "$BASE_BRANCH"

echo "✅ Worktree created at $WORKTREE_PATH"
echo ""
echo "To start working on this feature:"
echo "  cd $WORKTREE_PATH"
echo "  pnpm install"
echo "  pnpm dev"
echo ""
echo "To remove this worktree when done:"
echo "  ./tools/worktree/remove-feature.sh $FEATURE_NAME"