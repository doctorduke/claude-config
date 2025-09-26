#!/bin/bash

# Script to update a service from its source repository

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

echo "Updating service '$SERVICE_NAME' from $BRANCH branch..."

# Fetch latest changes
git fetch "$SERVICE_NAME" "$BRANCH"

# Pull changes into subtree
git subtree pull --prefix="$PREFIX" "$SERVICE_NAME" "$BRANCH" --squash -m "Update $SERVICE_NAME from upstream"

echo "✅ Service '$SERVICE_NAME' updated successfully"