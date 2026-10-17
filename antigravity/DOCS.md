# Home Assistant Add-on: Google Antigravity CLI

Run the official **Google Antigravity (`agy`)** AI coding assistant and its `remote-control` daemon directly inside Home Assistant OS with a persistent sidebar TUI, pre-installed Home Assistant & Docker toolchain, and **Always-Turbo** permissions.

## Features

- **Persistent Sidebar TUI (`tmux` + `ttyd`)**: Click **Antigravity** in the Home Assistant sidebar to attach directly to a persistent `agy` session running in `/config`. Switch browser tabs or reload Home Assistant without losing your active agent conversation.
- **Built-in Bash Window**: Switch between `1:agy` and `2:bash` at any time by clicking the bottom status bar or pressing `Alt+1` / `Alt+2`.
- **Always-Turbo Mode**: Automatically configures both global (`~/.gemini/antigravity-cli/settings.json`, `/etc/antigravity/admin_settings.json`) and session permissions (`--dangerously-skip-permissions`) to `turbo` (`always-proceed`), while preserving your selected model and GCP project settings.
- **Automatic `remote-control` Daemon**: Once you complete Google OAuth sign-in inside the sidebar terminal, the background supervisor automatically launches and monitors `agy remote-control serve` so your Home Assistant instance appears in [Antigravity Remote Control](https://antigravity.google.com).
- **Purpose-Built Home Assistant Toolchain**:
  - Official Home Assistant CLI (`ha`) with pre-injected `$SUPERVISOR_TOKEN`
  - Docker CLI (`docker`) connected to the host Supervisor Docker socket
  - `git`, `gh` (GitHub CLI), `python3`, `uv` / `uvx`, `ripgrep` (`rg`), `fd`, `jq`, `sqlite3`, `mosquitto-clients`
  - Pre-seeded `~/.gemini/config/GEMINI.md` teaching `agy` how to inspect and manage Home Assistant safely.
- **Automatic Self-Updating Binary**: Dynamically fetches the latest `agy` release for `amd64` or `aarch64` from Google's official updater manifest on startup, verifies its SHA-512 checksum, and caches it in persistent `/data/bin/agy`.

## Configuration Options

| Option | Default | Description |
| :--- | :--- | :--- |
| `instance_name` | `"homeassistant"` | Instance name displayed in Antigravity Remote Control (`https://antigravity.google.com`). |
| `auto_start_remote_control` | `true` | Automatically start and supervise `agy remote-control serve` once authenticated. |
| `git_user_name` | `""` | Optional Git `user.name` configured globally inside the add-on. |
| `git_user_email` | `""` | Optional Git `user.email` configured globally inside the add-on. |
