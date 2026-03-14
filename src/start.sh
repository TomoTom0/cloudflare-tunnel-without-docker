#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CLOUDFLARED_BIN="$PROJECT_DIR/bin/cloudflared"
PID_FILE="$PROJECT_DIR/tmp/cloudflared.pid"
LOG_FILE="$PROJECT_DIR/tmp/cloudflared.log"
ENV_FILE="$PROJECT_DIR/.env"

if [ ! -f "$CLOUDFLARED_BIN" ]; then
    echo "cloudflared not found. Run src/setup.sh first."
    exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
    echo ".env not found. Copy .env.example to .env and set TUNNEL_TOKEN."
    exit 1
fi

source "$ENV_FILE"

if [ -z "${TUNNEL_TOKEN:-}" ]; then
    echo "TUNNEL_TOKEN is not set in .env"
    exit 1
fi

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "cloudflared is already running (PID: $(cat "$PID_FILE"))"
    exit 1
fi

mkdir -p "$PROJECT_DIR/tmp"

echo "Starting cloudflared tunnel..."
nohup "$CLOUDFLARED_BIN" tunnel run --token "$TUNNEL_TOKEN" > "$LOG_FILE" 2>&1 &
echo $! > "$PID_FILE"
echo "cloudflared started (PID: $(cat "$PID_FILE"))"
echo "Log: $LOG_FILE"
