#!/usr/bin/env bash
# claudemux restore hook — tmux-resurrect post-restore-all. Wiring line
# printed by claudemux/install.sh (needs an absolute path to this file).

set -uo pipefail

. "$(dirname "$0")/_lib.sh"

[ -f "$CLAUDEMUX_TSV" ] || exit 0

# \x1f (unit separator) never appears in paths, safe as a field delimiter.
US=$'\x1f'

while IFS=$'\t' read -r sess win pane cwd uuid; do
  [ -z "$uuid" ] && continue
  target="${sess}:${win}.${pane}"

  # One tmux call fetches both pane_id (existence probe) and current path.
  info=$(pane_fmt "$target" "#{pane_id}${US}#{pane_current_path}") || continue
  [ -z "$info" ] && continue
  actual_cwd=${info#*$US}

  tmux set-option -pq -t "$target" @claude-session "$uuid"

  # Guard against cwd drift — resume is cwd-scoped and fails silently otherwise.
  if [ "$actual_cwd" != "$cwd" ]; then
    echo "claudemux: skipped ${target} (cwd drift: ${actual_cwd} != ${cwd})" >&2
    continue
  fi

  tmux send-keys -t "$target" "claude" Enter
done < "$CLAUDEMUX_TSV"
