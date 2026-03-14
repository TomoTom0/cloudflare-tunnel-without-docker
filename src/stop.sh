#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

ALL_PIDS=""

# PIDファイルからPIDを取得
if [ -f "$PID_FILE" ]; then
    PID="$(cat "$PID_FILE")"
    if is_cloudflared_process "$PID"; then
        ALL_PIDS="$PID"
    else
        [ -n "$PID" ] && echo "PID $PID is not cloudflared. Cleaning up PID file."
    fi
fi

# /procを走査して追加のプロセスを検出
SCANNED_PIDS="$(find_cloudflared_pids)"
if [ -n "$SCANNED_PIDS" ]; then
    if [ -n "$ALL_PIDS" ]; then
        # PIDファイルのPIDと重複しないものを追加
        while IFS= read -r pid; do
            if [ "$pid" != "$ALL_PIDS" ]; then
                ALL_PIDS="$ALL_PIDS"$'\n'"$pid"
            fi
        done <<< "$SCANNED_PIDS"
    else
        ALL_PIDS="$SCANNED_PIDS"
    fi
fi

if [ -z "$ALL_PIDS" ]; then
    echo "cloudflared is not running."
    rm -f "$PID_FILE"
    exit 0
fi

echo "Stopping cloudflared processes..."
echo "$ALL_PIDS" | while IFS= read -r pid; do
    echo " - Stopping PID $pid"
    kill "$pid"
done

rm -f "$PID_FILE"
echo "Stopped."
