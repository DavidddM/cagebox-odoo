#!/bin/bash
set -euo pipefail

AUTH_CONF=/run/squid/github-auth.conf
mkdir -p /run/squid

if [ -n "${GITHUB_TOKEN:-}" ]; then
    CREDENTIAL=$(printf '%s' "x-access-token:${GITHUB_TOKEN}" | base64 -w0)
    printf 'request_header_add Authorization "Basic %s" github_fetch\n' "$CREDENTIAL" > "$AUTH_CONF"
else
    : > "$AUTH_CONF"
fi
chown root:proxy "$AUTH_CONF"
chmod 640 "$AUTH_CONF"
unset GITHUB_TOKEN CREDENTIAL

rm -f /run/squid.pid
exec squid -N -f /etc/squid/squid.conf
