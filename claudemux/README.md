# claudemux

**tmux-claude-resurrect — per-pane Claude Code session restore**

Makes Claude Code sessions survive tmux-resurrect save/restore cycles (and
Claude Code updates) with per-pane fidelity. Each tmux pane gets its own
persistent session UUID; when tmux comes back, each pane resumes its own
conversation, not a neighbor's.

## How it works

1. A shell wrapper intercepts `claude` inside tmux panes, generates a UUID,
   stores it as a pane-scoped tmux user option (`@claude-session`), and
   invokes `claude` with `--session-id <uuid>` or `--resume <uuid>`
   depending on whether the session file already exists.
2. A tmux-resurrect **post-save** hook dumps every tagged pane's
   `(session, window, pane, cwd, uuid)` to a TSV.
3. A tmux-resurrect **post-restore** hook reads the TSV, re-tags each
   restored pane, verifies cwd wasn't drifted, and sends `claude` keys
   into the pane — the wrapper resolves to `--resume <uuid>`.

## Prerequisites

- **tmux 3.2+** (for `#{@option-name}` format support)
- **[tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect)** (plus
  optionally **tmux-continuum** for automatic periodic saves)
- **Claude Code 2.1+** (needs `--session-id` flag)
- `uuidgen` (ships with macOS / most Linux distros)
- Shell: `bash` or `zsh`

