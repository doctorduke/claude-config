#!/usr/bin/env bash

################################################################################
# GitHub Actions Runner Label Configuration Script
# Version: 1.0.0
# Platform: WSL 2.0 / Linux / macOS
#
# Description: Manages labels for GitHub Actions self-hosted runners.
#              Supports adding, removing, and validating runner labels.
#
# Usage:
#   ./configure-labels.sh --runner-id <ID> --action <ACTION> [options]
#
# Required Arguments:
#   --runner-id <ID>      Runner ID number
#   --action <ACTION>     Action to perform: add, remove, list, validate
#
# Optional Arguments:
#   --labels <LABELS>     Comma-separated labels (for add/remove actions)
#   --org <ORG>           GitHub organization name
#   --token <TOKEN>       Runner registration token (for reconfiguration)
#   --preset <PRESET>     Use predefined label preset (see presets below)
#   --help                Show this help message
#
# Label Presets:
#   default               self-hosted,linux,x64,ai-agent,wsl-ubuntu-22.04
#   gpu                   self-hosted,linux,x64,gpu,cuda
#   high-memory           self-hosted,linux,x64,high-memory
#   docker                self-hosted,linux,x64,docker
################################################################################

set -e
set -u
set -o pipefail

# Script constants
readonly SCRIPT_VERSION="1.0.0"
readonly LOG_FILE="configure-labels.log"

# Color output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Label presets
declare -A LABEL_PRESETS=(
    ["default"]="self-hosted,linux,x64,ai-agent,wsl-ubuntu-22.04"
    ["gpu"]="self-hosted,linux,x64,gpu,cuda"
    ["high-memory"]="self-hosted,linux,x64,high-memory"
    ["docker"]="self-hosted,linux,x64,docker"
    ["windows"]="self-hosted,windows,x64"
    ["macos"]="self-hosted,macos,x64"
)

# Configuration
RUNNER_ID=""
ACTION=""
LABELS=""
GITHUB_ORG=""
RUNNER_TOKEN=""
PRESET=""

################################################################################
# Utility Functions
################################################################################

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" | tee -a "$LOG_FILE" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" | tee -a "$LOG_FILE"
}

show_help() {
    cat << EOF
GitHub Actions Runner Label Configuration Script v${SCRIPT_VERSION}

Usage: $0 --runner-id <ID> --action <ACTION> [options]

Required Arguments:
  --runner-id <ID>      Runner ID number
  --action <ACTION>     Action to perform: add, remove, list, validate, reset

Optional Arguments:
  --labels <LABELS>     Comma-separated labels (for add/remove actions)
  --org <ORG>           GitHub organization name (required for reset)
  --token <TOKEN>       Runner registration token (required for reset)
  --preset <PRESET>     Use predefined label preset (for add/reset actions)
  --help                Show this help message

Actions:
  list                  Display current labels for the runner
  add                   Add labels to the runner (preserves existing)
  remove                Remove specific labels from the runner
  reset                 Reset labels to specified set (requires reconfiguration)
  validate              Validate current labels against best practices

Label Presets:
  default               self-hosted,linux,x64,ai-agent,wsl-ubuntu-22.04
  gpu                   self-hosted,linux,x64,gpu,cuda
  high-memory           self-hosted,linux,x64,high-memory
  docker                self-hosted,linux,x64,docker
  windows               self-hosted,windows,x64
  macos                 self-hosted,macos,x64

Examples:
  # List current labels
  $0 --runner-id 1 --action list

  # Add custom labels
  $0 --runner-id 1 --action add --labels "python,nodejs"

  # Reset to GPU preset
  $0 --runner-id 1 --action reset --org myorg --token ghp_xxx --preset gpu

  # Validate labels
  $0 --runner-id 1 --action validate

EOF
    exit 0
}

################################################################################
# Runner Discovery
################################################################################

