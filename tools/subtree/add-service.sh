#!/bin/bash

# Script to add a new service as a git subtree

set -e

if [ $# -lt 2 ]; then
    echo "Usage: $0 <service-name> <repository-url> [branch]"
    echo "Example: $0 auth-service https://github.com/umemee/auth-service.git main"
    exit 1
fi

SERVICE_NAME=$1
REPO_URL=$2
BRANCH=${3:-main}
PREFIX="services/$SERVICE_NAME"

echo "Adding service '$SERVICE_NAME' from $REPO_URL ($BRANCH branch)..."

# Add the remote
git remote add -f "$SERVICE_NAME" "$REPO_URL" 2>/dev/null || echo "Remote already exists"

# Add the subtree
git subtree add --prefix="$PREFIX" "$SERVICE_NAME" "$BRANCH" --squash

echo "✅ Service '$SERVICE_NAME' added at $PREFIX"
echo ""
echo "To update this service in the future, run:"
echo "  ./tools/subtree/update-service.sh $SERVICE_NAME"
echo ""
echo "To push changes back to the service repository, run:"
echo "  ./tools/subtree/push-service.sh $SERVICE_NAME"