> **Don't have tmux set up yet?** If you're on macOS using iTerm2 natively,
> jump to [Starting from scratch on macOS (iTerm2 users)](#starting-from-scratch-on-macos-iterm2-users)
> for a full walkthrough, then come back here.

## Install

Clone the repo wherever you like, then run the installer from the `claudemux`
subdir:

```sh
git clone https://github.com/john-traas/claude-kit.git
cd claude-kit/claudemux
./install.sh
```

The installer is interactive. It:

1. Asks you to confirm the `claudemux` path (detected from its own location).
2. Appends an `export CLAUDEMUX_DIR=...` + wrapper source line to your shell
   rc (`~/.zshrc` or `~/.bashrc`) — idempotent; refuses to re-install if a
   block is already present.
3. Prints two `set -g @resurrect-hook-*` lines for your `~/.tmux.conf` —
   copy them in **before** the `run '~/.tmux/plugins/tpm/tpm'` line.

Reload after editing: `exec $SHELL` for the rc change, `tmux source-file ~/.tmux.conf`
for tmux.

## Move the install later

The wrapper loads from `$CLAUDEMUX_DIR`, so to move the checkout you edit one
line in your shell rc. The tmux hooks hold absolute paths — re-run `install.sh`
from the new location to reprint the correct lines and swap them in `~/.tmux.conf`.

## Usage

Just run `claude` in a tmux pane like normal. The wrapper is invisible —
it only adds persistence. To start a fresh session in the current pane:

```sh
claudemux-reset
```

That clears the pane's `@claude-session` tag; the next `claude` invocation
will mint a new UUID.

## Known limitations

- **cwd-scoped.** `claude --resume` only works from the session's original
  cwd. The restore hook guards against drift and skips silently-mismatched
  panes (logged via `tmux display-message`).
- **tmux layout stability.** If you renumber windows or reorganize panes
  between save and restore, the `session:window.pane` keys won't match
  and those panes are skipped.
- **No auto-restore of Claude crash state.** If Claude crashed mid-turn,
  `--resume` picks up from the last durable message. That's a Claude
  behavior, not a claudemux one.
- **Shell scope.** Only bash/zsh tested. Fish wrapper would need a
  translation of the function syntax.

## Files

| Path | Purpose |
|------|---------|
| `install.sh` | Interactive installer — run once after cloning |
| `wrapper.sh` | Sourced by your shell; defines `claude` and `claudemux-reset` |
| `hooks/save.sh` | tmux-resurrect post-save-all hook |
| `hooks/restore.sh` | tmux-resurrect post-restore-all hook |
| `hooks/_lib.sh` | Shared TSV path + column contract, sourced by both hooks |

State lives at `~/.local/share/tmux/resurrect/claude-sessions.tsv`
(override via `CLAUDEMUX_TSV`).

## Starting from scratch on macOS (iTerm2 users)

If you currently use iTerm2 natively (no tmux) and want the per-pane
restore experience, this is a one-time setup that takes about 10 minutes.
When you're done, you'll have tmux running inside a single iTerm2 window,
tmux-resurrect auto-saving every 15 minutes, and claudemux restoring each
pane's Claude session across restarts.

### 1. Install tmux

```sh
brew install tmux
tmux -V   # verify 3.2 or newer
```

### 2. Install TPM (Tmux Plugin Manager)

```sh
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

### 3. Clone claude-kit and run `claudemux/install.sh`

```sh
git clone https://github.com/john-traas/claude-kit.git
cd claude-kit/claudemux
./install.sh
```

Answer the prompts. The installer will append the wrapper source line to your
shell rc and print two `set -g @resurrect-hook-*` lines — keep the terminal
open so you can copy them into the next step.

### 4. Create `~/.tmux.conf`

Save this file — sensible defaults + resurrect/continuum. **Replace the two
`set -g @resurrect-hook-*` lines** with the absolute paths that `install.sh`
printed for you.

```tmux
# --- Sensible defaults ---
set -g default-terminal "screen-256color"
set -g mouse on
set -g base-index 1
setw -g pane-base-index 1

# --- Plugins via TPM ---
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'

# --- Resurrect: capture pane contents for richer restore ---
set -g @resurrect-capture-pane-contents 'on'

# --- Continuum: autosave every 15 min, auto-restore on tmux start ---
set -g @continuum-restore 'on'
set -g @continuum-save-interval '15'

# --- claudemux hooks — PASTE FROM install.sh OUTPUT ---
# set -g @resurrect-hook-post-save-all    '<absolute path to claudemux/hooks/save.sh>'
# set -g @resurrect-hook-post-restore-all '<absolute path to claudemux/hooks/restore.sh>'

# --- Initialize TPM (keep this LAST) ---
run '~/.tmux/plugins/tpm/tpm'
```

### 5. Reload your shell

```sh
exec $SHELL
```

The `install.sh` step above already added the wrapper source line to your rc.

### 6. Start tmux and install plugins

```sh
tmux new -s main
```

Inside tmux, press **`Ctrl-B I`** (capital I) — this tells TPM to fetch
and install the plugins from your `~/.tmux.conf`. A "Plugins installed"
message flashes at the bottom when it's done.

### 7. Test the save/restore cycle

- In a tmux pane, run `claude` — the wrapper silently tags the pane with
  a session UUID and starts Claude.
- Manual save: `Ctrl-B Ctrl-S` (tmux-resurrect's default save binding).
- Kill the server: `tmux kill-server`.
- Relaunch: `tmux new -s main` — `@continuum-restore 'on'` brings the
  saved layout back automatically; the claudemux restore hook fires
  `claude --resume <uuid>` in each tagged pane.

### 8. iTerm2 tips (optional but recommended)

- **Install iTerm Shell Integration** via iTerm's menu:
  `iTerm2 → Install Shell Integration`. Adds per-pane cwd tracking that
  works nicely alongside tmux.
- **Enable "Reopen windows on startup"** in iTerm preferences
  (General → Startup) so that when you reboot or quit iTerm, your window
  returns and tmux-continuum auto-restores the session inside it.
- **Skip `tmux -CC` (iTerm/tmux integration mode)** for v1 — it's
  intriguing but has rough edges around the resurrect hook flow. Use
  vanilla tmux inside one iTerm window for now.

### Daily workflow, once set up

You stop thinking about tmux-resurrect and claudemux. Run `claude` in any
tmux pane; the wrapper handles session-UUID assignment transparently.
When you update Claude Code, reboot, or kill tmux, each pane comes back
with its own Claude session intact — no pane accidentally resuming a
neighbor's conversation.

### Key bindings cheat sheet

| Combo | Action |
|---|---|
| `Ctrl-B %` | Split pane vertically |
| `Ctrl-B "` | Split pane horizontally |
| `Ctrl-B arrow` | Move between panes |
| `Ctrl-B c` | New window |
| `Ctrl-B n` / `p` | Next / previous window |
| `Ctrl-B d` | Detach (tmux keeps running in background) |
| `Ctrl-B Ctrl-S` | Manual resurrect save |
| `Ctrl-B Ctrl-R` | Manual resurrect restore |
| `Ctrl-B I` | Install/update TPM plugins |
| `Ctrl-B ?` | Show all key bindings |
