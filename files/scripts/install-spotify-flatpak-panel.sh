#!/bin/bash

set -oue pipefail

EXT_UUID="spotify-flatpak-panel@iansantos.codeberg.page"
RELEASE_API="https://codeberg.org/api/v1/repos/iansantos/spotify-flatpak-panel/releases/latest"
TMP_DIR="$(mktemp -d)"
BUNDLE="${TMP_DIR}/spotify-flatpak-panel.zip"

cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

EXT_URL="$(
  curl -fLs "${RELEASE_API}" \
    | jq -er 'first(.assets[] | select(.name | test("^spotify-flatpak-panel-.*\\.zip$")) | .browser_download_url) // error("release has no Spotify Flatpak Panel zip asset")'
)"

echo "Installing Spotify Flatpak Panel GNOME extension from ${EXT_URL}"
curl -fLs "${EXT_URL}" -o "${BUNDLE}"

XDG_CACHE_HOME="${TMP_DIR}/cache" \
XDG_DATA_HOME="/usr/share" \
  gnome-extensions install --force --print-uuid "${BUNDLE}"

echo "Spotify Flatpak Panel GNOME extension installed at /usr/share/gnome-shell/extensions/${EXT_UUID}"
