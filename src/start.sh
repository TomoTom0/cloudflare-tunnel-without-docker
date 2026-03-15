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
export TUNNEL_TOKEN

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
EXISTING_PIDS="$(find_cloudflared_pids)"
if [ -n "$EXISTING_PIDS" ]; then
    echo "cloudflared is already running but PID file was missing. Found PIDs:" >&2
    echo "$EXISTING_PIDS" >&2
    echo "Please run stop.sh to clean up before starting." >&2
    exit 1
fi

mkdir -p "$PROJECT_DIR/tmp"

echo "Starting cloudflared tunnel..."
nohup "$CLOUDFLARED_BIN" tunnel run > "$LOG_FILE" 2>&1 &
echo $! > "$PID_FILE"
PID="$(cat "$PID_FILE")"

# 起動直後のクラッシュを検知
sleep 2
if ! is_cloudflared_process "$PID" 2>/dev/null; then
    echo "cloudflared failed to start. Log output:" >&2
    cat "$LOG_FILE" >&2
    rm -f "$PID_FILE"
    exit 1
fi

echo "cloudflared started (PID: $PID)"
echo "Log: $LOG_FILE"
echo ""
echo "--- Recent log ---"
tail -5 "$LOG_FILE"
