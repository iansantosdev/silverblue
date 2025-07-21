#!/bin/bash

set -euo pipefail

find "${HOME}/.var/app/org.mozilla.firefox/.mozilla/firefox" -maxdepth 1 -type d -exec test -f "{}/user-overrides.js" \; -print \
  | while read -r profile; do
      "$profile/updater.sh" -bsu
      "$profile/prefsCleaner.sh" -s
  done
