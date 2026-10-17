# Changelog

## 1.1.0

- **Persistent TUI via `tmux`**: Opening the Antigravity sidebar now attaches directly to a persistent `tmux` session running `agy` in `/config`, with a second `2:bash` window accessible via click or `Alt+2`.
- **Lean Multi-Arch Container & Pre-built GHCR Images**: Replaced heavy Debian daemon packages with fast, multi-arch static binaries (`ha` CLI, `docker` CLI, `ttyd`, `uv` / `uvx`) plus `ripgrep`, `fd`, `gh`, `sqlite3`, and `mosquitto-clients`.
- **Home Assistant Context (`GEMINI.md`)**: Pre-seeds `~/.gemini/config/GEMINI.md` so `agy` natively understands `/config`, `ha` CLI commands, `$SUPERVISOR_TOKEN`, and Docker access.
- **Non-Destructive Settings Management**: Enforces Always-Turbo permissions without overwriting model or GCP project choices made inside the `agy` TUI.
- **Persistent `/data/bin/agy` Cache**: Caches the SHA-512 verified `agy` binary in `/data/bin/agy` across container updates.

## 1.0.1

- Fix startup `s6-overlay` PID 1 conflict by setting `init: false`.

## 1.0.0

- Initial release of the Google Antigravity CLI Home Assistant Add-on.
