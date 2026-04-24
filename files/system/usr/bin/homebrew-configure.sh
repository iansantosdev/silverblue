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
  "age"
  "autorestic"
  "bat"
  "chezmoi"
  "cosign"
  "exiftool"
  "eza"
  "fd"
  "fish"
  "forgejo-cli"
  "fzf"
  "gemini-cli"
  "gh"
  "glab"
  "go"
  "htop"
  "hugo"
  "just"
  "node"
  "nvtop"
  "opencode"
  "rclone"
  "restic"
  "ripgrep"
  "sd"
  "sevenzip"
  "shellcheck"
  "smartmontools"
  "sshfs"
  "tokei"
  "unar"
  "vim"
  "yt-dlp"
  "zoxide"
)

casks=(
  "codex"
)

installed_packages=$(brew list --formula)
installed_casks=$(brew list --cask)
packages_to_install=()
for pkg in "${packages[@]}"; do
  if ! echo "${installed_packages}" | grep -Fxq "$pkg"; then
    packages_to_install+=("$pkg")
  fi
done

casks_to_install=()
for cask in "${casks[@]}"; do
  if ! echo "${installed_casks}" | grep -Fxq "$cask"; then
    casks_to_install+=("$cask")
  fi
done

if [ ${#packages_to_install[@]} -gt 0 ] || [ ${#casks_to_install[@]} -gt 0 ]; then
  notify-send --app-name="Homebrew" "Default Packages" "Installing..."

  if [ ${#packages_to_install[@]} -gt 0 ]; then
    echo "Installing Homebrew packages: ${packages_to_install[*]}..."
    brew install --quiet "${packages_to_install[@]}"
  fi

  if [ ${#casks_to_install[@]} -gt 0 ]; then
    echo "Installing Homebrew casks: ${casks_to_install[*]}..."
    brew install --cask --quiet "${casks_to_install[@]}"
  fi

  notify-send --app-name="Homebrew" "Default Packages" "Finished installing"
else
  echo "All required Homebrew packages and casks are already installed."
fi
