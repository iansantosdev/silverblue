#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SYSTEM_UNIT_DIR="$ROOT_DIR/files/system/usr/lib/systemd/system"
USER_UNIT_DIR="$ROOT_DIR/files/system/usr/lib/systemd/user"

TMPDIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

shopt -s nullglob

VALIDATION_SYSTEM_UNIT_DIR="$TMPDIR/system-units"
VALIDATION_USER_UNIT_DIR="$TMPDIR/user-units"
VALIDATION_USER_HOME="$TMPDIR/user-home"
VALIDATION_USER_RUNTIME_DIR="$TMPDIR/user-runtime"
mkdir -p \
  "$VALIDATION_SYSTEM_UNIT_DIR" \
  "$VALIDATION_USER_UNIT_DIR" \
  "$VALIDATION_USER_HOME/.config" \
  "$VALIDATION_USER_HOME/.local/share"
mkdir -m 0700 "$VALIDATION_USER_RUNTIME_DIR"
cp -a "$SYSTEM_UNIT_DIR/." "$VALIDATION_SYSTEM_UNIT_DIR/"
cp -a "$USER_UNIT_DIR/." "$VALIDATION_USER_UNIT_DIR/"

while IFS= read -r unit; do
  sed -i \
    "s|/usr/libexec/silverblue/|$ROOT_DIR/files/system/usr/libexec/silverblue/|g" \
    "$unit"
done < <(find "$VALIDATION_SYSTEM_UNIT_DIR" "$VALIDATION_USER_UNIT_DIR" -type f)

system_units=(
  "$SYSTEM_UNIT_DIR"/*.path
  "$SYSTEM_UNIT_DIR"/*.service
  "$SYSTEM_UNIT_DIR"/*.timer
)
user_units=(
  "$USER_UNIT_DIR"/*.path
  "$USER_UNIT_DIR"/*.service
  "$USER_UNIT_DIR"/*.timer
)
validation_system_units=(
  "$VALIDATION_SYSTEM_UNIT_DIR"/*.path
  "$VALIDATION_SYSTEM_UNIT_DIR"/*.service
  "$VALIDATION_SYSTEM_UNIT_DIR"/*.timer
)
validation_user_units=(
  "$VALIDATION_USER_UNIT_DIR"/*.path
  "$VALIDATION_USER_UNIT_DIR"/*.service
  "$VALIDATION_USER_UNIT_DIR"/*.timer
)

verify_user_units() {
  HOME="$VALIDATION_USER_HOME" \
    XDG_CONFIG_HOME="$VALIDATION_USER_HOME/.config" \
    XDG_DATA_HOME="$VALIDATION_USER_HOME/.local/share" \
    XDG_RUNTIME_DIR="$VALIDATION_USER_RUNTIME_DIR" \
    SYSTEMD_UNIT_PATH="$VALIDATION_USER_UNIT_DIR:/usr/lib/systemd/user" \
    systemd-analyze --user verify \
      --generators=no \
      --man=no \
      --recursive-errors=no \
      "$@"
}

echo "Verifying system units..."
SYSTEMD_UNIT_PATH="$VALIDATION_SYSTEM_UNIT_DIR:/usr/lib/systemd/system" \
  systemd-analyze verify \
    --generators=no \
    --man=no \
    --recursive-errors=no \
    "${validation_system_units[@]}"

echo "Verifying user units..."
verify_user_units "${validation_user_units[@]}"

echo "Verifying installed units with local drop-ins..."
system_dropins=(
  rpm-ostreed-automatic.service
  rpm-ostreed-automatic.timer
  tailscaled.service
)
for unit in "${system_dropins[@]}"; do
  if [[ -e "/usr/lib/systemd/system/$unit" ]]; then
    SYSTEMD_UNIT_PATH="$VALIDATION_SYSTEM_UNIT_DIR:/usr/lib/systemd/system" \
      systemd-analyze verify \
        --generators=no \
        --man=no \
        --recursive-errors=no \
        "$unit"
  fi
done

if [[ -e /usr/lib/systemd/user/gnome-software.service ]]; then
  verify_user_units gnome-software.service
fi

echo "Checking repository conventions..."
if find \
  "$ROOT_DIR/files/system/usr/lib/systemd/system-preset" \
  "$ROOT_DIR/files/system/usr/lib/systemd/user-preset" \
  -type f -print -quit 2>/dev/null | grep -q .; then
  echo "Systemd presets must not duplicate the BlueBuild systemd module." >&2
  exit 1
fi

for unit in "${system_units[@]}" "${user_units[@]}"; do
  unit_name="${unit##*/}"
  if [[ "$unit_name" != silverblue-* ]]; then
    echo "Custom unit is missing the silverblue- prefix: $unit" >&2
    exit 1
  fi
done

while IFS= read -r command; do
  relative_path="${command#/usr/libexec/silverblue/}"
  helper="$ROOT_DIR/files/system/usr/libexec/silverblue/$relative_path"
  if [[ ! -x "$helper" ]]; then
    echo "Unit helper is missing or not executable: $helper" >&2
    exit 1
  fi
done < <(
  awk -F= '
    /^Exec(Start|StartPre|Condition)=/ {
      command = $2
      sub(/^-/, "", command)
      sub(/[[:space:]].*$/, "", command)
      if (command ~ /^\/usr\/libexec\/silverblue\//) {
        print command
      }
    }
  ' "${system_units[@]}" "${user_units[@]}" | sort -u
)

calendar_timers=(
  "$SYSTEM_UNIT_DIR/rpm-ostreed-automatic.timer.d/override.conf"
  "$USER_UNIT_DIR"/silverblue-*.timer
)
for timer in "${calendar_timers[@]}"; do
  for directive in OnCalendar Persistent RandomizedOffsetSec AccuracySec; do
    if ! grep -q "^${directive}=" "$timer"; then
      echo "Timer is missing ${directive}: $timer" >&2
      exit 1
    fi
  done

  if grep -Eq '^OnBootSec=.+$' "$timer"; then
    echo "Persistent calendar timer must not also use OnBootSec: $timer" >&2
    exit 1
  fi
done

echo "Analyzing system service hardening..."
SYSTEMD_UNIT_PATH="$VALIDATION_SYSTEM_UNIT_DIR:/usr/lib/systemd/system" \
  systemd-analyze security \
    --offline=yes \
    --threshold=90 \
    --json=short \
    silverblue-autologin.service \
    silverblue-flatpak-remove-fedora-remotes.service \
    >"$TMPDIR/security.json"
