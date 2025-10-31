#!/usr/bin/env bash
# Script: circuit_breaker.sh
# Description: Circuit breaker pattern implementation to prevent cascading failures
# Usage: source "${SCRIPT_DIR}/lib/circuit_breaker.sh"
#
# Circuit Breaker States:
# - CLOSED: Normal operation, requests flow through
# - OPEN: Circuit is open, requests fail fast without attempting
# - HALF_OPEN: Testing if service recovered, limited requests allowed
#
# Configuration (via environment variables):
# - CB_FAILURE_THRESHOLD: Number of failures before opening circuit (default: 5)
# - CB_TIMEOUT: Seconds circuit stays open before attempting HALF_OPEN (default: 60)
# - CB_HALF_OPEN_TIMEOUT: Seconds to test in HALF_OPEN state (default: 30)
# - CB_SUCCESS_THRESHOLD: Consecutive successes needed to close from HALF_OPEN (default: 2)
# - CB_STATE_DIR: Directory for circuit breaker state files (default: ${TMPDIR:-/tmp}/circuit_breakers)

# Prevent double sourcing
[[ -n "${_CIRCUIT_BREAKER_LOADED:-}" ]] && return 0
readonly _CIRCUIT_BREAKER_LOADED=1

set -euo pipefail

# Configuration defaults (use environment variables if set)
: "${CB_FAILURE_THRESHOLD:=5}"
: "${CB_TIMEOUT:=60}"
: "${CB_HALF_OPEN_TIMEOUT:=30}"
: "${CB_SUCCESS_THRESHOLD:=2}"
: "${CB_STATE_DIR:=${TMPDIR:-/tmp}/circuit_breakers}"

# Circuit breaker states
readonly CB_STATE_CLOSED="CLOSED"
readonly CB_STATE_OPEN="OPEN"
readonly CB_STATE_HALF_OPEN="HALF_OPEN"

# Ensure state directory exists
mkdir -p "${CB_STATE_DIR}"

# Generate circuit breaker state file path
_get_cb_state_file() {
    local endpoint="$1"
    # Sanitize endpoint name for use as filename
    local safe_name
    safe_name=$(echo "${endpoint}" | sed 's|[^a-zA-Z0-9_-]|_|g')
    echo "${CB_STATE_DIR}/${safe_name}.state"
}

# Get lock file for circuit breaker
_get_cb_lock_file() {
    local state_file="$1"
    echo "${state_file}.lock"
}

# Acquire lock with timeout
_acquire_lock() {
    local lock_file="$1"
    local timeout="${2:-5}"
    local elapsed=0

    while [[ ${elapsed} -lt ${timeout} ]]; do
        if mkdir "${lock_file}" 2>/dev/null; then
            return 0
        fi
        sleep 0.1
        elapsed=$((elapsed + 1))
    done

    return 1
}

# Release lock
_release_lock() {
    local lock_file="$1"
    rmdir "${lock_file}" 2>/dev/null || true
}

# Initialize circuit breaker state file
_init_state_file() {
    local state_file="$1"
    local failure_threshold="${2:-${CB_FAILURE_THRESHOLD}}"
    local timeout="${3:-${CB_TIMEOUT}}"

    cat > "${state_file}" <<EOF
STATE=${CB_STATE_CLOSED}
FAILURE_COUNT=0
SUCCESS_COUNT=0
FAILURE_THRESHOLD=${failure_threshold}
TIMEOUT=${timeout}
OPEN_TIME=0
HALF_OPEN_TIME=0
EOF
}

# Read circuit breaker state
_read_state() {
    local state_file="$1"

    if [[ ! -f "${state_file}" ]]; then
        return 1
    fi

    # Source the state file to load variables
    source "${state_file}"
}

