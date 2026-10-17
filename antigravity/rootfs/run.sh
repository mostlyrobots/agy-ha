#!/usr/bin/env bash
set -euo pipefail

echo "=========================================================="
echo " Starting Google Antigravity Home Assistant Add-on        "
echo "=========================================================="

# 1. Setup persistent storage in /data
mkdir -p /data/.gemini/antigravity-cli
mkdir -p /data/.gemini/config
mkdir -p /data/.ssh
mkdir -p /data/.config/gh
mkdir -p /data/bin
chmod 700 /data/.ssh

rm -rf /root/.gemini
ln -sf /data/.gemini /root/.gemini

rm -rf /root/.ssh
ln -sf /data/.ssh /root/.ssh

mkdir -p /root/.config
rm -rf /root/.config/gh
ln -sf /data/.config/gh /root/.config/gh

mkdir -p /root/.local
rm -rf /root/.local/bin
ln -sf /data/bin /root/.local/bin

touch /data/.gitconfig
ln -sf /data/.gitconfig /root/.gitconfig

export PATH="/usr/local/bin:/data/bin:${PATH}"

# Ensure PATH is persisted for interactive bash shells
cat > /etc/profile.d/antigravity.sh << 'EOF'
export PATH="/usr/local/bin:/data/bin:${PATH}"
export TERM="xterm-256color"
export COLORTERM="truecolor"
alias agy="/usr/local/bin/agy --dangerously-skip-permissions"
EOF
chmod +x /etc/profile.d/antigravity.sh

# 2. Fetch or update agy binary from Google
/fetch-agy.sh

# 3. Read add-on options from /data/options.json
OPTIONS_FILE="/data/options.json"
INSTANCE_NAME="homeassistant"
AUTO_START_DAEMON="true"
GIT_USER_NAME=""
GIT_USER_EMAIL=""

if [ -f "${OPTIONS_FILE}" ]; then
  OPT_INSTANCE="$(jq -r '.instance_name // empty' "${OPTIONS_FILE}")"
  [ -n "${OPT_INSTANCE}" ] && INSTANCE_NAME="${OPT_INSTANCE}"

  OPT_AUTO_START="$(jq -r 'if .auto_start_remote_control == false then "false" else "true" end' "${OPTIONS_FILE}")"
  AUTO_START_DAEMON="${OPT_AUTO_START}"

  GIT_USER_NAME="$(jq -r '.git_user_name // empty' "${OPTIONS_FILE}")"
  GIT_USER_EMAIL="$(jq -r '.git_user_email // empty' "${OPTIONS_FILE}")"
fi

# Configure git safe.directory and optional identity
git config --global --replace-all safe.directory "*" || true
if [ -n "${GIT_USER_NAME}" ]; then
  git config --global user.name "${GIT_USER_NAME}" || true
fi
if [ -n "${GIT_USER_EMAIL}" ]; then
  git config --global user.email "${GIT_USER_EMAIL}" || true
fi

# Normalize instance prefix (strip trailing hyphen if provided)
INSTANCE_PREFIX="${INSTANCE_NAME%-}"
[ -z "${INSTANCE_PREFIX}" ] && INSTANCE_PREFIX="homeassistant"

