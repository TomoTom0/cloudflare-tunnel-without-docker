#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BIN_DIR="$PROJECT_DIR/bin"

CLOUDFLARED_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"
CLOUDFLARED_BIN="$BIN_DIR/cloudflared"

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

echo "Downloading cloudflared..."
mkdir -p "$BIN_DIR"
curl -fSL -o "$CLOUDFLARED_BIN" "$CLOUDFLARED_URL"
chmod +x "$CLOUDFLARED_BIN"

echo "Installed:"
"$CLOUDFLARED_BIN" version
