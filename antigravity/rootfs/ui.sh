#!/usr/bin/env bash
set -euo pipefail

export PATH="/usr/local/bin:/data/bin:${PATH}"
export TERM="xterm-256color"
export COLORTERM="truecolor"

cd /config

# Create persistent tmux session with window 1 (agy) and window 2 (bash) if not already running
if ! tmux has-session -t antigravity 2>/dev/null; then
  tmux new-session -d -s antigravity -n "agy" -c /config "/agy-loop.sh"
  tmux new-window -t antigravity:2 -n "bash" -c /config "/bin/bash -l"
  tmux select-window -t antigravity:1
fi

exec tmux attach-session -t antigravity
