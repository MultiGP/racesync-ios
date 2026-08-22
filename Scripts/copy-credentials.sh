#!/bin/bash
set -euo pipefail

FILENAME="credentials.plist"
DEBUG_FILENAME="credentials-debug.plist"

# Pick source file by configuration
if [[ "${CONFIGURATION}" == "Debug" ]]; then
  SRC_NAME="${DEBUG_FILENAME}"
else
  SRC_NAME="${FILENAME}"
fi

# Search upwards from SRCROOT for a credentials/ folder
SEARCH_DIR="${SRCROOT}"
while [[ "${SEARCH_DIR}" != "/" ]]; do
  if [[ -d "${SEARCH_DIR}/credentials" ]]; then
    SRC_PATH="${SEARCH_DIR}/credentials/${SRC_NAME}"
    break
  fi
  SEARCH_DIR="$(dirname "${SEARCH_DIR}")"
done

if [[ -z "${SRC_PATH:-}" ]]; then
  echo "ERROR: Could not find credentials/ folder above SRCROOT=${SRCROOT}" >&2
  exit 1
fi

if [[ ! -f "${SRC_PATH}" ]]; then
  echo "ERROR: Source file not found: ${SRC_PATH}" >&2
  exit 1
fi

# Destination is always the app bundle — no framework hunting needed
DEST_PATH="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/${FILENAME}"

echo "Copying: ${SRC_PATH} → ${DEST_PATH}"
cp -fv "${SRC_PATH}" "${DEST_PATH}"
echo "Done."
