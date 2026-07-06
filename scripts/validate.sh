#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

TMPDIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

bluebuild --log-out /tmp/bluebuild-logs validate recipes/silverblue.yml

scripts/validate-flatpaks.sh --offline

shellcheck \
  scripts/*.sh \
  files/scripts/*.sh \
  files/system/usr/libexec/silverblue/* \
  modules/gnome-extensions/gnome-extensions.sh

scripts/validate-systemd.sh

dconf compile "$TMPDIR/check-dconf-user" files/system/etc/dconf/db/distro.d

cp /usr/share/glib-2.0/schemas/*.xml "$TMPDIR/"
cp files/gschema-overrides/*.gschema.override "$TMPDIR/"
glib-compile-schemas --strict --dry-run "$TMPDIR"
