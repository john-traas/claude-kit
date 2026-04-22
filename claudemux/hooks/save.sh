#!/usr/bin/env bash
# claudemux save hook — tmux-resurrect post-save-all. Wiring line printed by
# claudemux/install.sh (needs an absolute path to this file).

set -euo pipefail

. "$(dirname "$0")/_lib.sh"

mkdir -p "$(dirname "$CLAUDEMUX_TSV")"

tmux list-panes -a -F "$CLAUDEMUX_TSV_FIELDS" \
  | awk -F'\t' -v n="$CLAUDEMUX_TSV_NCOLS" 'NF == n && $n != ""' \
  > "$CLAUDEMUX_TSV"
