#!/usr/bin/env bash

set -euo pipefail

readonly EXTENSIONS_URL="https://extensions.gnome.org"
readonly EXTENSIONS_DIR="/usr/share/gnome-shell/extensions"
readonly SCHEMAS_DIR="/usr/share/glib-2.0/schemas"
readonly LOCALES_DIR="/usr/share/locale"
readonly -a CURL_ARGS=(
  --fail
  --silent
  --show-error
  --location
  --retry 3
  --connect-timeout 30
  --max-time 300
)

die() {
  echo "ERROR: $*" >&2
  exit 1
}

fetch() {
  curl "${CURL_ARGS[@]}" "$@"
}

get_json_array INSTALL 'try .["install"][]' "$1"
get_json_array UNINSTALL 'try .["uninstall"][]' "$1"

if (( ${#INSTALL[@]} == 0 && ${#UNINSTALL[@]} == 0 )); then
  die "No extensions were specified to install or uninstall"
fi

command -v gnome-shell >/dev/null 2>&1 \
  || die "GNOME Shell is not installed; GNOME extensions are not supported"

gnome_version_output="$(gnome-shell --version)"
if [[ ! "$gnome_version_output" =~ ([0-9]+) ]]; then
  die "Could not determine the GNOME Shell version from: ${gnome_version_output}"
fi
readonly GNOME_VERSION="${BASH_REMATCH[1]}"

TMP_DIR="$(mktemp -d)"
readonly TMP_DIR
trap 'rm -rf "$TMP_DIR"' EXIT

echo "GNOME version: ${GNOME_VERSION}"

get_extension_info() {
  local identifier="$1"
  local response match_count

  if [[ "$identifier" =~ ^[0-9]+$ ]]; then
    EXT_JSON_DATA="$(fetch "${EXTENSIONS_URL}/extension-info/?pk=${identifier}")" \
      || die "Could not fetch extension with PK ID '${identifier}'"

    jq -e '.pk != null' >/dev/null <<<"$EXT_JSON_DATA" \
      || die "Extension with PK ID '${identifier}' does not exist"
  else
    response="$(
      fetch --get --data-urlencode "search=${identifier}" \
        "${EXTENSIONS_URL}/extension-query/"
    )" || die "Could not search for extension '${identifier}'"

    EXT_JSON_DATA="$(
      jq -ce --arg name "$identifier" \
        '[.extensions[] | select(.name == $name)]' <<<"$response"
    )" || die "The extension search returned invalid data"

    match_count="$(jq -r 'length' <<<"$EXT_JSON_DATA")"
    case "$match_count" in
      0)
        die "Extension '${identifier}' does not exist (names are case-sensitive)"
        ;;
      1)
        EXT_JSON_DATA="$(jq -c '.[0]' <<<"$EXT_JSON_DATA")"
        ;;
      *)
        die "Multiple extensions are named '${identifier}'; use the PK ID from the extension URL"
        ;;
    esac
  fi

  EXT_UUID="$(jq -er '.uuid | select(type == "string" and length > 0)' <<<"$EXT_JSON_DATA")" \
    || die "Extension '${identifier}' has no valid UUID"
  EXT_NAME="$(jq -er '.name | select(type == "string" and length > 0)' <<<"$EXT_JSON_DATA")" \
    || die "Extension '${identifier}' has no valid name"
  [[ "$EXT_UUID" != */* && "$EXT_UUID" != "." && "$EXT_UUID" != ".." ]] \
    || die "Extension '${identifier}' returned an unsafe UUID"
}

get_suitable_version() {
  local version
  local shell_version="$GNOME_VERSION"

  while (( shell_version >= 40 )); do
    if version="$(
      jq -er --arg shell_version "$shell_version" \
        '.shell_version_map[$shell_version].version // empty' <<<"$EXT_JSON_DATA"
    )"; then
      SUITABLE_VERSION="$version"
      if (( shell_version != GNOME_VERSION )); then
        echo "Using '${EXT_NAME}' release for GNOME ${shell_version}; no GNOME ${GNOME_VERSION} release is available"
      fi
      return
    fi
    shell_version=$((shell_version - 1))
  done

  die "Extension '${EXT_NAME}' has no release compatible with GNOME ${GNOME_VERSION} or an earlier supported version"
}

install_schemas() {
  local source_dir="$1"
  local extension_dir="$2"
  local destination
  local -a schema_files

  shopt -s nullglob
  schema_files=("${source_dir}/schemas/"*.gschema.xml)
  shopt -u nullglob
  (( ${#schema_files[@]} > 0 )) || return

  echo "Installing extension schemas"
  case "$EXT_UUID" in
    flypie@schneegans.github.com|paperwm@paperwm.github.com)
      destination="${extension_dir}/schemas"
      install -d -m 0755 "$destination"
      install -p -m 0644 "${schema_files[@]}" "$destination/"
      glib-compile-schemas "$destination" >/dev/null
      ;;
    *)
      install -d -m 0755 "$SCHEMAS_DIR"
      install -p -m 0644 "${schema_files[@]}" "$SCHEMAS_DIR/"
      ;;
  esac
}

install_locales() {
  local source_dir="$1"
  local locale_file

  [[ -d "${source_dir}/locale" ]] || return
  locale_file="$(find "${source_dir}/locale" -type f -name '*.mo' -print -quit)"
  [[ -n "$locale_file" ]] || return

  echo "Installing extension locales"
  install -d -m 0755 "$LOCALES_DIR"
  cp -a "${source_dir}/locale/." "$LOCALES_DIR/"
}

install_extension() {
  local identifier="$1"
  local archive source_dir extension_dir url work_dir

  get_extension_info "$identifier"
  get_suitable_version

  work_dir="$(mktemp -d "${TMP_DIR}/extension.XXXXXX")"
  archive="${work_dir}/extension.zip"
  source_dir="${work_dir}/source"
  extension_dir="${EXTENSIONS_DIR}/${EXT_UUID}"
  url="${EXTENSIONS_URL}/extension-data/${EXT_UUID//@/}.v${SUITABLE_VERSION}.shell-extension.zip"

  echo "Installing '${EXT_NAME}' version ${SUITABLE_VERSION}"
  fetch "$url" --output "$archive"
  install -d -m 0755 "$source_dir"
  unzip -q "$archive" -d "$source_dir"

  rm -rf "$extension_dir"
  install -d -m 0755 "$extension_dir"
  find "$source_dir" -mindepth 1 -maxdepth 1 \
    ! -name locale ! -name schemas \
    -exec cp -a -- {} "$extension_dir/" \;
  find "$extension_dir" -type d -exec chmod 0755 {} +
  find "$extension_dir" -type f -exec chmod 0644 {} +

  install_schemas "$source_dir" "$extension_dir"
  install_locales "$source_dir"

  echo "Extension '${EXT_NAME}' installed successfully"
}

uninstall_extension() {
  local identifier="$1"
  local extension_dir metadata gettext_domain settings_schema schema_location

  get_extension_info "$identifier"
  extension_dir="${EXTENSIONS_DIR}/${EXT_UUID}"
  metadata="${extension_dir}/metadata.json"

  [[ -d "$extension_dir" ]] \
    || die "Extension '${EXT_NAME}' is not installed in the base image"
  [[ -f "$metadata" ]] \
    || die "Installed extension '${EXT_NAME}' has no metadata.json"

  gettext_domain="$(jq -er '."gettext-domain" // ""' "$metadata")"
  settings_schema="$(jq -er '."settings-schema" // ""' "$metadata")"

  if [[ -n "$gettext_domain" ]]; then
    find "$LOCALES_DIR" -type f -name "${gettext_domain}.mo" -delete
  fi

  if [[ -n "$settings_schema" ]]; then
    [[ "$settings_schema" != */* ]] \
      || die "Installed extension '${EXT_NAME}' has an unsafe settings schema"
    schema_location="${SCHEMAS_DIR}/${settings_schema}.gschema.xml"
  else
    schema_location="${SCHEMAS_DIR}/org.gnome.shell.extensions.${EXT_UUID%%@*}.gschema.xml"
  fi
  rm -f "$schema_location"

  rm -rf "$extension_dir"
  echo "Extension '${EXT_NAME}' uninstalled successfully"
}

for extension in "${INSTALL[@]}"; do
  install_extension "$extension"
done

for extension in "${UNINSTALL[@]}"; do
  uninstall_extension "$extension"
done

echo "Compiling extension schemas"
glib-compile-schemas "$SCHEMAS_DIR" >/dev/null
