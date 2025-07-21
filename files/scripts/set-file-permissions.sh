#!/bin/bash

set -oue pipefail

chmod 400 /etc/doas.conf
chmod 444 /etc/default/tailscaled
