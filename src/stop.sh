#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PID_FILE="$PROJECT_DIR/tmp/cloudflared.pid"

if [ ! -f "$PID_FILE" ]; then
    echo "PID file not found. cloudflared is not running."
    exit 0
fi

PID="$(cat "$PID_FILE")"

if kill -0 "$PID" 2>/dev/null; then
    echo "Stopping cloudflared (PID: $PID)..."
    kill "$PID"
    rm -f "$PID_FILE"
    echo "Stopped."
else
    echo "Process $PID is not running. Cleaning up PID file."
    rm -f "$PID_FILE"
fi