# Write circuit breaker state
_write_state() {
    local state_file="$1"
    local state="$2"
    local failure_count="$3"
    local success_count="$4"
    local open_time="${5:-0}"
    local half_open_time="${6:-0}"

    cat > "${state_file}" <<EOF
STATE=${state}
FAILURE_COUNT=${failure_count}
SUCCESS_COUNT=${success_count}
FAILURE_THRESHOLD=${FAILURE_THRESHOLD:-${CB_FAILURE_THRESHOLD}}
TIMEOUT=${TIMEOUT:-${CB_TIMEOUT}}
LAST_FAILURE_TIME=${last_failure_time}
OPEN_TIME=${open_time}
HALF_OPEN_TIME=${half_open_time}
EOF
}

# Initialize circuit breaker for endpoint
# Usage: init_circuit_breaker "endpoint_name" [failure_threshold] [timeout]
init_circuit_breaker() {
    local endpoint="$1"
    local failure_threshold="${2:-${CB_FAILURE_THRESHOLD}}"
    local timeout="${3:-${CB_TIMEOUT}}"

    local state_file
    state_file=$(_get_cb_state_file "${endpoint}")

    local lock_file
    lock_file=$(_get_cb_lock_file "${state_file}")

    if _acquire_lock "${lock_file}"; then
        if [[ ! -f "${state_file}" ]]; then
            _init_state_file "${state_file}" "${failure_threshold}" "${timeout}"
            [[ "${CURRENT_LOG_LEVEL:-1}" -le 0 ]] && echo "[DEBUG] Circuit breaker initialized for ${endpoint}" >&2
        fi
        _release_lock "${lock_file}"
    else
        [[ "${CURRENT_LOG_LEVEL:-1}" -le 2 ]] && echo "[WARN] Could not acquire lock for ${endpoint} initialization" >&2
    fi
}

# Get current circuit breaker state
# Usage: get_circuit_state "endpoint_name"
# Returns: CLOSED, OPEN, or HALF_OPEN
get_circuit_state() {
    local endpoint="$1"

    local state_file
    state_file=$(_get_cb_state_file "${endpoint}")

    if [[ ! -f "${state_file}" ]]; then
        echo "${CB_STATE_CLOSED}"
        return 0
    fi

    local lock_file
    lock_file=$(_get_cb_lock_file "${state_file}")

    if _acquire_lock "${lock_file}"; then
        _read_state "${state_file}"
        local current_state="${STATE}"
        local open_time="${OPEN_TIME}"
        local half_open_time="${HALF_OPEN_TIME}"
        local timeout="${TIMEOUT:-${CB_TIMEOUT}}"
        _release_lock "${lock_file}"

        local current_time
        current_time=$(date +%s)

        # Check if circuit should transition from OPEN to HALF_OPEN
        if [[ "${current_state}" == "${CB_STATE_OPEN}" ]]; then
            local elapsed=$((current_time - open_time))
            if [[ ${elapsed} -ge ${timeout} ]]; then
                echo "${CB_STATE_HALF_OPEN}"
                return 0
            fi
        fi

        # Check if circuit should transition from HALF_OPEN to OPEN (timeout expired)
        if [[ "${current_state}" == "${CB_STATE_HALF_OPEN}" ]]; then
            local elapsed=$((current_time - half_open_time))
            if [[ ${elapsed} -ge ${CB_HALF_OPEN_TIMEOUT} ]]; then
                echo "${CB_STATE_OPEN}"
                return 0
            fi
        fi

        echo "${current_state}"
    else
        [[ "${CURRENT_LOG_LEVEL:-1}" -le 2 ]] && echo "[WARN] Could not acquire lock for ${endpoint} state check" >&2
        echo "${CB_STATE_CLOSED}"
    fi
}

# Check if circuit is open (should fail fast)
# Usage: is_circuit_open "endpoint_name"
# Returns: 0 if OPEN, 1 if CLOSED or HALF_OPEN
is_circuit_open() {
    local endpoint="$1"
    local state
    state=$(get_circuit_state "${endpoint}")

    if [[ "${state}" == "${CB_STATE_OPEN}" ]]; then
        return 0
    else
        return 1
    fi
}

