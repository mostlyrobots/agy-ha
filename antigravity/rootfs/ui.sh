#!/usr/bin/env bash
set -e

cd /config
clear

TOKEN_FILE="/data/.gemini/antigravity-cli/antigravity-oauth-token"

echo -e "\033[1;34m"
echo "  ██████╗  ██████╗  ██████╗  ██████╗ ██╗     ███████╗"
echo " ██╔════╝ ██╔═══██╗██╔═══██╗██╔════╝ ██║     ██╔════╝"
echo " ██║  ███╗██║   ██║██║   ██║██║  ███╗██║     █████╗  "
echo " ██║   ██║██║   ██║██║   ██║██║   ██║██║     ██╔══╝  "
echo " ╚██████╔╝╚██████╔╝╚██████╔╝╚██████╔╝███████╗███████╗"
echo "  ╚═════╝  ╚═════╝  ╚═════╝  ╚═════╝ ╚══════╝╚══════╝"
echo "       Google Antigravity - Home Assistant Terminal    "
echo -e "\033[0m"

echo "──────────────────────────────────────────────────────────"
echo " Mode: TURBO (All permissions granted automatically)"
echo " Workspace: /config (Home Assistant configuration)"

if [ ! -s "$TOKEN_FILE" ]; then
  echo -e "\033[1;33m Status: Authentication Required\033[0m"
  echo "──────────────────────────────────────────────────────────"
  echo ""
  echo " Antigravity needs to authenticate with your Google account."
  echo " Launching agy now to start the login flow..."
  echo ""
  read -p " Press [ENTER] to begin authentication: " _dummy

  /usr/local/bin/agy

  if [ -s "$TOKEN_FILE" ]; then
    echo ""
    echo -e "\033[1;32m [✓] Authentication successful!\033[0m"
    echo " The remote-control daemon is starting automatically in the background."
    echo ""
    # Ensure daemon is triggered immediately
    pkill -f "agy.*remote-control serve" 2>/dev/null || true
    sleep 1
  fi
else
  if pgrep -f "agy.*remote-control serve" >/dev/null 2>&1; then
    echo -e "\033[1;32m Remote Daemon: ACTIVE\033[0m (Running in background)"
  else
    echo -e "\033[1;33m Remote Daemon: STARTING...\033[0m"
  fi
  echo "──────────────────────────────────────────────────────────"
fi

echo ""
echo " You are now in the Home Assistant Antigravity terminal."
echo " Commands: 'agy' (launch agent), 'agy --help', or any shell command."
echo ""

exec /bin/bash -l
