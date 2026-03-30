#!/usr/bin/env bash
# Usage: [sudo] bash install.sh
#   PREFIX=~/.local bash install.sh   # install per-user
set -euo pipefail

prefix="${PREFIX:-/usr/local}"

install -d "$prefix/bin"
install -m 0755 jailsh "$prefix/bin/jailsh"

printf 'Installed to %s/bin/jailsh\n' "$prefix"
