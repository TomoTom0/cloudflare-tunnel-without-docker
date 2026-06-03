#!/usr/bin/env bash
# 共通関数

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CLOUDFLARED_BIN="$PROJECT_DIR/bin/cloudflared"
PID_FILE="$PROJECT_DIR/tmp/cloudflared.pid"
LOG_FILE="$PROJECT_DIR/tmp/cloudflared.log"
ENV_FILE="$PROJECT_DIR/.env"
OS_NAME="$(uname -s)"

# realpath相当のポータブル実装（macOSのreadlinkは-f非対応のため）
resolve_path() {
    local base=""
    local dir="${1%/*}"
    local file="${1##*/}"
    if [ "$dir" = "$1" ]; then
        dir="."
    fi
    base="$(cd "$dir" 2>/dev/null && pwd -P)" || return 1
    echo "$base/$file"
}

# 指定PIDがcloudflaredプロセスかどうか判定
is_cloudflared_process() {
    local pid="$1"
    kill -0 "$pid" 2>/dev/null || return 1

    if [ "$OS_NAME" = "Linux" ]; then
        [ "$(readlink -f /proc/"$pid"/exe 2>/dev/null)" = "$(readlink -f "$CLOUDFLARED_BIN")" ]
    elif [ "$OS_NAME" = "Darwin" ]; then
        local proc_comm
        proc_comm="$(ps -p "$pid" -o comm= 2>/dev/null)" || return 1
        [ "$proc_comm" = "$(resolve_path "$CLOUDFLARED_BIN")" ]
    else
        return 1
    fi
}

# 全cloudflaredプロセスのPIDを探す（Linux: /proc走査、macOS: ps走査）
find_cloudflared_pids() {
    local pid
    if [ "$OS_NAME" = "Linux" ]; then
        for pid_dir in /proc/[0-9]*; do
            pid="${pid_dir##*/}"
            if is_cloudflared_process "$pid" 2>/dev/null; then
                echo "$pid"
            fi
        done
    elif [ "$OS_NAME" = "Darwin" ]; then
        local resolved_bin
        resolved_bin="$(resolve_path "$CLOUDFLARED_BIN")" || return 0
        while IFS= read -r line; do
            pid="${line%% *}"
            local comm="${line#* }"
            if [ "$comm" = "$resolved_bin" ]; then
                echo "$pid"
            fi
        done < <(ps -eo pid,comm 2>/dev/null)
    fi
}