get_runner_dir() {
    local runner_id="$1"
    echo "${HOME}/actions-runner-${runner_id}"
}

check_runner_exists() {
    local runner_dir="$1"

    if [[ ! -d "$runner_dir" ]]; then
        log_error "Runner directory not found: $runner_dir"
        return 1
    fi

    if [[ ! -f "$runner_dir/.runner" ]]; then
        log_error "Runner configuration not found: $runner_dir/.runner"
        return 1
    fi

    return 0
}

################################################################################
# Label Management Functions
################################################################################

get_current_labels() {
    local runner_dir="$1"

    if [[ ! -f "$runner_dir/.runner" ]]; then
        log_error "Runner configuration file not found"
        return 1
    fi

    # Extract labels from .runner file
    local labels
    labels=$(jq -r '.labels // [] | join(",")' "$runner_dir/.runner" 2>/dev/null)

    if [[ -z "$labels" ]]; then
        echo ""
    else
        echo "$labels"
    fi
}

list_labels() {
    local runner_dir="$1"

    log "Retrieving labels for runner: $runner_dir"

    local labels
    labels=$(get_current_labels "$runner_dir")

    if [[ -z "$labels" ]]; then
        log_warn "No labels configured for this runner"
        return 0
    fi

    log "Current labels:"
    echo ""
    # Convert comma-separated to array and print
    IFS=',' read -ra label_array <<< "$labels"
    for label in "${label_array[@]}"; do
        echo "  - $label"
    done
    echo ""

    log_info "Total labels: ${#label_array[@]}"
    return 0
}

validate_labels() {
    local runner_dir="$1"

    log "Validating labels for runner: $runner_dir"

    local labels
    labels=$(get_current_labels "$runner_dir")

    if [[ -z "$labels" ]]; then
        log_error "No labels configured - runners should have at minimum: self-hosted"
        return 1
    fi

    # Convert to array
    IFS=',' read -ra label_array <<< "$labels"

    # Check for required base label
    local has_self_hosted=false
    local has_os=false
    local has_arch=false

    for label in "${label_array[@]}"; do
        case "$label" in
            self-hosted)
                has_self_hosted=true
                ;;
            linux|windows|macos)
                has_os=true
                ;;
            x64|arm64|arm)
                has_arch=true
                ;;
        esac
    done

    local validation_passed=true

    if [[ "$has_self_hosted" == "false" ]]; then
        log_error "Missing required label: self-hosted"
        validation_passed=false
    fi

    if [[ "$has_os" == "false" ]]; then
        log_warn "Missing OS label (linux/windows/macos)"
    fi

    if [[ "$has_arch" == "false" ]]; then
        log_warn "Missing architecture label (x64/arm64/arm)"
    fi

    if [[ "$validation_passed" == "true" ]]; then
        log "Label validation passed"
        list_labels "$runner_dir"
        return 0
    else
        log_error "Label validation failed"
        return 1
    fi
}

add_labels() {
    local runner_dir="$1"
    local new_labels="$2"

    log "Adding labels to runner: $runner_dir"
    log_info "New labels: $new_labels"

    # Get current labels
    local current_labels
    current_labels=$(get_current_labels "$runner_dir")

    # Merge labels (avoid duplicates)
    local merged_labels
    if [[ -z "$current_labels" ]]; then
        merged_labels="$new_labels"
    else
        # Combine and deduplicate
        local all_labels="${current_labels},${new_labels}"
        IFS=',' read -ra label_array <<< "$all_labels"

        # Deduplicate using associative array
        declare -A seen
        local unique_labels=()
        for label in "${label_array[@]}"; do
            label=$(echo "$label" | xargs)  # trim whitespace
            if [[ -z "${seen[$label]:-}" ]]; then
                seen[$label]=1
                unique_labels+=("$label")
            fi
        done

        # Join back to comma-separated string
        merged_labels=$(IFS=,; echo "${unique_labels[*]}")
    fi

    log_info "Merged labels: $merged_labels"

    # Note: Actual label modification requires runner reconfiguration
    log_warn "Label addition requires runner reconfiguration"
    log_info "To apply labels, you need to reconfigure the runner with --replace flag"
    log_info "Recommended command:"
    echo ""
    echo "  cd $runner_dir"
    echo "  ./config.sh remove --token <TOKEN>"
    echo "  ./config.sh --url https://github.com/<ORG> --token <TOKEN> \\"
    echo "              --name <RUNNER_NAME> --labels \"$merged_labels\" --replace"
    echo ""

    return 0
}

