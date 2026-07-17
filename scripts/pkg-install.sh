#!/bin/bash
# The ONLY command the claude user may run via sudo. Grants "install named
# packages from the configured repos" and nothing else: no options, no local
# .deb files, no alternate config — so the apt-get -o Pre-Invoke / -c config
# escalation paths are closed while unattended package installs still work.
#
# Usage (from the agent):
#   sudo pkg-install --update
#   sudo pkg-install libnss3 libgbm1 libasound2t64
set -euo pipefail

# sudo env_reset strips the proxy vars, and the sandbox has no direct egress,
# so apt must be pointed at the proxy explicitly. Matches HTTP_PROXY.
export http_proxy="http://squid-proxy:3128"
export https_proxy="http://squid-proxy:3128"

usage() {
    echo "usage: pkg-install <pkg> [pkg...]   |   pkg-install --update" >&2
    exit 1
}

[ "$#" -ge 1 ] || usage

if [ "$1" = "--update" ] && [ "$#" -eq 1 ]; then
    exec /usr/bin/apt-get update
fi

for pkg in "$@"; do
    case "$pkg" in
        -*)        echo "pkg-install: options are not allowed ('$pkg')" >&2; exit 1 ;;
        */*|*.deb) echo "pkg-install: local/path installs are not allowed ('$pkg')" >&2; exit 1 ;;
    esac
    if ! printf '%s' "$pkg" | grep -qE '^[a-zA-Z0-9][a-zA-Z0-9.+:-]*$'; then
        echo "pkg-install: invalid package name '$pkg'" >&2
        exit 1
    fi
done

exec /usr/bin/apt-get install -y --no-install-recommends "$@"
