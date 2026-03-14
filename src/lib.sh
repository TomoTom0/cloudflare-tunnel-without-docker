#!/usr/bin/env bash
# 共通関数

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CLOUDFLARED_BIN="$PROJECT_DIR/bin/cloudflared"
PID_FILE="$PROJECT_DIR/tmp/cloudflared.pid"
LOG_FILE="$PROJECT_DIR/tmp/cloudflared.log"
ENV_FILE="$PROJECT_DIR/.env"

# 指定PIDがcloudflaredプロセスかどうか判定
is_cloudflared_process() {
    local pid="$1"
    kill -0 "$pid" 2>/dev/null || return 1
    [ "$(readlink -f /proc/"$pid"/exe 2>/dev/null)" = "$(readlink -f "$CLOUDFLARED_BIN")" ]
}

# /procを走査してcloudflaredの全PIDを探す
find_cloudflared_pids() {
    local pid
    for pid_dir in /proc/[0-9]*; do
        pid="${pid_dir##*/}"
        if is_cloudflared_process "$pid" 2>/dev/null; then
            echo "$pid"
        fi
    done
}