ensure_remote_control_hostname() {
  local CONFIG_JSON="/data/.gemini/config/config.json"
  local CUR_CFG="{}"
  if [ -s "${CONFIG_JSON}" ]; then
    CUR_CFG="$(cat "${CONFIG_JSON}" 2>/dev/null || echo "{}")"
  fi

  local EXISTING_HOST
  EXISTING_HOST="$(echo "${CUR_CFG}" | jq -r '.userSettings.cliRemoteControlHostname // empty' 2>/dev/null || true)"

  local SUFFIX=""
  if [[ "${EXISTING_HOST}" == *-antigravity-* ]]; then
    SUFFIX="${EXISTING_HOST#*antigravity-}"
  elif [[ "${EXISTING_HOST}" == "${INSTANCE_PREFIX}-"* ]]; then
    SUFFIX="${EXISTING_HOST#${INSTANCE_PREFIX}-}"
  elif [ -n "${EXISTING_HOST}" ]; then
    SUFFIX="${EXISTING_HOST}"
  fi

  if [ -z "${SUFFIX}" ]; then
    local ADJS=("glowing" "rising" "radiant" "stellar" "cosmic" "lunar" "solar" "quantum")
    local NOUNS=("flare" "vector" "nebula" "horizon" "pulse" "orbit" "beacon" "vertex")
    local W1="${ADJS[$((RANDOM % ${#ADJS[@]}))]}"
    local W2="${NOUNS[$((RANDOM % ${#NOUNS[@]}))]}"
    SUFFIX="${W1}-${W2}"
  fi

  FULL_INSTANCE_NAME="${INSTANCE_PREFIX}-${SUFFIX}"

  local UPDATED_CFG
  UPDATED_CFG="$(echo "${CUR_CFG}" | jq --arg host "${FULL_INSTANCE_NAME}" '
    .userSettings = (.userSettings // {}) |
    .userSettings.cliRemoteControlHostname = $host |
    .userSettings.remoteControlHostname = $host |
    .userSettings.globalPermissionGrants = {
      allow: (
        ((.userSettings.globalPermissionGrants.allow // []) + [
          "command(*)",
          "write_file(*)",
          "read_file(*)",
          "read_url(*)",
          "mcp(*)"
        ]) | unique
      )
    }
  ' 2>/dev/null || echo "${CUR_CFG}")"

  echo "${UPDATED_CFG}" > "${CONFIG_JSON}"
  echo -n "${FULL_INSTANCE_NAME}" > /data/.gemini/antigravity-cli/remote-control-name
}

ensure_remote_control_hostname

# 4. Enforce Always-Turbo Mode globally and per-workspace without clobbering user model choices
SETTINGS_PATH="/data/.gemini/antigravity-cli/settings.json"
echo "[Antigravity] Enforcing TURBO mode permissions (Instance: ${FULL_INSTANCE_NAME})..."

CURRENT_SETTINGS="{}"
if [ -s "${SETTINGS_PATH}" ]; then
  CURRENT_SETTINGS="$(cat "${SETTINGS_PATH}" 2>/dev/null || echo "{}")"
fi

TURBO_FILTER='
  .permissionPreset = "turbo" |
  .permission_preset = "turbo" |
  .toolPermission = "always-proceed" |
  .artifactReview = "always-proceed" |
  .artifactReviewPolicy = "always-proceed" |
  .artifactReviewMode = "always-proceed" |
  .permissions = {
    allow: [
      "command(*)",
      "write_file(*)",
      "read_file(*)",
      "read_url(*)",
      "mcp(*)"
    ]
  } |
  .trustedWorkspaces = ((.trustedWorkspaces // []) + [
    "/config",
    "/homeassistant",
    "/addon_configs",
    "/share",
    "/ssl",
    "/media",
    "/backup",
    "/data",
    "/root",
    "/"
  ] | unique)
'

NEW_SETTINGS="$(echo "${CURRENT_SETTINGS}" | jq "${TURBO_FILTER}" 2>/dev/null || echo "{}")"
echo "${NEW_SETTINGS}" > "${SETTINGS_PATH}"
chmod 600 "${SETTINGS_PATH}"

mkdir -p /etc/antigravity
echo "${NEW_SETTINGS}" > /etc/antigravity/admin_settings.json
chmod 644 /etc/antigravity/admin_settings.json

# 5. Seed Home Assistant system instructions in ~/.gemini/config/GEMINI.md
cat > /data/.gemini/config/GEMINI.md << 'EOF'
# Home Assistant OS Agent Environment

You are running inside the **Google Antigravity CLI Add-on** on a Home Assistant OS / Supervised system with full manager permissions (`hassio_role: manager`, `homeassistant_api: true`, `docker_api: true`, `full_access: true`) and **Turbo Mode** enabled.

## Available Directories
- `/config` (also mapped at `/homeassistant`): Live Home Assistant Core configuration (`configuration.yaml`, `automations.yaml`, `scripts.yaml`, `scenes.yaml`, `custom_components/`, `.storage/`).
- `/addon_configs`: Per-add-on public configuration directories.
- `/share`: Shared data directory accessible across add-ons and Home Assistant.
- `/ssl`: TLS certificates directory.
- `/media`: Home Assistant media storage.
- `/backup`: Home Assistant backups directory.
- `/data`: Persistent storage for this Antigravity add-on (`~/.gemini`, `~/.ssh`, `/data/bin`).

## Pre-installed Home Assistant & Dev Toolchain
- **Home Assistant CLI (`ha`)**: Run `ha core check`, `ha core restart`, `ha core logs`, `ha addons`, `ha supervisor info`, `ha host info`, `ha network info`, `ha backups`, etc.
- **Supervisor & Core REST APIs**: `$SUPERVISOR_TOKEN` is automatically injected into the environment.
  - Core API: `curl -sSL -H "Authorization: Bearer $SUPERVISOR_TOKEN" http://supervisor/core/api/states`
  - Supervisor API: `curl -sSL -H "Authorization: Bearer $SUPERVISOR_TOKEN" http://supervisor/addons`
- **Docker CLI (`docker`)**: Connected directly to the host Supervisor Docker socket (`/var/run/docker.sock`). Run `docker ps`, `docker logs homeassistant`, `docker exec`, `docker stats`, etc.
- **Developer Tools**: `git`, `gh` (GitHub CLI), `python3`, `uv` / `uvx`, `rg` (ripgrep), `fd`, `jq`, `sqlite3` (for inspecting `/config/home-assistant_v2.db`), `mosquitto_pub` / `mosquitto_sub`, `tmux`.

## Best Practices When Modifying Home Assistant
1. Before restarting Home Assistant Core after editing YAML files in `/config`, always validate configuration with `ha core check`.
2. Reload specific domains when possible (e.g., via `/core/api/services/automation/reload`) instead of full restarts unless required.
EOF

# 6. Configure tmux for persistent Ingress TUI experience
cat > /root/.tmux.conf << 'EOF'
set -g default-terminal "xterm-256color"
set -ga terminal-overrides ",xterm-256color:Tc"
set -g mouse on
set -g history-limit 50000
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
set -s escape-time 10

# Easy window switching with Alt+1 / Alt+2 or mouse click on status bar
bind -n M-1 select-window -t 1
bind -n M-2 select-window -t 2

# Clean dark status bar
set -g status-position bottom
set -g status-style "bg=#181825,fg=#cdd6f4"
set -g status-left-length 40
set -g status-left "#[bg=#89b4fa,fg=#11111b,bold] ANTIGRAVITY #[bg=#313244,fg=#a6e3a1,bold] TURBO #[default] "
set -g status-right-length 80
set -g status-right "#[fg=#a6adc8]Click tab or Alt+1:agy Alt+2:bash #[bg=#313244,fg=#cdd6f4] /config "
setw -g window-status-format "#[fg=#6c7086]  #I:#W  "
setw -g window-status-current-format "#[bg=#45475a,fg=#cdd6f4,bold]  #I:#W  "
EOF

# 7. Background supervisor for agy remote-control serve
DAEMON_PID=""

stop_daemon() {
  if [ -n "${DAEMON_PID}" ] && kill -0 "${DAEMON_PID}" 2>/dev/null; then
    echo "[Antigravity] Stopping remote-control daemon (PID ${DAEMON_PID})..."
    kill "${DAEMON_PID}" 2>/dev/null || true
    wait "${DAEMON_PID}" 2>/dev/null || true
    DAEMON_PID=""
  fi
  pkill -f "agy.*remote-control serve" 2>/dev/null || true
}

daemon_supervisor_loop() {
  echo "[Antigravity] Remote-control supervisor started (auto_start=${AUTO_START_DAEMON}, instance=${FULL_INSTANCE_NAME})."
  local TOKEN_FILE="/data/.gemini/antigravity-cli/antigravity-oauth-token"
  local LAST_TOKEN_MTIME=""

  while true; do
    if [ "${AUTO_START_DAEMON}" = "true" ]; then
      if [ -s "${TOKEN_FILE}" ]; then
        rm -f /tmp/auth_notice_printed
        ensure_remote_control_hostname
        echo "[Antigravity] Starting agy remote-control serve (Instance: ${FULL_INSTANCE_NAME})..."
        cd /config
        set +e
        /usr/local/bin/agy --dangerously-skip-permissions remote-control serve >> /data/remote-control.log 2>&1 &
        DAEMON_PID=$!
        wait "${DAEMON_PID}"
        local EXIT_CODE=$?
        set -e
        DAEMON_PID=""

        if [ "${EXIT_CODE}" -eq 3 ]; then
          echo "[Antigravity] remote-control serve exited with status 3 (unauthenticated or unregistered). Waiting for token update..."
          LAST_TOKEN_MTIME="$(stat -c %Y "${TOKEN_FILE}" 2>/dev/null || echo "")"
          while [ -s "${TOKEN_FILE}" ]; do
            local CUR_MTIME
            CUR_MTIME="$(stat -c %Y "${TOKEN_FILE}" 2>/dev/null || echo "")"
            if [ "${CUR_MTIME}" != "${LAST_TOKEN_MTIME}" ]; then
              break
            fi
            sleep 5
          done
        else
          echo "[Antigravity] remote-control serve exited (code ${EXIT_CODE}). Restarting in 10s..."
          sleep 10
        fi
      else
        if [ ! -f /tmp/auth_notice_printed ]; then
          echo "[Antigravity] Waiting for Google OAuth sign-in. Open the Antigravity panel in Home Assistant to log in."
          touch /tmp/auth_notice_printed
        fi
        sleep 3
      fi
    else
      sleep 10
    fi
  done
}

daemon_supervisor_loop &
SUPERVISOR_PID=$!

cleanup() {
  echo "[Antigravity] Shutting down add-on..."
  kill "${SUPERVISOR_PID}" 2>/dev/null || true
  stop_daemon
  tmux kill-server 2>/dev/null || true
  pkill -f "ttyd" 2>/dev/null || true
  exit 0
}

trap cleanup SIGTERM SIGINT

# 8. Start ttyd on Ingress port 8099
echo "[Antigravity] Starting Ingress terminal on port 8099..."
cd /config
exec ttyd \
  -p 8099 \
  -W \
  -t fontSize=14 \
  -t fontFamily="JetBrains Mono, Fira Code, monospace" \
  -t disableLeaveAlert=true \
  -t theme='{"background": "#11111b", "foreground": "#cdd6f4"}' \
  /ui.sh
