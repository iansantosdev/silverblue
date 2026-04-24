#!/bin/bash

set -oue pipefail

FILE=/usr/share/gnome-shell/extensions/sp-tray@sp-tray.esenliyim.github.com/metadata.json
jq '.["shell-version"] += ["50"]' $FILE > tmp && mv tmp $FILE

FILE=/usr/share/gnome-shell/extensions/clipboard-history@alexsaveau.dev/metadata.json
jq '.["shell-version"] += ["50"]' $FILE > tmp && mv tmp $FILE
