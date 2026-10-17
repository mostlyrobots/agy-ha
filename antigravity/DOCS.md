# Home Assistant Add-on: Google Antigravity CLI

The Google Antigravity CLI add-on provides a fully-equipped terminal development environment and remote-control agent for your Home Assistant system.

## Features

- **Automated Google Releases**: Automatically fetches the latest official `agy` binary on startup from Google.
- **Always Turbo Mode**: Preconfigures permissions so Antigravity has full permission to read, write, execute commands, and perform actions without prompting for tool confirmations.
- **Supervisor & Container Access**: Mapped to `/config`, `/share`, `/ssl`, `/media`, and Docker API for inspecting and managing system resources.
- **Ingress Web Terminal**: Click **Antigravity** directly in your Home Assistant sidebar to interact with the CLI or run shell commands.
- **Background Remote Control Daemon**: Once authenticated, the add-on runs `agy remote-control serve` in the background with persistent health monitoring.

## Setup Instructions

1. **Start the Add-on**:
   - In Home Assistant, open the **Antigravity** add-on page and click **Start**.
   - Make sure **Show in sidebar** is enabled.
2. **First-Time Authentication**:
   - Click **Antigravity** in the Home Assistant left sidebar.
   - An interactive terminal will open. Follow the on-screen instructions to sign in with your Google account.
3. **Background Daemon**:
   - As soon as authentication completes, the background remote-control daemon activates automatically.

## Configuration Options

- `default_model`: The default model used by Antigravity (e.g. `Gemini 3.8 Flash (Low)`, `Gemini 3.8 Pro`).
- `gcp_project`: (Optional) Google Cloud Project ID.
- `auto_start_remote_control`: Whether to start the remote-control daemon in the background (default: `true`).