# Record a failure
# Usage: record_failure "endpoint_name"
record_failure() {
    local endpoint="$1"

    local state_file
    state_file=$(_get_cb_state_file "${endpoint}")

    if [[ ! -f "${state_file}" ]]; then
        init_circuit_breaker "${endpoint}"
    fi

    local lock_file
    lock_file=$(_get_cb_lock_file "${state_file}")

    if _acquire_lock "${lock_file}"; then
        _read_state "${state_file}"

        local current_time
        current_time=$(date +%s)

        local new_failure_count=$((FAILURE_COUNT + 1))
        local new_success_count=0  # Reset success count on failure
        local new_state="${STATE}"
        local new_open_time="${OPEN_TIME}"
        local new_half_open_time="${HALF_OPEN_TIME}"

        # Check if we should transition from OPEN to HALF_OPEN first
        if [[ "${STATE}" == "${CB_STATE_OPEN}" ]]; then
            local elapsed=$((current_time - OPEN_TIME))
            if [[ ${elapsed} -ge ${TIMEOUT} ]]; then
                new_state="${CB_STATE_HALF_OPEN}"
                new_half_open_time="${current_time}"
                [[ "${CURRENT_LOG_LEVEL:-1}" -le 1 ]] && echo "[INFO] Circuit breaker transitioning to HALF_OPEN for ${endpoint}" >&2
            fi
        fi

        # Check current state and determine transition
        case "${new_state}" in
            "${CB_STATE_CLOSED}")
                if [[ ${new_failure_count} -ge ${FAILURE_THRESHOLD} ]]; then
                    new_state="${CB_STATE_OPEN}"
                    new_open_time="${current_time}"
                    [[ "${CURRENT_LOG_LEVEL:-1}" -le 2 ]] && echo "[WARN] Circuit breaker opened for ${endpoint} (${new_failure_count} failures)" >&2
                fi
                ;;
            "${CB_STATE_HALF_OPEN}")
                # Failure in HALF_OPEN immediately returns to OPEN
                new_state="${CB_STATE_OPEN}"
                new_open_time="${current_time}"
                new_half_open_time=0
                [[ "${CURRENT_LOG_LEVEL:-1}" -le 2 ]] && echo "[WARN] Circuit breaker reopened for ${endpoint} (failure in HALF_OPEN)" >&2
                ;;
            "${CB_STATE_OPEN}")
                # Already open, just update failure count
                ;;
        esac

        _write_state "${state_file}" "${new_state}" "${new_failure_count}" "${new_success_count}" \
                     "${current_time}" "${new_open_time}" "${new_half_open_time}"

        _release_lock "${lock_file}"
    else
        [[ "${CURRENT_LOG_LEVEL:-1}" -le 2 ]] && echo "[WARN] Could not acquire lock for ${endpoint} failure recording" >&2
    fi
}

# Record a success
# Usage: record_success "endpoint_name"
record_success() {
    local endpoint="$1"

    local state_file
    state_file=$(_get_cb_state_file "${endpoint}")

    if [[ ! -f "${state_file}" ]]; then
        init_circuit_breaker "${endpoint}"
        return 0
    fi

    local lock_file
    lock_file=$(_get_cb_lock_file "${state_file}")

    if _acquire_lock "${lock_file}"; then
        _read_state "${state_file}"

        local current_time
        current_time=$(date +%s)

        local new_failure_count=0  # Reset failure count on success
        local new_success_count=$((SUCCESS_COUNT + 1))
        local new_state="${STATE}"
        local new_open_time="${OPEN_TIME}"
        local new_half_open_time="${HALF_OPEN_TIME}"

        # Check if we should transition from OPEN to HALF_OPEN first
        if [[ "${STATE}" == "${CB_STATE_OPEN}" ]]; then
            local elapsed=$((current_time - OPEN_TIME))
            if [[ ${elapsed} -ge ${TIMEOUT} ]]; then
                new_state="${CB_STATE_HALF_OPEN}"
                new_half_open_time="${current_time}"
                new_success_count=1
                [[ "${CURRENT_LOG_LEVEL:-1}" -le 1 ]] && echo "[INFO] Circuit breaker transitioning to HALF_OPEN for ${endpoint}" >&2
            fi
        fi

        # Check current state and determine transition
        case "${new_state}" in
            "${CB_STATE_CLOSED}")
                # Already closed, just reset counters
                ;;
            "${CB_STATE_OPEN}")
                # Still open, cannot record success
                ;;
            "${CB_STATE_HALF_OPEN}")
                # Check if we have enough successes to close
                if [[ ${new_success_count} -ge ${CB_SUCCESS_THRESHOLD} ]]; then
                    new_state="${CB_STATE_CLOSED}"
                    new_success_count=0
                    new_open_time=0
                    new_half_open_time=0
                    [[ "${CURRENT_LOG_LEVEL:-1}" -le 1 ]] && echo "[INFO] Circuit breaker closed for ${endpoint} (service recovered)" >&2
                fi
                ;;
        esac

        _write_state "${state_file}" "${new_state}" "${new_failure_count}" "${new_success_count}" \
                     "0" "${new_open_time}" "${new_half_open_time}"

        _release_lock "${lock_file}"
    else
        [[ "${CURRENT_LOG_LEVEL:-1}" -le 2 ]] && echo "[WARN] Could not acquire lock for ${endpoint} success recording" >&2
    fi
}

