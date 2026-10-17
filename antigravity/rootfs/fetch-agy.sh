#!/usr/bin/env bash
set -euo pipefail

ARCH="$(uname -m)"
case "${ARCH}" in
  x86_64|amd64)
    MANIFEST_URL="https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/linux_amd64.json"
    ;;
  aarch64|arm64)
    MANIFEST_URL="https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/linux_arm64.json"
    ;;
  *)
    echo "[Antigravity] ERROR: Unsupported architecture: ${ARCH}" >&2
    exit 1
    ;;
esac

mkdir -p /data/bin
PERSISTENT_BIN="/data/bin/agy"
VERSION_FILE="/data/bin/agy-version"

# Ensure symlink exists if persistent binary is already present
if [ -x "${PERSISTENT_BIN}" ] && [ ! -e "/usr/local/bin/agy" ]; then
  ln -sf "${PERSISTENT_BIN}" /usr/local/bin/agy
fi

echo "[Antigravity] Checking latest agy release for ${ARCH}..."
MANIFEST_JSON="$(curl -fsSL --connect-timeout 10 --max-time 30 "${MANIFEST_URL}" || true)"

if [ -z "${MANIFEST_JSON}" ]; then
  if [ -x "${PERSISTENT_BIN}" ]; then
    echo "[Antigravity] WARNING: Could not reach update server; using cached agy binary."
    ln -sf "${PERSISTENT_BIN}" /usr/local/bin/agy
    exit 0
  else
    echo "[Antigravity] ERROR: Failed to fetch manifest and no cached agy binary found!" >&2
    exit 1
  fi
fi

VERSION="$(echo "${MANIFEST_JSON}" | jq -r '.version // empty')"
TARBALL_URL="$(echo "${MANIFEST_JSON}" | jq -r '.url // empty')"
EXPECTED_SHA="$(echo "${MANIFEST_JSON}" | jq -r '.sha512 // empty')"

if [ -z "${VERSION}" ] || [ -z "${TARBALL_URL}" ] || [ -z "${EXPECTED_SHA}" ]; then
  echo "[Antigravity] ERROR: Invalid manifest payload received." >&2
  [ -x "${PERSISTENT_BIN}" ] && exit 0 || exit 1
fi

CURRENT_VERSION=""
if [ -f "${VERSION_FILE}" ]; then
  CURRENT_VERSION="$(cat "${VERSION_FILE}")"
fi

if [ -x "${PERSISTENT_BIN}" ] && [ "${CURRENT_VERSION}" = "${VERSION}" ]; then
  ln -sf "${PERSISTENT_BIN}" /usr/local/bin/agy
  echo "[Antigravity] agy is up to date (version ${VERSION})."
  exit 0
fi

echo "[Antigravity] Downloading agy ${VERSION} (${ARCH})..."
TMP_DIR="$(mktemp -d /tmp/agy_install.XXXXXX)"
trap 'rm -rf "${TMP_DIR}"' EXIT

TMP_ARCHIVE="${TMP_DIR}/agy.tar.gz"
curl -fsSL --connect-timeout 15 --max-time 300 "${TARBALL_URL}" -o "${TMP_ARCHIVE}"

echo "[Antigravity] Verifying SHA-512 checksum..."
CALCULATED_SHA="$(sha512sum "${TMP_ARCHIVE}" | awk '{print $1}')"
if [ "${CALCULATED_SHA}" != "${EXPECTED_SHA}" ]; then
  echo "[Antigravity] ERROR: SHA-512 checksum mismatch!" >&2
  echo "  Expected:   ${EXPECTED_SHA}" >&2
  echo "  Calculated: ${CALCULATED_SHA}" >&2
  exit 1
fi

echo "[Antigravity] Extracting agy ${VERSION}..."
mkdir -p "${TMP_DIR}/unpack"
tar -xzf "${TMP_ARCHIVE}" -C "${TMP_DIR}/unpack"

EXTRACTED_BIN="$(find "${TMP_DIR}/unpack" -type f -name "agy" -print -quit)"
if [ -z "${EXTRACTED_BIN}" ]; then
  EXTRACTED_BIN="$(find "${TMP_DIR}/unpack" -type f -executable -print -quit)"
fi

if [ -z "${EXTRACTED_BIN}" ]; then
  echo "[Antigravity] ERROR: Could not locate agy binary inside archive!" >&2
  exit 1
fi

chmod +x "${EXTRACTED_BIN}"
mv -f "${EXTRACTED_BIN}" "${PERSISTENT_BIN}"
ln -sf "${PERSISTENT_BIN}" /usr/local/bin/agy
echo "${VERSION}" > "${VERSION_FILE}"

echo "[Antigravity] Successfully installed agy ${VERSION} -> ${PERSISTENT_BIN}"
