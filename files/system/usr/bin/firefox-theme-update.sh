#!/bin/bash

set -euo pipefail

FIREFOX_DIR="${HOME}/.var/app/org.mozilla.firefox/.mozilla/firefox"

if [ ! -d "$FIREFOX_DIR" ]; then
    echo "Firefox directory not found, skipping theme update."
    exit 0
fi

TMPDIR=$(mktemp -d)
cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

echo "Updating Firefox GNOME theme..."

git clone --depth 1 --branch master --quiet https://github.com/rafaelmardojai/firefox-gnome-theme.git "$TMPDIR/firefox-gnome-theme"

find "$FIREFOX_DIR" -maxdepth 1 -type d -exec test -d "{}/chrome" \; -print \
  | while read -r profile; do
      target="$profile/chrome/theme"
      rm -rf "$target"
      install -d "$target"
      cp -a "$TMPDIR/firefox-gnome-theme/theme/." "$target/"
      cp -a "$TMPDIR/firefox-gnome-theme/userChrome.css"  "${target%/*}"
      cp -a "$TMPDIR/firefox-gnome-theme/userContent.css" "${target%/*}"
  done

echo "Firefox GNOME theme updated successfully."
