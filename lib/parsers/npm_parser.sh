#!/bin/bash
# NPM Parser - Extracts errors from npm command output

parse_npm() {
    local errors=()
    local error_code=""
    local error_path=""
    local error_type=""
    
    while IFS= read -r line; do
        # Extract error code
        if [[ "$line" =~ npm\ ERR!\ code\ ([A-Z_]+) ]]; then
            error_code="${BASH_REMATCH[1]}"
        fi
        
        # Extract file path
        if [[ "$line" =~ npm\ ERR!\ path\ (.+) ]]; then
            error_path="${BASH_REMATCH[1]}"
        fi
        
        # Extract error type
        if [[ "$line" =~ npm\ ERR!\ ([A-Z_]+): ]]; then
            error_type="${BASH_REMATCH[1]}"
        fi
        
        # Keep actual error lines
        if echo "$line" | grep -q "npm ERR!"; then
            # Skip noise
            if ! echo "$line" | grep -qE "npm ERR! A complete log|npm ERR! $"; then
                errors+=("$line")
            fi
        fi
    done
    
    # Generate summary
    if [[ -n "$error_code" ]]; then
        echo "=== NPM ERROR SUMMARY ==="
        echo "Error Code: $error_code"
        [[ -n "$error_path" ]] && echo "File: $error_path"
        [[ -n "$error_type" ]] && echo "Type: $error_type"
        echo ""
        echo "=== ERROR DETAILS ==="
        printf '%s\n' "${errors[@]}" | head -15
    else
        # No structured error, show all npm ERR lines
        printf '%s\n' "${errors[@]}" | head -20
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    parse_npm
fi
