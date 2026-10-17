#!/usr/bin/env bash

export PATH="/usr/local/bin:/data/bin:${PATH}"
export TERM="xterm-256color"
export COLORTERM="truecolor"

TOKEN_FILE="/data/.gemini/antigravity-cli/antigravity-oauth-token"
INSTANCE_FILE="/data/.gemini/antigravity-cli/remote-control-name"

cd /config

while true; do
  clear
  INSTANCE_NAME="$(cat "${INSTANCE_FILE}" 2>/dev/null || echo "homeassistant")"

  if [ ! -s "${TOKEN_FILE}" ]; then
    echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e " \033[1;37mGoogle Antigravity for Home Assistant\033[0m  │  \033[1;32mMode: TURBO\033[0m  │  \033[1;33mSetup: Sign-In\033[0m"
    echo -e " Complete Google OAuth login below. Remote Control (\033[1;37m${INSTANCE_NAME}\033[0m) will auto-start."
    echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo ""
  fi

  /usr/local/bin/agy --dangerously-skip-permissions

  echo ""
  echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
  if pgrep -f "agy.*remote-control serve" >/dev/null 2>&1; then
    echo -e " \033[1;32m● Remote Control Daemon: ACTIVE\033[0m (Instance: \033[1;37m${INSTANCE_NAME}\033[0m)"
  elif [ -s "${TOKEN_FILE}" ]; then
    echo -e " \033[1;33m● Remote Control Daemon: STARTING...\033[0m (Instance: \033[1;37m${INSTANCE_NAME}\033[0m)"
  else
    echo -e " \033[1;31m○ Remote Control Daemon: Waiting for Google OAuth login\033[0m"
  fi
  echo -e "\033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
  read -r -p " Press [ENTER] to relaunch Antigravity, or type 'sh' for a bash shell: " choice || true
  if [ "${choice}" = "sh" ] || [ "${choice}" = "bash" ]; then
    echo " Tip: Type 'exit' to return to Antigravity, or use the bottom bar (2:bash)."
    /bin/bash -l
  fi
done
