#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BIN_DIR="$PROJECT_DIR/bin"

CLOUDFLARED_BIN="$BIN_DIR/cloudflared"

# システムのアーキテクチャに合ったURLを決定
ARCH="$(uname -m)"
case "$ARCH" in
    x86_64)  ARCH_SUFFIX="amd64" ;;
    aarch64) ARCH_SUFFIX="arm64" ;;
    armv7l)  ARCH_SUFFIX="arm" ;;
    *)
        echo "Error: Unsupported architecture: $ARCH" >&2
        exit 1
        ;;
esac
CLOUDFLARED_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH_SUFFIX}"

UPDATE=false
if [ "${1:-}" = "--update" ]; then
    UPDATE=true
fi

if [ -f "$CLOUDFLARED_BIN" ] && [ "$UPDATE" = false ]; then
    echo "cloudflared is already installed at $CLOUDFLARED_BIN"
    "$CLOUDFLARED_BIN" version
    exit 0
fi

if [ "$UPDATE" = true ] && [ -f "$CLOUDFLARED_BIN" ]; then
    echo "Current version:"
    "$CLOUDFLARED_BIN" version
    echo ""
fi

echo "Downloading cloudflared for ${ARCH} (${ARCH_SUFFIX})..."
echo "URL: $CLOUDFLARED_URL"
mkdir -p "$BIN_DIR"
curl -fSL -o "$CLOUDFLARED_BIN" "$CLOUDFLARED_URL"
chmod +x "$CLOUDFLARED_BIN"

# ダウンロードしたファイルがELFバイナリか検証
if ! head -c 4 "$CLOUDFLARED_BIN" | grep -q "^.ELF"; then
    echo "Error: Downloaded file is not a valid ELF binary." >&2
    echo "Content preview:" >&2
    head -c 200 "$CLOUDFLARED_BIN" >&2
    echo "" >&2
    rm -f "$CLOUDFLARED_BIN"
    exit 1
fi

# 実行可能か検証
if ! "$CLOUDFLARED_BIN" version > /dev/null 2>&1; then
    echo "Error: cloudflared binary cannot execute on this system." >&2
    echo "Expected architecture: $(uname -m)" >&2
    file "$CLOUDFLARED_BIN" 2>/dev/null >&2 || true
    rm -f "$CLOUDFLARED_BIN"
    exit 1
fi

echo "Installed:"
"$CLOUDFLARED_BIN" version
