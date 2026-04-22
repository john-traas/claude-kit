#!/usr/bin/env bash
# claudex-lite installer — symlinks the executables into ~/.local/bin/
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd -P)"
BIN_DIR="$HOME/.local/bin"

mkdir -p "$BIN_DIR"
ln -sf "$SCRIPT_DIR/claudex-lite" "$BIN_DIR/claudex-lite"
ln -sf "$REPO_DIR/cx" "$BIN_DIR/cx"

echo "claudex-lite installed: $BIN_DIR/claudex-lite -> $SCRIPT_DIR/claudex-lite"
echo "cx installed:           $BIN_DIR/cx -> $REPO_DIR/cx"

if ! command -v claudex-lite >/dev/null 2>&1; then
  echo ""
  echo "Add to your shell rc to put ~/.local/bin on PATH:"
  echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
fi
