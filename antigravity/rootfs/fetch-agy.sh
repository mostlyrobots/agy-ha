#!/usr/bin/env bash
set -e

ARCH=$(uname -m)
case "$ARCH" in
  x86_64|amd64)
    MANIFEST_URL="https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/linux_amd64.json"
    ;;
  aarch64|arm64)
    MANIFEST_URL="https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/linux_arm64.json"
    ;;
  *)
    echo "[Antigravity] Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

echo "[Antigravity] Checking latest agy release for $ARCH..."
MANIFEST_JSON=$(curl -sSL --fail "$MANIFEST_URL" || true)

if [ -z "$MANIFEST_JSON" ]; then
  if [ -x "/usr/local/bin/agy" ]; then
    echo "[Antigravity] Could not fetch manifest, using existing binary."
    exit 0
  else
    echo "[Antigravity] ERROR: Failed to fetch manifest and no local binary found!"
    exit 1
  fi
fi

VERSION=$(echo "$MANIFEST_JSON" | jq -r '.version')
TARBALL_URL=$(echo "$MANIFEST_JSON" | jq -r '.url')
EXPECTED_SHA=$(echo "$MANIFEST_JSON" | jq -r '.sha512')

CURRENT_VERSION=""
if [ -f "/data/agy-version" ]; then
  CURRENT_VERSION=$(cat "/data/agy-version")
fi

if [ -x "/usr/local/bin/agy" ] && [ "$CURRENT_VERSION" = "$VERSION" ]; then
  echo "[Antigravity] Already on latest version ($VERSION)."
  exit 0
fi

echo "[Antigravity] Downloading agy version $VERSION from $TARBALL_URL..."
TMP_ARCHIVE="/tmp/agy_${VERSION}.tar.gz"
curl -sSL --fail "$TARBALL_URL" -o "$TMP_ARCHIVE"

echo "[Antigravity] Verifying SHA-512 checksum..."
CALCULATED_SHA=$(sha512sum "$TMP_ARCHIVE" | awk '{print $1}')
if [ "$CALCULATED_SHA" != "$EXPECTED_SHA" ]; then
  echo "[Antigravity] ERROR: Checksum mismatch!"
  echo "Expected:   $EXPECTED_SHA"
  echo "Calculated: $CALCULATED_SHA"
  rm -f "$TMP_ARCHIVE"
  exit 1
fi

echo "[Antigravity] Checksum verified. Extracting..."
mkdir -p /tmp/agy_unpack
tar -xzf "$TMP_ARCHIVE" -C /tmp/agy_unpack

EXTRACTED_BIN=$(find /tmp/agy_unpack -type f -name "agy" | head -n 1)
if [ -z "$EXTRACTED_BIN" ]; then
  # Fall back to any ELF binary found in the archive
  EXTRACTED_BIN=$(find /tmp/agy_unpack -type f -executable | head -n 1)
fi

if [ -n "$EXTRACTED_BIN" ]; then
  cp "$EXTRACTED_BIN" /usr/local/bin/agy
  chmod +x /usr/local/bin/agy
  mkdir -p /data
  echo "$VERSION" > /data/agy-version
  echo "[Antigravity] Successfully installed agy version $VERSION to /usr/local/bin/agy"
else
  echo "[Antigravity] ERROR: Could not find agy binary in archive!"
  rm -rf /tmp/agy_unpack "$TMP_ARCHIVE"
  exit 1
fi

rm -rf /tmp/agy_unpack "$TMP_ARCHIVE"
