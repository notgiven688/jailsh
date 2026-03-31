#!/usr/bin/env bash
# Usage: [sudo] bash install.sh
#   PREFIX=~/.local bash install.sh   # install per-user
set -euo pipefail

prefix="${PREFIX:-/usr/local}"

install -d "$prefix/bin"
install -m 0755 jail-sh "$prefix/bin/jail-sh"

printf 'Installed to %s/bin/jail-sh\n' "$prefix"
