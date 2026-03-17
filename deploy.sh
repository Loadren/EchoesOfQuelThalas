#!/usr/bin/env bash
set -euo pipefail

ADDON_NAME="EchoesOfQuelThalas"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_ROOT="${1:-/mnt/Games/World of Warcraft/_retail_/Interface/AddOns}"
DEST_DIR="${DEST_ROOT}/${ADDON_NAME}"

if [[ ! -d "${DEST_ROOT}" ]]; then
  echo "AddOns folder not found: ${DEST_ROOT}" >&2
  echo "Usage: bash deploy.sh [/path/to/World of Warcraft/_retail_/Interface/AddOns]" >&2
  exit 1
fi

mkdir -p "${DEST_DIR}"

if command -v rsync >/dev/null 2>&1; then
  rsync -a --delete \
    --exclude ".git/" \
    --exclude ".release/" \
    --exclude "tools/" \
    --exclude "deploy.sh" \
    --exclude "README.md" \
    --exclude "CHANGELOG.md" \
    "${SCRIPT_DIR}/" \
    "${DEST_DIR}/"
else
  rm -rf "${DEST_DIR}"
  mkdir -p "${DEST_DIR}"
  cp -r "${SCRIPT_DIR}/EchoesOfQuelThalas.toc" "${DEST_DIR}/"
  cp -r "${SCRIPT_DIR}/Engine.lua" "${DEST_DIR}/"
  cp -r "${SCRIPT_DIR}/Locale.lua" "${DEST_DIR}/"
  cp -r "${SCRIPT_DIR}/Options.lua" "${DEST_DIR}/"
  cp -r "${SCRIPT_DIR}/Packs.lua" "${DEST_DIR}/"
  cp -r "${SCRIPT_DIR}/Tracks.lua" "${DEST_DIR}/"
  cp -r "${SCRIPT_DIR}/Zones.lua" "${DEST_DIR}/"
  cp -r "${SCRIPT_DIR}/silence.ogg" "${DEST_DIR}/"
  cp -r "${SCRIPT_DIR}/lib" "${DEST_DIR}/"
fi

echo "Deployed ${ADDON_NAME} to ${DEST_DIR}"