remove_labels() {
    local runner_dir="$1"
    local labels_to_remove="$2"

    log "Removing labels from runner: $runner_dir"
    log_info "Labels to remove: $labels_to_remove"

    # Get current labels
    local current_labels
    current_labels=$(get_current_labels "$runner_dir")

    if [[ -z "$current_labels" ]]; then
        log_warn "No labels currently configured"
        return 0
    fi

    # Convert to arrays
    IFS=',' read -ra current_array <<< "$current_labels"
    IFS=',' read -ra remove_array <<< "$labels_to_remove"

    # Create associative array for labels to remove
    declare -A remove_map
    for label in "${remove_array[@]}"; do
        label=$(echo "$label" | xargs)
        remove_map[$label]=1
    done

    # Filter out labels to remove
    local filtered_labels=()
    for label in "${current_array[@]}"; do
        label=$(echo "$label" | xargs)
        if [[ -z "${remove_map[$label]:-}" ]]; then
            filtered_labels+=("$label")
        fi
    done

    # Join back to comma-separated string
    local new_labels=$(IFS=,; echo "${filtered_labels[*]}")

    log_info "New labels after removal: $new_labels"

    # Note: Actual label modification requires runner reconfiguration
    log_warn "Label removal requires runner reconfiguration"
    log_info "To apply labels, you need to reconfigure the runner with --replace flag"
    log_info "Recommended command:"
    echo ""
    echo "  cd $runner_dir"
    echo "  ./config.sh remove --token <TOKEN>"
    echo "  ./config.sh --url https://github.com/<ORG> --token <TOKEN> \\"
    echo "              --name <RUNNER_NAME> --labels \"$new_labels\" --replace"
    echo ""

    return 0
}

reset_labels() {
    local runner_dir="$1"
    local new_labels="$2"
    local org="$3"
    local token="$4"

    if [[ -z "$org" ]] || [[ -z "$token" ]]; then
        log_error "Organization and token required for label reset"
        log_info "Use: --org <ORG> --token <TOKEN>"
        return 1
    fi

    log "Resetting labels for runner: $runner_dir"
    log_info "New labels: $new_labels"

    # Get runner name
    local runner_name
    runner_name=$(jq -r '.agentName // empty' "$runner_dir/.runner" 2>/dev/null)

    if [[ -z "$runner_name" ]]; then
        log_error "Cannot determine runner name from configuration"
        return 1
    fi

    # Get runner URL
    local runner_url
    runner_url=$(jq -r '.serverUrl // empty' "$runner_dir/.runner" 2>/dev/null)

    if [[ -z "$runner_url" ]]; then
        runner_url="https://github.com/${org}"
    fi

    log "Reconfiguring runner with new labels..."

    cd "$runner_dir" || return 1

    # Stop service if running
    if [[ -f "svc.sh" ]]; then
        if sudo ./svc.sh status &> /dev/null; then
            log_info "Stopping runner service..."
            sudo ./svc.sh stop
            sudo ./svc.sh uninstall
        fi
    fi

    # Reconfigure with new labels
    log_info "Running configuration..."
    if ! ./config.sh --url "$runner_url" --token "$token" \
                     --name "$runner_name" --labels "$new_labels" \
                     --replace --unattended; then
        log_error "Failed to reconfigure runner"
        return 1
    fi

    # Reinstall and start service
    if [[ -f "svc.sh" ]]; then
        log_info "Reinstalling service..."
        sudo ./svc.sh install

        log_info "Starting service..."
        sudo ./svc.sh start
    fi

    log "Labels reset successfully!"
    list_labels "$runner_dir"

    return 0
}

