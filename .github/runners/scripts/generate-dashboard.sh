#!/bin/bash
#
# Generate Dashboard from Queue Metrics
#
# Creates HTML dashboard and Grafana JSON from historical metrics
#
# Usage:
#   ./generate-dashboard.sh [OPTIONS]
#
# Options:
#   --metrics-dir DIR      Directory containing metrics (default: ./metrics)
#   --output-html FILE     Output HTML dashboard file
#   --output-grafana FILE  Output Grafana JSON dashboard file
#   --days N               Number of days of history to include (default: 7)
#   --help                 Show this help message

set -euo pipefail

# Configuration
METRICS_DIR="${METRICS_DIR:-./metrics}"
OUTPUT_HTML=""
OUTPUT_GRAFANA=""
DAYS=7

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --metrics-dir)
                METRICS_DIR="$2"
                shift 2
                ;;
            --output-html)
                OUTPUT_HTML="$2"
                shift 2
                ;;
            --output-grafana)
                OUTPUT_GRAFANA="$2"
                shift 2
                ;;
            --days)
                DAYS="$2"
                shift 2
                ;;
            --help)
                grep '^#' "$0" | grep -v '#!/bin/bash' | sed 's/^# //' | sed 's/^#//'
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

# Generate HTML dashboard
generate_html_dashboard() {
    local csv_file="$METRICS_DIR/queue-metrics.csv"

    if [[ ! -f "$csv_file" ]]; then
        echo "Error: Metrics CSV file not found: $csv_file" >&2
        exit 1
    fi

    # Get latest metrics
    # Get header to determine column indices
    local header=$(head -1 "$csv_file")
    local timestamp_col=$(echo "$header" | tr ',' '
' | grep -n "^timestamp$" | cut -d: -f1)
    local repo_col=$(echo "$header" | tr ',' '
' | grep -n "^repo$" | cut -d: -f1)
    local pending_col=$(echo "$header" | tr ',' '
' | grep -n "^pending$" | cut -d: -f1)
    local in_progress_col=$(echo "$header" | tr ',' '
' | grep -n "^in_progress$" | cut -d: -f1)
    local available_col=$(echo "$header" | tr ',' '
' | grep -n "^available$" | cut -d: -f1)
    local busy_col=$(echo "$header" | tr ',' '
' | grep -n "^busy$" | cut -d: -f1)
    local offline_col=$(echo "$header" | tr ',' '
' | grep -n "^offline$" | cut -d: -f1)
    local queue_depth_col=$(echo "$header" | tr ',' '
' | grep -n "^queue_depth$" | cut -d: -f1)
    local utilization_col=$(echo "$header" | tr ',' '
' | grep -n "^utilization$" | cut -d: -f1)
    local status_col=$(echo "$header" | tr ',' '
' | grep -n "^status$" | cut -d: -f1)

    # Get latest metrics using header-based column indices
    local latest=$(tail -1 "$csv_file")
    local timestamp=$(echo "$latest" | cut -d',' -f"$timestamp_col")
    local repo=$(echo "$latest" | cut -d',' -f"$repo_col")
    local pending=$(echo "$latest" | cut -d',' -f"$pending_col")
    local in_progress=$(echo "$latest" | cut -d',' -f"$in_progress_col")
    local available=$(echo "$latest" | cut -d',' -f"$available_col")
    local busy=$(echo "$latest" | cut -d',' -f"$busy_col")
    local offline=$(echo "$latest" | cut -d',' -f"$offline_col")
    local queue_depth=$(echo "$latest" | cut -d',' -f"$queue_depth_col")
    local utilization=$(echo "$latest" | cut -d',' -f"$utilization_col")
    local status=$(echo "$latest" | cut -d',' -f"$status_col")

    # Status color
    local status_color="green"
    case $status in
        warning) status_color="orange" ;;
        critical) status_color="red" ;;
    esac

    # Generate historical data for charts (last N days)
    local chart_data=$(tail -n $((DAYS * 288 + 1)) "$csv_file" | tail -n +2 | awk -F',' '{
        print "{\"timestamp\":\"" $1 "\",\"queue_depth\":" $8 ",\"utilization\":" $9 "}"
    }' | paste -sd ',' -)

    cat > "$OUTPUT_HTML" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>GitHub Actions Queue Monitor</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #f5f5f5;
            padding: 20px;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
        }

        header {
            background: white;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }

        h1 {
            font-size: 24px;
            margin-bottom: 10px;
        }

        .status-badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 4px;
            font-size: 12px;
            font-weight: bold;
            text-transform: uppercase;
        }

        .status-healthy { background: #d4edda; color: #155724; }
        .status-warning { background: #fff3cd; color: #856404; }
        .status-critical { background: #f8d7da; color: #721c24; }

        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }

        .card {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }

        .card-title {
            font-size: 14px;
            color: #666;
            margin-bottom: 8px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }

        .card-value {
            font-size: 32px;
            font-weight: bold;
            color: #333;
        }

        .card-subtitle {
            font-size: 12px;
            color: #999;
            margin-top: 4px;
        }

        .chart-container {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            margin-bottom: 20px;
        }

        .chart-title {
            font-size: 18px;
            margin-bottom: 15px;
        }

        .timestamp {
            color: #666;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>GitHub Actions Queue Monitor</h1>
            <div class="timestamp">Last updated: $timestamp</div>
            <div style="margin-top: 10px;">
                <span class="status-badge status-$status">$status</span>
            </div>
        </header>

        <div class="grid">
            <div class="card">
                <div class="card-title">Queue Depth</div>
                <div class="card-value" style="color: $status_color;">$queue_depth</div>
                <div class="card-subtitle">Pending workflows</div>
            </div>

            <div class="card">
                <div class="card-title">Utilization</div>
                <div class="card-value" style="color: $status_color;">$utilization%</div>
                <div class="card-subtitle">Runner capacity used</div>
            </div>

            <div class="card">
                <div class="card-title">Available Runners</div>
                <div class="card-value">$available</div>
                <div class="card-subtitle">Ready to accept jobs</div>
            </div>

            <div class="card">
                <div class="card-title">Busy Runners</div>
                <div class="card-value">$busy</div>
                <div class="card-subtitle">Currently executing jobs</div>
            </div>
        </div>

        <div class="chart-container">
            <div class="chart-title">Queue Depth (Last $DAYS Days)</div>
            <canvas id="queueDepthChart"></canvas>
        </div>

        <div class="chart-container">
            <div class="chart-title">Runner Utilization (Last $DAYS Days)</div>
            <canvas id="utilizationChart"></canvas>
        </div>
    </div>

    <script>
        const data = [$chart_data];

        // Queue Depth Chart
        new Chart(document.getElementById('queueDepthChart'), {
            type: 'line',
            data: {
                labels: data.map(d => new Date(d.timestamp).toLocaleString()),
                datasets: [{
                    label: 'Queue Depth',
                    data: data.map(d => d.queue_depth),
                    borderColor: 'rgb(75, 192, 192)',
                    backgroundColor: 'rgba(75, 192, 192, 0.1)',
                    tension: 0.4,
                    fill: true
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: { display: false }
                },
                scales: {
                    y: { beginAtZero: true }
                }
            }
        });

        // Utilization Chart
        new Chart(document.getElementById('utilizationChart'), {
            type: 'line',
            data: {
                labels: data.map(d => new Date(d.timestamp).toLocaleString()),
                datasets: [{
                    label: 'Utilization %',
                    data: data.map(d => d.utilization),
                    borderColor: 'rgb(255, 99, 132)',
                    backgroundColor: 'rgba(255, 99, 132, 0.1)',
                    tension: 0.4,
                    fill: true
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: { display: false }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        max: 100
                    }
                }
            }
        });
    </script>
</body>
</html>
EOF

    echo "HTML dashboard generated: $OUTPUT_HTML"
}

# Generate Grafana JSON dashboard
generate_grafana_dashboard() {
    cat > "$OUTPUT_GRAFANA" <<'EOF'
{
  "dashboard": {
    "title": "GitHub Actions Queue Monitor",
    "tags": ["github-actions", "queue", "runners"],
    "timezone": "utc",
    "panels": [
      {
        "id": 1,
        "title": "Queue Depth",
        "type": "graph",
        "gridPos": {"x": 0, "y": 0, "w": 12, "h": 8},
        "targets": [
          {
            "expr": "github_actions_queue_depth",
            "legendFormat": "Queue Depth"
          }
        ],
        "yaxes": [
          {"label": "Workflows", "min": 0},
          {"show": false}
        ]
      },
      {
        "id": 2,
        "title": "Runner Utilization",
        "type": "graph",
        "gridPos": {"x": 12, "y": 0, "w": 12, "h": 8},
        "targets": [
          {
            "expr": "github_actions_runner_utilization",
            "legendFormat": "Utilization %"
          }
        ],
        "yaxes": [
          {"label": "Percent", "min": 0, "max": 100},
          {"show": false}
        ]
      },
      {
        "id": 3,
        "title": "Workflows",
        "type": "graph",
        "gridPos": {"x": 0, "y": 8, "w": 12, "h": 8},
        "targets": [
          {
            "expr": "github_actions_workflows_pending",
            "legendFormat": "Pending"
          },
          {
            "expr": "github_actions_workflows_in_progress",
            "legendFormat": "In Progress"
          }
        ],
        "yaxes": [
          {"label": "Workflows", "min": 0},
          {"show": false}
        ]
      },
      {
        "id": 4,
        "title": "Runners",
        "type": "graph",
        "gridPos": {"x": 12, "y": 8, "w": 12, "h": 8},
        "targets": [
          {
            "expr": "github_actions_runners_available",
            "legendFormat": "Available"
          },
          {
            "expr": "github_actions_runners_busy",
            "legendFormat": "Busy"
          },
          {
            "expr": "github_actions_runners_offline",
            "legendFormat": "Offline"
          }
        ],
        "yaxes": [
          {"label": "Runners", "min": 0},
          {"show": false}
        ]
      },
      {
        "id": 5,
        "title": "Wait Times",
        "type": "graph",
        "gridPos": {"x": 0, "y": 16, "w": 24, "h": 8},
        "targets": [
          {
            "expr": "github_actions_max_wait_time_seconds",
            "legendFormat": "Max Wait Time"
          },
          {
            "expr": "github_actions_avg_wait_time_seconds",
            "legendFormat": "Avg Wait Time"
          }
        ],
        "yaxes": [
          {"label": "Seconds", "min": 0},
          {"show": false}
        ]
      }
    ],
    "refresh": "5m",
    "time": {"from": "now-7d", "to": "now"}
  }
}
EOF

    echo "Grafana dashboard generated: $OUTPUT_GRAFANA"
}

# Main function
main() {
    parse_args "$@"

    if [[ -z "$OUTPUT_HTML" ]] && [[ -z "$OUTPUT_GRAFANA" ]]; then
        echo "Error: No output file specified" >&2
        echo "Use --output-html FILE or --output-grafana FILE" >&2
        exit 1
    fi

    if [[ ! -d "$METRICS_DIR" ]]; then
        echo "Error: Metrics directory not found: $METRICS_DIR" >&2
        exit 1
    fi

    if [[ -n "$OUTPUT_HTML" ]]; then
        generate_html_dashboard
    fi

    if [[ -n "$OUTPUT_GRAFANA" ]]; then
        generate_grafana_dashboard
    fi
}

# Run main function
main "$@"
