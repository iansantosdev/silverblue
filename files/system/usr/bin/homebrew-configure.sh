#!/bin/bash

set -euo pipefail

HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"

if [[ ! -x "${HOMEBREW_PREFIX}/bin/brew" ]]; then
  echo "Homebrew is not installed in ${HOMEBREW_PREFIX}. Please install it first."
  exit 1
fi

eval "$("${HOMEBREW_PREFIX}/bin/brew" shellenv)"
export HOMEBREW_NO_ENV_HINTS=1

brew analytics off
brew update --force --quiet

packages=(
  "autorestic"
  "bat"
  "chezmoi"
  "cosign"
  "eza"
  "fd"
  "fish"
  "fzf"
  "htop"
  "just"
  "nvtop"
  "rclone"
  "restic"
  "ripgrep"
  "sd"
  "sevenzip"
  "smartmontools"
  "sshfs"
  "vim"
  "yt-dlp"
  "zoxide"
)

installed_packages=$(brew list --formula)
packages_to_install=()
for pkg in "${packages[@]}"; do
  if ! echo "${installed_packages}" | grep -Fxq "$pkg"; then
    packages_to_install+=("$pkg")
  fi
done

if [ ${#packages_to_install[@]} -gt 0 ]; then
  echo "Installing Homebrew packages: ${packages_to_install[*]}..."
  notify-send --app-name="Homebrew" "Default Packages" "Installing..."
  brew install --quiet "${packages_to_install[@]}"
  notify-send --app-name="Homebrew" "Default Packages" "Finished installing"
else
  echo "All required Homebrew packages are already installed."
fi
