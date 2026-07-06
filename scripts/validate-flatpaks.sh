#!/usr/bin/env bash

set -euo pipefail

MODE="${1:-online}"
if [[ "$MODE" != "online" && "$MODE" != "--offline" ]]; then
  echo "usage: $0 [--offline]" >&2
  exit 2
fi

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PREINSTALL_FILE="$ROOT_DIR/files/system/usr/share/flatpak/preinstall.d/silverblue.preinstall"
REMOTE_URL="https://dl.flathub.org/repo/flathub.flatpakrepo"

TMPDIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

EXPECTED_REFS="$TMPDIR/expected-refs"
AVAILABLE_REFS="$TMPDIR/available-refs"
ARCH="$(flatpak --default-arch)"

awk -v arch="$ARCH" '
  function fail(message) {
    print FILENAME ": " message > "/dev/stderr"
    failed = 1
    exit 1
  }

  function emit() {
    if (name == "")
      return
    if (branch == "")
      fail("missing Branch for " name)
    if (collection != "org.flathub.Stable")
      fail("missing or invalid CollectionID for " name)

    kind = runtime == "true" ? "runtime" : "app"
    ref = kind "/" name "/" arch "/" branch
    if (seen[ref]++)
      fail("duplicate ref " ref)
    print ref
    count++
  }

  /^\[Flatpak Preinstall [^]]+\]$/ {
    emit()
    name = $0
    sub(/^\[Flatpak Preinstall /, "", name)
    sub(/\]$/, "", name)
    branch = ""
    collection = ""
    runtime = "false"
    next
  }

  /^Branch=/ {
    branch = substr($0, length("Branch=") + 1)
    next
  }

  /^CollectionID=/ {
    collection = substr($0, length("CollectionID=") + 1)
    next
  }

  /^IsRuntime=/ {
    runtime = substr($0, length("IsRuntime=") + 1)
    if (runtime != "true" && runtime != "false")
      fail("IsRuntime must be true or false")
    next
  }

  /^[[:space:]]*$/ || /^[#;]/ { next }

  { fail("unsupported line: " $0) }

  END {
    if (failed)
      exit 1
    emit()
    if (count == 0)
      fail("no Flatpak refs declared")
  }
' "$PREINSTALL_FILE" > "$EXPECTED_REFS"

if [[ "$MODE" == "--offline" ]]; then
  echo "Validated $(wc -l < "$EXPECTED_REFS") Flatpak declarations"
  exit 0
fi

export HOME="$TMPDIR/home"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
mkdir -p "$XDG_CACHE_HOME" "$XDG_DATA_HOME"

if ! remote_add_output="$(flatpak --user remote-add \
  --if-not-exists \
  --from \
  flathub \
  "$REMOTE_URL" 2>&1)"; then
  printf '%s\n' "$remote_add_output" >&2
  exit 1
fi

flatpak --user remote-modify \
  --collection-id=org.flathub.Stable \
  flathub

remote_collection="$(
  flatpak --user remotes --columns=name,collection |
    awk -F '\t' '$1 == "flathub" { print $2 }'
)"
if [[ "$remote_collection" != "org.flathub.Stable" ]]; then
  echo "Flathub remote has invalid collection ID: $remote_collection" >&2
  exit 1
fi

flatpak --user remote-ls --columns=ref flathub > "$AVAILABLE_REFS"

missing=0
while IFS= read -r ref; do
  if ! grep -Fqx -- "$ref" "$AVAILABLE_REFS"; then
    echo "Flatpak ref is unavailable on Flathub: $ref" >&2
    missing=1
  fi
done < "$EXPECTED_REFS"

if ((missing)); then
  exit 1
fi

echo "Validated $(wc -l < "$EXPECTED_REFS") Flatpak refs against Flathub"
