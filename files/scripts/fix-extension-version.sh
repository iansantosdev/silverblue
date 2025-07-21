#!/bin/bash

set -oue pipefail

FILE=/usr/share/gnome-shell/extensions/sp-tray@sp-tray.esenliyim.github.com/metadata.json
jq '.["shell-version"] += ["48"]' $FILE > tmp && mv tmp $FILE
