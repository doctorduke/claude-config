#!/bin/bash
# Fixtures Library
# Provides test data and fixtures

# Create a test Git repository
create_test_repo() {
    local repo_name="${1:-test-repo}"
    local repo_dir="$(mktemp -d)/$repo_name"

    mkdir -p "$repo_dir"
    cd "$repo_dir" || return 1

    git init -q
    git config user.name "Test User"
    git config user.email "test@example.com"

    # Create initial commit
    echo "# Test Repository" > README.md
    git add README.md
    git commit -q -m "Initial commit"

    echo "$repo_dir"
}

# Create a test PR fixture
create_test_pr() {
    local pr_number="${1:-123}"
    local title="${2:-Test Pull Request}"
    local state="${3:-open}"
    local branch="${4:-feature/test}"
    local base="${5:-main}"

    cat << EOF
{
  "number": $pr_number,
  "title": "$title",
  "state": "$state",
  "head": {
    "ref": "$branch",
    "sha": "abc123def456"
  },
  "base": {
    "ref": "$base"
  },
  "user": {
    "login": "testuser"
  },
  "body": "This is a test pull request",
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2025-01-01T00:00:00Z",
  "html_url": "https://github.com/testorg/testrepo/pull/$pr_number"
}
EOF
}

# Create a test issue fixture
create_test_issue() {
    local issue_number="${1:-456}"
    local title="${2:-Test Issue}"
    local state="${3:-open}"
    local labels="${4:-bug}"

    cat << EOF
{
  "number": $issue_number,
  "title": "$title",
  "state": "$state",
  "labels": [
    {"name": "$labels"}
  ],
  "user": {
    "login": "testuser"
  },
  "body": "This is a test issue",
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2025-01-01T00:00:00Z",
  "html_url": "https://github.com/testorg/testrepo/issues/$issue_number"
}
EOF
}

# Create a test workflow run fixture
create_test_workflow_run() {
    local run_id="${1:-789}"
    local status="${2:-completed}"
    local conclusion="${3:-success}"

    cat << EOF
{
  "id": $run_id,
  "status": "$status",
  "conclusion": "$conclusion",
  "workflow_id": 123,
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2025-01-01T00:00:00Z",
  "html_url": "https://github.com/testorg/testrepo/actions/runs/$run_id"
}
EOF
}

# Create test AI response
create_test_ai_response() {
    local content="${1:-This is a test response}"
    local model="${2:-claude-3-5-sonnet-20241022}"

    cat << EOF
{
  "content": [
    {
      "type": "text",
      "text": "$content"
    }
  ],
  "id": "msg_test123",
  "model": "$model",
  "role": "assistant",
  "stop_reason": "end_turn",
  "type": "message",
  "usage": {
    "input_tokens": 10,
    "output_tokens": 20
  }
}
EOF
}

# Create test environment file
create_test_env_file() {
    local env_file="${1:-test.env}"

    cat > "$env_file" << 'EOF'
# Test environment variables
GITHUB_TOKEN=ghp_test123456789
ANTHROPIC_API_KEY=sk-ant-test123456789
OPENAI_API_KEY=sk-test123456789
GITHUB_OWNER=testorg
GITHUB_REPO=testrepo
AI_PROVIDER=anthropic
AI_MODEL=claude-3-5-sonnet-20241022
EOF

    echo "$env_file"
}

# Create test configuration file
create_test_config() {
    local config_file="${1:-test-config.json}"

    cat > "$config_file" << 'EOF'
{
  "ai_provider": "anthropic",
  "ai_model": "claude-3-5-sonnet-20241022",
  "github": {
    "owner": "testorg",
    "repo": "testrepo"
  },
  "runner": {
    "name": "test-runner",
    "labels": ["self-hosted", "test"],
    "work_dir": "/tmp/test-runner"
  },
  "security": {
    "secret_scanning_enabled": true,
    "max_execution_time": 3600
  }
}
EOF

    echo "$config_file"
}

# Create test script file
create_test_script() {
    local script_file="${1:-test-script.sh}"
    local content="${2:-echo 'Test script'}"

    cat > "$script_file" << EOF
#!/bin/bash
$content
EOF

    chmod +x "$script_file"
    echo "$script_file"
}

# Create test log file
create_test_log() {
    local log_file="${1:-test.log}"
    local num_lines="${2:-100}"

    for i in $(seq 1 "$num_lines"); do
        echo "[$(date -Iseconds)] [INFO] Test log entry $i" >> "$log_file"
    done

    echo "$log_file"
}