# Reset circuit breaker (for testing or manual recovery)
# Usage: reset_circuit_breaker "endpoint_name"
reset_circuit_breaker() {
    local endpoint="$1"

    local state_file
    state_file=$(_get_cb_state_file "${endpoint}")

    local lock_file
    lock_file=$(_get_cb_lock_file "${state_file}")

    if _acquire_lock "${lock_file}"; then
        if [[ -f "${state_file}" ]]; then
            _read_state "${state_file}"
            _init_state_file "${state_file}" "${FAILURE_THRESHOLD:-${CB_FAILURE_THRESHOLD}}" "${TIMEOUT:-${CB_TIMEOUT}}"
            [[ "${CURRENT_LOG_LEVEL:-1}" -le 1 ]] && echo "[INFO] Circuit breaker reset for ${endpoint}" >&2
        fi
        _release_lock "${lock_file}"
    else
        [[ "${CURRENT_LOG_LEVEL:-1}" -le 2 ]] && echo "[WARN] Could not acquire lock for ${endpoint} reset" >&2
    fi
}

# Get circuit breaker statistics
# Usage: get_circuit_stats "endpoint_name"
get_circuit_stats() {
    local endpoint="$1"

    local state_file
    state_file=$(_get_cb_state_file "${endpoint}")

    if [[ ! -f "${state_file}" ]]; then
        echo "Circuit breaker not initialized for ${endpoint}"
        return 1
    fi

    local lock_file
    lock_file=$(_get_cb_lock_file "${state_file}")

    if _acquire_lock "${lock_file}"; then
        _read_state "${state_file}"

        local current_time
        current_time=$(date +%s)

        echo "Endpoint: ${endpoint}"
        echo "State: ${STATE}"
        echo "Failure Count: ${FAILURE_COUNT}"
        echo "Success Count: ${SUCCESS_COUNT}"
        echo "Failure Threshold: ${FAILURE_THRESHOLD}"
        echo "Timeout: ${TIMEOUT}s"

        if [[ "${STATE}" == "${CB_STATE_OPEN}" ]]; then
            local elapsed=$((current_time - OPEN_TIME))
            local remaining=$((TIMEOUT - elapsed))
            echo "Time in OPEN state: ${elapsed}s"
            echo "Time until HALF_OPEN: ${remaining}s"
        fi

        if [[ "${STATE}" == "${CB_STATE_HALF_OPEN}" ]]; then
            local elapsed=$((current_time - HALF_OPEN_TIME))
            echo "Time in HALF_OPEN state: ${elapsed}s"
        fi

        _release_lock "${lock_file}"
    else
        echo "Could not acquire lock for ${endpoint} stats"
        return 1
    fi
}

# Export functions
export -f init_circuit_breaker get_circuit_state is_circuit_open
export -f record_failure record_success reset_circuit_breaker get_circuit_stats
