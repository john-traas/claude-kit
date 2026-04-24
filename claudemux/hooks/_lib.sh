# claudemux hooks shared definitions — sourced by save.sh and restore.sh.
# Defines the TSV path and column contract so both hooks can't drift.

CLAUDEMUX_TSV="${CLAUDEMUX_TSV:-${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect/claude-sessions.tsv}"

# Column order — part of the save/restore contract.
CLAUDEMUX_TSV_FIELDS='#{session_name}	#{window_index}	#{pane_index}	#{pane_current_path}	#{@claude-session}'
CLAUDEMUX_TSV_NCOLS=5

# pane_fmt <target> <format> — print format value, empty on failure.
pane_fmt() {
  tmux display-message -pt "$1" -p "$2" 2>/dev/null
}
