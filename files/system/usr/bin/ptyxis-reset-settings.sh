#!/bin/bash

set -oue pipefail

dconf reset -f /org/gnome/Ptyxis/

mkdir -p "$HOME/.config"
touch "$HOME/.config/ptyxis-reset-settings-done"
