# Google Antigravity Home Assistant Add-on Repository

Home Assistant Add-on repository for **Google Antigravity CLI (`agy`)** — providing a persistent Ingress TUI, Always-Turbo permissions, automatic `remote-control` daemon supervision, and a purpose-built Home Assistant OS agent toolchain (`ha` CLI, `docker` CLI, `uv`, `ripgrep`, `gh`, `sqlite3`, `mosquitto-clients`).

## Add-ons in this Repository

- **[Google Antigravity CLI](./antigravity)**: Persistent `tmux`-backed `agy` TUI in the Home Assistant sidebar, automatic `agy remote-control serve` background supervisor, and full Home Assistant / Supervisor / Docker management environment.

## Installation

1. In Home Assistant, navigate to **Settings → Add-ons → Add-on Store**.
2. Click the **three dots (`⋮`)** in the top right corner and select **Repositories**.
3. Add this repository URL:
   ```text
   https://github.com/mostlyrobots/agy-ha
   ```
4. Find **Google Antigravity CLI**, click **Install** (pulls the pre-built container image from GHCR), and enable **Show in sidebar**.
5. Start the add-on and open **Antigravity** in the sidebar to complete Google OAuth sign-in. Once authenticated, `agy remote-control serve` starts automatically in the background in Turbo mode.
