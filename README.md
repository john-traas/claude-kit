# claude-kit

A small collection of tools for working with Claude Code more comfortably.

## Tools

### [claudemux](claudemux/README.md)

Per-pane Claude Code session restore for tmux-resurrect. Each tmux pane
survives save/restore cycles (and Claude Code updates) with its own
session UUID intact.

### [claudex-lite](claudex-lite/README.md)

Fast, fzf-based picker for Claude Code sessions. Lists sessions from
the current directory (or all projects with `--all`), shows a rich
preview, and resumes the selected one. Ships with a `cx` dispatcher
for shorter invocation.
