#!/usr/bin/env bash
set -e

echo "=========================================================="
echo " Starting Google Antigravity Home Assistant Add-on        "
echo "=========================================================="

# 1. Setup persistent storage links
mkdir -p /data/.gemini/antigravity-cli
mkdir -p /data/.local/bin
mkdir -p /data/workspace

rm -rf /root/.gemini
ln -sf /data/.gemini /root/.gemini

mkdir -p /root/.local
rm -rf /root/.local/bin
ln -sf /data/.local/bin /root/.local/bin

export PATH="/usr/local/bin:/data/.local/bin:$PATH"

# 2. Fetch or update agy binary from Google
/fetch-agy.sh || true

# 3. Read add-on options from /data/options.json if available
OPTIONS_FILE="/data/options.json"
DEFAULT_MODEL="Gemini 3.8 Flash (Low)"
GCP_PROJECT=""
AUTO_START_DAEMON=true

if [ -f "$OPTIONS_FILE" ]; then
  OPT_MODEL=$(jq -r '.default_model // empty' "$OPTIONS_FILE")
  [ -n "$OPT_MODEL" ] && DEFAULT_MODEL="$OPT_MODEL"

  OPT_PROJECT=$(jq -r '.gcp_project // empty' "$OPTIONS_FILE")
  [ -n "$OPT_PROJECT" ] && GCP_PROJECT="$OPT_PROJECT"

  OPT_AUTO_START=$(jq -r '.auto_start_remote_control // true' "$OPTIONS_FILE")
  [ "$OPT_AUTO_START" = "false" ] && AUTO_START_DAEMON=false
fi

# 4. Enforce Always-Turbo Mode in global and project settings
SETTINGS_PATH="/data/.gemini/antigravity-cli/settings.json"
echo "[Antigravity] Enforcing TURBO mode in settings..."

if [ -f "$SETTINGS_PATH" ]; then
  CURRENT_SETTINGS=$(cat "$SETTINGS_PATH")
else
  CURRENT_SETTINGS="{}"
fi

NEW_SETTINGS=$(echo "$CURRENT_SETTINGS" | jq \
  --arg model "$DEFAULT_MODEL" \
  --arg project "$GCP_PROJECT" \
  '
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
  .trustedWorkspaces = [
    "/config",
    "/share",
    "/ssl",
    "/data",
    "/root",
    "/"
  ] |
  if ($model | length > 0) then .model = $model else . end |
  if ($project | length > 0) then .gcp = { project: $project, location: "global" } else . end
  '
)

echo "$NEW_SETTINGS" > "$SETTINGS_PATH"
chmod 600 "$SETTINGS_PATH"

# Also configure .gitconfig if not set
if [ ! -f /root/.gitconfig ] && [ -f /data/.gitconfig ]; then
  ln -sf /data/.gitconfig /root/.gitconfig
fi

# 5. Remote-control daemon background supervisor
DAEMON_PID=""

start_daemon() {
  if ! pgrep -f "agy.*remote-control serve" >/dev/null 2>&1; then
    echo "[Antigravity] Launching agy remote-control daemon in TURBO mode..."
    cd /config
    /usr/local/bin/agy --dangerously-skip-permissions remote-control serve >> /data/remote-control.log 2>&1 &
    DAEMON_PID=$!
    echo "[Antigravity] Remote-control daemon running with PID $DAEMON_PID"
  fi
}

stop_daemon() {
  if [ -n "$DAEMON_PID" ] && kill -0 "$DAEMON_PID" 2>/dev/null; then
    echo "[Antigravity] Stopping remote-control daemon (PID $DAEMON_PID)..."
    kill "$DAEMON_PID" 2>/dev/null || true
    wait "$DAEMON_PID" 2>/dev/null || true
    DAEMON_PID=""
  fi
  pkill -f "agy.*remote-control serve" 2>/dev/null || true
}

daemon_supervisor_loop() {
  echo "[Antigravity] Background supervisor loop started."
  while true; do
    if [ "$AUTO_START_DAEMON" = "true" ]; then
      # Check if authenticated
      TOKEN_FILE="/data/.gemini/antigravity-cli/antigravity-oauth-token"
      if [ -s "$TOKEN_FILE" ]; then
        if ! pgrep -f "agy.*remote-control serve" >/dev/null 2>&1; then
          start_daemon
        fi
      else
        if [ ! -f /tmp/auth_notice_printed ]; then
          echo "[Antigravity] Waiting for authentication. Please open Antigravity from Home Assistant sidebar to log in."
          touch /tmp/auth_notice_printed
        fi
      fi
    fi
    sleep 5
  done
}

daemon_supervisor_loop &
SUPERVISOR_PID=$!

# Trap signals for graceful shutdown
cleanup() {
  echo "[Antigravity] Stopping add-on..."
  kill "$SUPERVISOR_PID" 2>/dev/null || true
  stop_daemon
  pkill -f "ttyd" 2>/dev/null || true
  exit 0
}

trap cleanup SIGTERM SIGINT

# 6. Start ttyd on Ingress port 8099
echo "[Antigravity] Starting Ingress terminal on port 8099..."
cd /config
exec ttyd \
  -p 8099 \
  -W \
  -t fontSize=14 \
  -t fontFamily="monospace" \
  -t theme='{"background": "#1e1e1e"}' \
  /ui.sh
