#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

PID=""

# PIDファイルからPIDを取得
if [ -f "$PID_FILE" ]; then
    PID="$(cat "$PID_FILE")"
    if ! is_cloudflared_process "$PID"; then
        [ -n "$PID" ] && echo "PID $PID is not cloudflared. Cleaning up PID file."
        rm -f "$PID_FILE"
        PID=""
    fi
fi

# PIDファイルにない場合、/procを走査
if [ -z "$PID" ]; then
    PID="$(find_cloudflared_pid || true)"
fi

if [ -z "$PID" ]; then
    echo "cloudflared is not running."
    exit 0
fi

echo "Stopping cloudflared (PID: $PID)..."
kill "$PID"
rm -f "$PID_FILE"
echo "Stopped."
