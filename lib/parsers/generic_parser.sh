#!/bin/bash
set -euo pipefail
# Generic Parser - Universal fallback for any command output

parse_generic() {
    local max_lines=50
    local line_count=0
    local all_lines=()
    
    # Read all input into array first
    while IFS= read -r line || [[ -n "$line" ]]; do
        all_lines+=("$line")
    done
    
    # Extract errors and warnings
    for line in "${all_lines[@]}"; do
        # Skip empty lines
        [[ -z "$line" ]] && continue
        
        # Keep error/warning lines
        if echo "$line" | grep -qiE "error|fail|exception|fatal|critical|warning|warn"; then
            echo "$line"
            ((line_count++))
            [[ $line_count -ge $max_lines ]] && break
        fi
    done
    
    # If no errors found, show first and last 10 lines
    if [[ $line_count -eq 0 ]]; then
        local total=${#all_lines[@]}
        if [[ $total -gt 20 ]]; then
            printf '%s\n' "${all_lines[@]:0:10}"
            echo "... (showing first 10 and last 10 of $total lines) ..."
            printf '%s\n' "${all_lines[@]: -10}"
        else
            printf '%s\n' "${all_lines[@]}"
        fi
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    parse_generic
fi
