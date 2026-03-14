#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

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

# PIDファイルのプロセスを確認
if [ -f "$PID_FILE" ]; then
    OLD_PID="$(cat "$PID_FILE")"
    if is_cloudflared_process "$OLD_PID"; then
        echo "cloudflared is already running (PID: $OLD_PID)"
        exit 1
    fi
    rm -f "$PID_FILE"
fi

# PIDファイルがなくてもプロセスが存在する場合を検出
EXISTING_PID="$(find_cloudflared_pid || true)"
if [ -n "$EXISTING_PID" ]; then
    echo "cloudflared is already running (PID: $EXISTING_PID) but PID file was missing. Recreating."
    mkdir -p "$PROJECT_DIR/tmp"
    echo "$EXISTING_PID" > "$PID_FILE"
    exit 1
fi

mkdir -p "$PROJECT_DIR/tmp"

echo "Starting cloudflared tunnel..."
nohup "$CLOUDFLARED_BIN" tunnel run --token "$TUNNEL_TOKEN" > "$LOG_FILE" 2>&1 &
echo $! > "$PID_FILE"
echo "cloudflared started (PID: $(cat "$PID_FILE"))"
echo "Log: $LOG_FILE"
