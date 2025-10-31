#!/bin/bash
# Generic Parser - Universal fallback for any command output

parse_generic() {
    local max_lines=50
    local line_count=0
    
    # Extract errors and warnings
    while IFS= read -r line; do
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
        head -10
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    parse_generic
fi
