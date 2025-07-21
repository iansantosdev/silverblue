#!/bin/bash

set -oue pipefail

CUSTOM_CONF="/etc/gdm/custom.conf"
FIRST_USER=$(getent passwd | awk -F: '$3 >= 1000 && $3 < 60000 { print $1 }' | head -n 1)

if [ -z "$FIRST_USER" ]; then
  echo "No regular user found (UID >= 1000). Autologin will not be configured." >&2
  exit 1
fi

echo "Configuring autologin for user: $FIRST_USER"

sed -i "/^AutomaticLogin=/c\AutomaticLogin=$FIRST_USER" "$CUSTOM_CONF"

touch /etc/autologin-done
