#!/usr/bin/env bash

# Quick verification of token pattern fixes

echo "Checking token patterns in setup-runner.sh..."
echo "============================================="

# Check sanitize_log function
echo -e "\n1. Checking sanitize_log function:"
grep -A5 "^sanitize_log()" scripts/setup-runner.sh | grep "ghp_"

# Check verify_no_tokens_in_logs function
echo -e "\n2. Checking verify_no_tokens_in_logs function:"
grep -A5 "^verify_no_tokens_in_logs()" scripts/setup-runner.sh | grep "ghp_"

# Check if contains_token function exists
echo -e "\n3. Checking if contains_token function was removed:"
if grep -q "^contains_token()" scripts/setup-runner.sh; then
    echo "ERROR: contains_token function still exists!"
else
    echo "SUCCESS: contains_token function has been removed"
fi

# List all token patterns found
echo -e "\n4. Token patterns in sanitize_log:"
patterns=$(grep "ghp_" scripts/setup-runner.sh | head -1 | grep -o '[a-z_]*_' | sort -u)
for p in $patterns; do
    echo "  - $p"
done

echo -e "\n5. Token patterns in verify_no_tokens_in_logs:"
patterns=$(grep "ghp_" scripts/setup-runner.sh | tail -1 | grep -o '[a-z_]*_' | sort -u)
for p in $patterns; do
    echo "  - $p"
done

echo -e "\nVerification complete!"