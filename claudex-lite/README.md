# claudex-lite

Fast, fzf-based picker for Claude Code sessions. The lite tier of
claudex under the claude-kit umbrella.

## What it does

Scans `~/.claude/projects/` for Claude Code session files, shows those
in your current directory (most recent first) with a rich preview, and
on Enter launches `claude --resume <uuid>` for the selected session.

Press `Ctrl-A` inside the picker to broaden the view to all sessions
across all projects.

## Requirements

- `bash` 3.2+ (macOS default is fine)
- `fzf` 0.44+ — `brew install fzf`
- `jq` 1.7+ — `brew install jq`
- `claude` (Claude Code) on PATH — `claude --version` to check

## Install

```sh
./install.sh
```

This symlinks the script into `~/.local/bin/claudex-lite`. Ensure
`~/.local/bin` is on your `PATH`:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

## Usage

```sh
claudex-lite          # picker in current directory
claudex-lite --all    # picker across all sessions
```

Inside the picker:

| Key | Action |
|---|---|
| Up / Down or Ctrl-P / Ctrl-N | Navigate |
| Type | Fuzzy-filter |
| Enter | Resume the selected session |
| Ctrl-A | Broaden to all sessions |
| Esc | Cancel |

## Optional: bind a key

**zsh:**

```zsh
bindkey -s '^G' 'claudex-lite^M'
```

**bash:**

```bash
bind -x '"\C-g": claudex-lite'
```

Now hit Ctrl-G at your prompt to pop the picker.

## Scope and non-goals

v1 does: pick → preview → resume, with an in-picker scope toggle.

v1 does NOT do: rename, delete, tags, content search. Those are slated
for a later Ink-based tier.

## Testing

```sh
brew install bats-core
bats tests/
```
