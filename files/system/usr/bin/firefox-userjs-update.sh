#!/bin/bash

set -euo pipefail

FIREFOX_DIR="${HOME}/.var/app/org.mozilla.firefox/.mozilla/firefox"

if [ ! -d "$FIREFOX_DIR" ]; then
    echo "Firefox directory not found, skipping user.js update."
    exit 0
fi

echo "Updating Firefox user.js..."

find "$FIREFOX_DIR" -maxdepth 1 -type d -exec test -f "{}/user-overrides.js" \; -print \
  | while read -r profile; do
      if [ -f "$profile/updater.sh" ]; then
        "$profile/updater.sh" -bsu >/dev/null 2>&1
      fi
      if [ -f "$profile/prefsCleaner.sh" ]; then
        "$profile/prefsCleaner.sh" -s >/dev/null 2>&1
      fi
  done

echo "Firefox user.js updated successfully."
