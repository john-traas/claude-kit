# claudemux — per-pane Claude session pinning for tmux-resurrect.
# Sourced as a shell function (bash/zsh); `claude` resolves through this wrapper.
# Outside tmux: passthrough. Install via claudemux/install.sh.

claude() {
  if [ -z "${TMUX_PANE:-}" ]; then
    command claude "$@"
    return
  fi

  # Honor explicit session flags from the user — don't double up.
  for arg in "$@"; do
    case "$arg" in
      --session-id|--resume|-r|--continue|-c|--fork-session|--from-pr)
        command claude "$@"
        return
        ;;
    esac
  done

  local uuid
  uuid=$(tmux show-option -pqv -t "$TMUX_PANE" @claude-session 2>/dev/null)
  if [ -z "$uuid" ]; then
    uuid=$(uuidgen | tr '[:upper:]' '[:lower:]')
    tmux set-option -pq -t "$TMUX_PANE" @claude-session "$uuid"
  fi

  # Claude encodes session file paths as realpath with / and . → -.
  # Mirror that here to locate the existing file for --resume-vs-new branching.
  local real_cwd encoded session_file
  real_cwd=$(pwd -P)
  encoded=${real_cwd//\//-}
  encoded=${encoded//./-}
  session_file="${HOME}/.claude/projects/${encoded}/${uuid}.jsonl"

  # Benign TOCTOU: only this pane writes $session_file; the check-then-branch
  # race isn't observable in a single-user workflow. `claude --resume <missing>`
  # and `claude --session-id <existing>` both error, so the branch is load-bearing.
  if [ -f "$session_file" ]; then
    command claude --resume "$uuid" "$@"
  else
    command claude --session-id "$uuid" "$@"
  fi
}

# Escape hatch: start a fresh session in the current pane.
claudemux-reset() {
  if [ -z "${TMUX_PANE:-}" ]; then
    echo "claudemux-reset: not in a tmux pane" >&2
    return 1
  fi
  tmux set-option -pu -t "$TMUX_PANE" @claude-session
  echo "claudemux: cleared session tag on ${TMUX_PANE}"
}
