#!/usr/bin/env bash
# claudemux installer — interactive.
# Sets CLAUDEMUX_DIR in your shell rc, sources wrapper.sh, and prints
# the tmux.conf hook lines for copy-paste.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
MARKER="# claudemux — added by claudemux/install.sh"

confirm() {
  local prompt="$1" default="${2:-Y}" reply
  read -r -p "$prompt [$default]: " reply
  reply=${reply:-$default}
  [[ "$reply" =~ ^[Yy] ]]
}

echo "claudemux installer"
echo ""
echo "Detected claudemux at: $SCRIPT_DIR"
if confirm "Use this path?"; then
  CLAUDEMUX_DIR="$SCRIPT_DIR"
else
  read -r -p "Enter absolute path to claudemux checkout: " CLAUDEMUX_DIR
fi

CLAUDEMUX_DIR="$(cd "$CLAUDEMUX_DIR" 2>/dev/null && pwd -P)" || {
  echo "error: '$CLAUDEMUX_DIR' is not a directory" >&2
  exit 1
}
if [ ! -f "$CLAUDEMUX_DIR/wrapper.sh" ]; then
  echo "error: $CLAUDEMUX_DIR/wrapper.sh not found — not a claudemux checkout?" >&2
  exit 1
fi

echo ""
echo "Installing with CLAUDEMUX_DIR=$CLAUDEMUX_DIR"

case "${SHELL:-}" in
  */zsh)  RC="$HOME/.zshrc" ;;
  */bash) RC="$HOME/.bashrc" ;;
  *)      RC="" ;;
esac

if [ -n "$RC" ]; then
  echo ""
  echo "Shell config: $RC"

  if grep -qF "$MARKER" "$RC" 2>/dev/null; then
    echo "  [skip] claudemux block already present; edit $RC manually to change path"
  elif grep -qE '\. .*claudemux/wrapper\.sh' "$RC" 2>/dev/null; then
    echo "  [warn] existing claudemux source line detected in $RC"
    echo "         remove it manually, then re-run install.sh"
    exit 1
  elif confirm "  Append export + source line to $RC?"; then
    cat >> "$RC" <<EOF

$MARKER
export CLAUDEMUX_DIR="$CLAUDEMUX_DIR"
[ -f "\$CLAUDEMUX_DIR/wrapper.sh" ] && . "\$CLAUDEMUX_DIR/wrapper.sh"
EOF
    echo "  [added] 3 lines appended to $RC — reload with: exec \$SHELL"
  else
    echo "  [skip] not modifying $RC"
  fi
else
  echo ""
  echo "Unknown shell (\$SHELL=${SHELL:-unset}). Add these lines to your shell rc manually:"
  echo ""
  echo "    export CLAUDEMUX_DIR=\"$CLAUDEMUX_DIR\""
  echo "    [ -f \"\$CLAUDEMUX_DIR/wrapper.sh\" ] && . \"\$CLAUDEMUX_DIR/wrapper.sh\""
fi

chmod +x "$CLAUDEMUX_DIR/hooks/"*.sh 2>/dev/null || true

echo ""
echo "For tmux-resurrect integration, add to ~/.tmux.conf (before the tpm run line):"
echo ""
echo "    set -g @resurrect-hook-post-save-all    '$CLAUDEMUX_DIR/hooks/save.sh'"
echo "    set -g @resurrect-hook-post-restore-all '$CLAUDEMUX_DIR/hooks/restore.sh'"
echo ""
echo "Done."
