# claude-kit

A small collection of tools for working with Claude Code more comfortably.

## Tools

### [claudemux](claudemux/README.md)

Per-pane Claude Code session restore for tmux-resurrect. Each tmux pane
survives save/restore cycles (and Claude Code updates) with its own
session UUID intact.

## Planned

- **claudex** — an Ink-based session management workbench for Claude Code
  sessions. Complements Claude Code's built-in resume picker with things it
  deliberately doesn't do: rename, delete, tag, cross-session search, and
  bulk operations. Not yet shipped.
