#!/bin/bash
set -euo pipefail
# Python Parser - Extracts tracebacks and errors from Python output

parse_python() {
    local in_traceback=false
    local traceback_lines=()
    
    while IFS= read -r line; do
        # Detect traceback start
        if echo "$line" | grep -q "^Traceback (most recent call last):"; then
            in_traceback=true
            traceback_lines=("$line")
            continue
        fi
        
        # In traceback
        if [[ "$in_traceback" == true ]]; then
            traceback_lines+=("$line")
            
            # Detect traceback end (error line)
            if echo "$line" | grep -qE "^[A-Za-z]+Error:|^[A-Za-z]+Exception:"; then
                # Print traceback
                printf '%s\n' "${traceback_lines[@]}"
                traceback_lines=()
                in_traceback=false
            fi
        else
            # Not in traceback, look for errors
            if echo "$line" | grep -qiE "error|exception|fail|fatal|warning"; then
                echo "$line"
            fi
        fi
    done
    
    # Print any remaining traceback
    if [[ ${#traceback_lines[@]} -gt 0 ]]; then
        printf '%s\n' "${traceback_lines[@]}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    parse_python
fi
