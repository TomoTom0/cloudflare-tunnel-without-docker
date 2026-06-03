#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BIN_DIR="$PROJECT_DIR/bin"

CLOUDFLARED_BIN="$BIN_DIR/cloudflared"

OS_NAME="$(uname -s)"
ARCH="$(uname -m)"

case "$ARCH" in
    x86_64)       ARCH_SUFFIX="amd64" ;;
    aarch64|arm64) ARCH_SUFFIX="arm64" ;;
    armv7l)       ARCH_SUFFIX="arm" ;;
    *)
        echo "Error: Unsupported architecture: $ARCH" >&2
        exit 1
        ;;
esac

case "$OS_NAME" in
    Linux)  OS_SUFFIX="linux" ;;
    Darwin) OS_SUFFIX="darwin" ;;
    *)
        echo "Error: Unsupported OS: $OS_NAME" >&2
        exit 1
        ;;
esac

CLOUDFLARED_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-${OS_SUFFIX}-${ARCH_SUFFIX}"

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

echo "Downloading cloudflared for ${OS_NAME} ${ARCH} (${ARCH_SUFFIX})..."
mkdir -p "$BIN_DIR"

if [ "$OS_NAME" = "Darwin" ]; then
    CLOUDFLARED_URL="${CLOUDFLARED_URL}.tgz"
fi

echo "URL: $CLOUDFLARED_URL"

if [ "$OS_NAME" = "Darwin" ]; then
    curl -fSL "$CLOUDFLARED_URL" | tar xz -C "$BIN_DIR"
else
    curl -fSL -o "$CLOUDFLARED_BIN" "$CLOUDFLARED_URL"
fi

chmod +x "$CLOUDFLARED_BIN"

# ダウンロードしたファイルが正しいバイナリ形式か検証
if [ "$OS_NAME" = "Linux" ]; then
    if ! file "$CLOUDFLARED_BIN" | grep -q 'ELF.*executable'; then
        echo "Error: Downloaded file is not a valid ELF binary." >&2
        echo "Content preview:" >&2
        head -c 200 "$CLOUDFLARED_BIN" >&2
        echo "" >&2
        rm -f "$CLOUDFLARED_BIN"
        exit 1
    fi
elif [ "$OS_NAME" = "Darwin" ]; then
    if ! file "$CLOUDFLARED_BIN" | grep -q 'Mach-O.*executable'; then
        echo "Error: Downloaded file is not a valid Mach-O binary." >&2
        echo "Content preview:" >&2
        head -c 200 "$CLOUDFLARED_BIN" >&2
        echo "" >&2
        rm -f "$CLOUDFLARED_BIN"
        exit 1
    fi
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