################################################################################
# Preset Management
################################################################################

apply_preset() {
    local preset_name="$1"

    if [[ -z "${LABEL_PRESETS[$preset_name]:-}" ]]; then
        log_error "Unknown preset: $preset_name"
        log_info "Available presets:"
        for preset in "${!LABEL_PRESETS[@]}"; do
            echo "  - $preset: ${LABEL_PRESETS[$preset]}"
        done
        return 1
    fi

    echo "${LABEL_PRESETS[$preset_name]}"
    return 0
}

list_presets() {
    log "Available label presets:"
    echo ""
    for preset in "${!LABEL_PRESETS[@]}"; do
        echo "  $preset:"
        echo "    ${LABEL_PRESETS[$preset]}"
        echo ""
    done
}

################################################################################
# Main Flow
################################################################################

parse_arguments() {
    if [[ $# -eq 0 ]]; then
        show_help
    fi

    while [[ $# -gt 0 ]]; do
        case $1 in
            --runner-id)
                RUNNER_ID="$2"
                shift 2
                ;;
            --action)
                ACTION="$2"
                shift 2
                ;;
            --labels)
                LABELS="$2"
                shift 2
                ;;
            --org)
                GITHUB_ORG="$2"
                shift 2
                ;;
            --token)
                RUNNER_TOKEN="$2"
                shift 2
                ;;
            --preset)
                PRESET="$2"
                shift 2
                ;;
            --help)
                show_help
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                ;;
        esac
    done

    # Validate required arguments
    if [[ -z "$RUNNER_ID" ]]; then
        log_error "Missing required argument: --runner-id"
        show_help
    fi

    if [[ -z "$ACTION" ]]; then
        log_error "Missing required argument: --action"
        show_help
    fi

    # Apply preset if specified
    if [[ -n "$PRESET" ]]; then
        LABELS=$(apply_preset "$PRESET")
        if [[ $? -ne 0 ]]; then
            exit 1
        fi
    fi
}

main() {
    log "==================================================================="
    log "GitHub Actions Runner Label Configuration v${SCRIPT_VERSION}"
    log "==================================================================="

    parse_arguments "$@"

    # Get runner directory
    local runner_dir
    runner_dir=$(get_runner_dir "$RUNNER_ID")

    # Check runner exists
    if ! check_runner_exists "$runner_dir"; then
        exit 1
    fi

    # Execute action
    case "$ACTION" in
        list)
            list_labels "$runner_dir"
            ;;
        validate)
            validate_labels "$runner_dir"
            ;;
        add)
            if [[ -z "$LABELS" ]]; then
                log_error "Labels required for add action. Use --labels or --preset"
                exit 1
            fi
            add_labels "$runner_dir" "$LABELS"
            ;;
        remove)
            if [[ -z "$LABELS" ]]; then
                log_error "Labels required for remove action. Use --labels"
                exit 1
            fi
            remove_labels "$runner_dir" "$LABELS"
            ;;
        reset)
            if [[ -z "$LABELS" ]]; then
                log_error "Labels required for reset action. Use --labels or --preset"
                exit 1
            fi
            reset_labels "$runner_dir" "$LABELS" "$GITHUB_ORG" "$RUNNER_TOKEN"
            ;;
        presets)
            list_presets
            ;;
        *)
            log_error "Unknown action: $ACTION"
            log_info "Valid actions: list, add, remove, reset, validate, presets"
            exit 1
            ;;
    esac

    log "==================================================================="
    log "Label configuration completed"
    log "==================================================================="
}

# Run main function
main "$@"
