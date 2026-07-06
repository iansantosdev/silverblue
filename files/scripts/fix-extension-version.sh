#!/bin/bash

set -oue pipefail

update_shell_version() {
  local file="$1"
  local tmp
  tmp="$(mktemp)"

  jq '(.["shell-version"] // []) += ["50"] | .["shell-version"] |= unique' "$file" > "$tmp"
  chown --reference="$file" "$tmp"
  chmod --reference="$file" "$tmp"
  mv "$tmp" "$file"
}

update_shell_version /usr/share/gnome-shell/extensions/clipboard-history@alexsaveau.dev/metadata.json
