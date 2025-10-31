#!/usr/bin/env bash
# Script: run-tests.sh
# Description: Simple test runner for unit tests
# Usage: ./run-tests.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "Running Unit Tests"
echo "=========================================="
echo ""

# Run the test suite
bash "${SCRIPT_DIR}/unit/test-common-functions.sh"
exit_code=$?

echo ""
echo "=========================================="
echo "Generating Coverage Report"
echo "=========================================="
echo ""

bash "${SCRIPT_DIR}/generate-coverage.sh"

exit ${exit_code}
