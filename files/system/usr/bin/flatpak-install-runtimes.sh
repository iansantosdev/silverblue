#!/bin/bash

set -oue pipefail

flatpak install --user --noninteractive runtime/org.gtk.Gtk3theme.Adwaita-dark/x86_64/3.22

mkdir -p "$HOME/.config"
touch "$HOME/.config/flatpak-install-runtimes-done"
