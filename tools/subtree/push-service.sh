#!/bin/bash

# Script to push changes back to a service repository

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <service-name> [branch]"
    echo "Example: $0 auth-service main"
    exit 1
fi

SERVICE_NAME=$1
BRANCH=${2:-main}
PREFIX="services/$SERVICE_NAME"

if [ ! -d "$PREFIX" ]; then
    echo "Error: Service '$SERVICE_NAME' not found at $PREFIX"
    exit 1
fi

echo "Pushing changes for service '$SERVICE_NAME' to $BRANCH branch..."

# Push changes back to service repository
git subtree push --prefix="$PREFIX" "$SERVICE_NAME" "$BRANCH"

echo "✅ Changes pushed to '$SERVICE_NAME' repository successfully"