# Create test webhook payload
create_test_webhook_payload() {
    local event_type="${1:-pull_request}"
    local action="${2:-opened}"

    case "$event_type" in
        pull_request)
            cat << EOF
{
  "action": "$action",
  "number": 123,
  "pull_request": $(create_test_pr),
  "repository": {
    "name": "testrepo",
    "owner": {
      "login": "testorg"
    }
  }
}
EOF
            ;;
        issues)
            cat << EOF
{
  "action": "$action",
  "issue": $(create_test_issue),
  "repository": {
    "name": "testrepo",
    "owner": {
      "login": "testorg"
    }
  }
}
EOF
            ;;
        workflow_run)
            cat << EOF
{
  "action": "$action",
  "workflow_run": $(create_test_workflow_run),
  "repository": {
    "name": "testrepo",
    "owner": {
      "login": "testorg"
    }
  }
}
EOF
            ;;
    esac
}

# Create test runner registration token response
create_test_runner_token() {
    local token="${1:-AABBCCDD123456789}"
    local expires_at="${2:-2025-12-31T23:59:59Z}"

    cat << EOF
{
  "token": "$token",
  "expires_at": "$expires_at"
}
EOF
}

# Create test secrets
create_test_secrets() {
    local secrets_file="${1:-.secrets}"

    cat > "$secrets_file" << 'EOF'
GITHUB_TOKEN=ghp_test123456789abcdef
ANTHROPIC_API_KEY=sk-ant-test123456789abcdef
DATABASE_PASSWORD=test_db_password_123
API_SECRET_KEY=test_api_secret_xyz789
EOF

    echo "$secrets_file"
}

# Create test diff
create_test_diff() {
    cat << 'EOF'
diff --git a/src/main.sh b/src/main.sh
index abc123..def456 100644
--- a/src/main.sh
+++ b/src/main.sh
@@ -10,7 +10,7 @@

 main() {
     echo "Starting application"
-    echo "Version 1.0"
+    echo "Version 2.0"

     # Initialize
     init_app
EOF
}

# Cleanup test data
cleanup_test_data() {
    local pattern="${1:-test-*}"

    # Clean up temporary files
    find /tmp -maxdepth 1 -name "$pattern" -type f -mtime -1 -delete 2>/dev/null || true

    # Clean up temporary directories
    find /tmp -maxdepth 1 -name "$pattern" -type d -mtime -1 -exec rm -rf {} + 2>/dev/null || true

    log_test "DEBUG" "Cleaned up test data matching: $pattern"
}

# Create a complete test environment
create_test_environment() {
    local env_dir="$(mktemp -d)/test-env"

    mkdir -p "$env_dir"/{config,logs,data,scripts}

    # Create test files
    create_test_env_file "$env_dir/config/.env"
    create_test_config "$env_dir/config/config.json"
    create_test_log "$env_dir/logs/app.log" 50

    echo "$env_dir"
}

# Populate test database (if needed)
populate_test_database() {
    local db_file="${1:-test.db}"

    # This is a placeholder - implement based on actual database needs
    log_test "DEBUG" "Populated test database: $db_file"
}

# Create test file with specific content
create_test_file_with_content() {
    local file_path="$1"
    local content="$2"

    mkdir -p "$(dirname "$file_path")"
    echo "$content" > "$file_path"

    echo "$file_path"
}

# Create test directory structure
create_test_directory_structure() {
    local base_dir="${1:-test-project}"

    mkdir -p "$base_dir"/{src,tests,docs,config}
    touch "$base_dir"/src/{main.sh,utils.sh}
    touch "$base_dir"/tests/{test-main.sh,test-utils.sh}
    touch "$base_dir"/docs/README.md
    touch "$base_dir"/config/config.json

    echo "$base_dir"
}

# Export fixture functions
export -f create_test_repo
export -f create_test_pr
export -f create_test_issue
export -f create_test_workflow_run
export -f create_test_ai_response
export -f create_test_env_file
export -f create_test_config
export -f create_test_script
export -f create_test_log
export -f create_test_webhook_payload
export -f create_test_runner_token
export -f create_test_secrets
export -f create_test_diff
export -f cleanup_test_data
export -f create_test_environment
export -f populate_test_database
export -f create_test_file_with_content
export -f create_test_directory_structure
