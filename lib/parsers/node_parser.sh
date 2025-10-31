#!/bin/bash
set -euo pipefail
# Node.js Parser - Extracts stack traces and errors from Node output

parse_node() {
    local in_stack=false
    local stack_lines=0
    local max_stack_lines=15
    
    while IFS= read -r line; do
        # Detect error start
        if echo "$line" | grep -qE "^[A-Za-z]+Error:|^Error:"; then
            echo "$line"
            in_stack=true
            stack_lines=0
            continue
        fi
        
        # In stack trace
        if [[ "$in_stack" == true ]]; then
            # Stack trace line
            if echo "$line" | grep -qE "^\s+at\s"; then
                # Filter out node_modules unless it's the first occurrence
                if ! echo "$line" | grep -q "node_modules" || [[ $stack_lines -lt 3 ]]; then
                    echo "$line"
                    ((stack_lines++))
                    [[ $stack_lines -ge $max_stack_lines ]] && in_stack=false
                fi
            else
                # End of stack trace
                in_stack=false
                # Check if this line has useful info
                if echo "$line" | grep -qiE "error|fail|exception"; then
                    echo "$line"
                fi
            fi
        else
            # Not in stack, look for errors
            if echo "$line" | grep -qiE "error|exception|fail|fatal|syntaxerror|referenceerror|typeerror"; then
                echo "$line"
            fi
        fi
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    parse_node
fi
