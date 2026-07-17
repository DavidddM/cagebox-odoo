#!/bin/bash
# Cagebox integration tests — run from host after docker compose up -d

PASS=0
FAIL=0
WARN=0

check() {
  local name="$1" expected="$2" actual="$3"
  if echo "$actual" | grep -qiE "$expected"; then
    echo "  ✓ $name"
    PASS=$((PASS+1))
  else
    echo "  ✗ $name"
    echo "    Expected: $expected"
    echo "    Got: $actual"
    FAIL=$((FAIL+1))
  fi
}

warn() {
  local name="$1" msg="$2"
  echo "  ⚠ $name — $msg"
  WARN=$((WARN+1))
}

DC="docker exec -u claude claude-sandbox"

echo ""
echo "=== Cagebox Integration Tests ==="
echo ""

# Wait for container
echo "[1] Container running"
if docker compose ps claude-sandbox | grep -q "Up"; then
  echo "  ✓ claude-sandbox is running"
  PASS=$((PASS+1))
else
  echo "  ✗ claude-sandbox is not running"
  echo "  Run: docker compose logs claude-sandbox --tail 30"
  exit 1
fi

# Wait for entrypoint to finish (tmux session exists)
echo "[2] Entrypoint complete"
for i in $(seq 1 60); do
  if $DC tmux has-session -t main 2>/dev/null; then
    echo "  ✓ tmux session 'main' exists"
    PASS=$((PASS+1))
    break
  fi
  if [ "$i" -eq 60 ]; then
    echo "  ✗ tmux session not created after 60s"
    FAIL=$((FAIL+1))
  fi
  sleep 1
done

# Git rewrites
echo "[3] Git URL rewrites"
GIT_CFG=$($DC git config --global --list 2>&1)
check "insteadOf git@github.com:" "insteadof=git@github.com:" "$GIT_CFG"
check "insteadOf ssh://git@github.com/" "insteadof=ssh://git@github.com/" "$GIT_CFG"
check "insteadOf https://github.com/" "insteadof=https://github.com/" "$GIT_CFG"

# Git push blocking
echo "[4] Git push blocking"
PUSH_OUT=$($DC bash -c "cd /tmp && git init -q test-push && cd test-push && git commit --allow-empty -m test -q && git push https://github.com/test/test.git main 2>&1" || true)
check "push is blocked" "blocked" "$PUSH_OUT"
$DC rm -rf /tmp/test-push 2>/dev/null || true

# Network — allowed
echo "[5] Network — allowed domains"
for domain in pypi.org registry.npmjs.org github.com api.anthropic.com; do
  CODE=$($DC curl -s -o /dev/null -w "%{http_code}" --max-time 10 "https://$domain" 2>&1)
  if [ "$CODE" != "000" ]; then
    echo "  ✓ $domain ($CODE)"
    PASS=$((PASS+1))
  else
    echo "  ✗ $domain (blocked)"
    FAIL=$((FAIL+1))
  fi
done

# Network — blocked
echo "[6] Network — blocked domains"
for domain in google.com facebook.com example.com; do
  CODE=$($DC curl -s -o /dev/null -w "%{http_code}" --max-time 10 "https://$domain" 2>&1)
  if [ "$CODE" = "000" ] || [ "$CODE" = "403" ]; then
    echo "  ✓ $domain (blocked, $CODE)"
    PASS=$((PASS+1))
  else
    echo "  ✗ $domain (NOT blocked, $CODE)"
    FAIL=$((FAIL+1))
  fi
done

# Plugins
if [ -f scripts/setup-tools.sh ]; then
  echo "[7] Plugins"
  PLUGINS=$($DC cat /home/claude/.claude/plugins/installed_plugins.json 2>&1)
  if echo "$PLUGINS" | grep -q '{' && [ -n "$PLUGINS" ]; then
    echo "  ✓ installed_plugins.json exists and is non-empty"
    PASS=$((PASS+1))
  else
    echo "  ✗ installed_plugins.json missing or empty"
    FAIL=$((FAIL+1))
  fi
else
  echo "[7] Plugins"
  echo "  ⚠ skipped (no setup-tools.sh)"
  WARN=$((WARN+1))
fi

# MCP servers
if [ -f scripts/setup-tools.sh ]; then
  echo "[8] MCP servers"
  MCP=$($DC find /home/claude/.claude -name ".mcp.json" -exec cat {} \; 2>&1)
  if echo "$MCP" | grep -q '{' && [ -n "$MCP" ]; then
    echo "  ✓ .mcp.json exists with content"
    PASS=$((PASS+1))
  else
    echo "  ✗ no .mcp.json found or empty"
    FAIL=$((FAIL+1))
  fi
else
  echo "[8] MCP servers"
  echo "  ⚠ skipped (no setup-tools.sh)"
  WARN=$((WARN+1))
fi

# Database
echo "[9] Database"
DB_OUT=$($DC psql -h db -U odoo -d postgres -c "SELECT 1 AS connected" 2>&1)
check "psql connection" "1" "$DB_OUT"

# Odoo import
echo "[10] Odoo Python import"
ODOO_OUT=$($DC bash -c "source /home/claude/odoo-venv/bin/activate && PYTHONPATH=/workspace/odoo python -c 'import odoo; print(\"OK\")'" 2>&1)
check "import odoo" "OK" "$ODOO_OUT"

# Mount permissions
echo "[11] Mount permissions"
RW_ODOO=$($DC bash -c "touch /workspace/odoo/test_rw && rm /workspace/odoo/test_rw && echo WRITABLE" 2>&1)
check "odoo is writable" "WRITABLE" "$RW_ODOO"
RW_OUT=$($DC bash -c "touch /workspace/my-addons/test_rw && rm /workspace/my-addons/test_rw && echo WRITABLE" 2>&1)
check "my-addons is writable" "WRITABLE" "$RW_OUT"

# Pip cache
echo "[12] Pip cache volume"
PIP_OUT=$($DC mount 2>&1)
check "pip cache mounted" "/home/claude/.cache/pip" "$PIP_OUT"

# Sudo lockdown
echo "[13] Sudo lockdown"
SUDO_L=$($DC sudo -n -l 2>&1)
check "pkg-install is granted" "pkg-install" "$SUDO_L"
if echo "$SUDO_L" | grep -qE '/usr/bin/apt|pip'; then
  echo "  ✗ sudoers still grants apt/pip directly"
  FAIL=$((FAIL+1))
else
  echo "  ✓ no direct apt/pip sudo grants"
  PASS=$((PASS+1))
fi
ID_OUT=$($DC id 2>&1)
if echo "$ID_OUT" | grep -q '(sudo)'; then
  echo "  ✗ claude is in the sudo group"
  FAIL=$((FAIL+1))
else
  echo "  ✓ claude not in sudo group"
  PASS=$((PASS+1))
fi

# pkg-install wrapper
echo "[14] pkg-install wrapper"
OPT_OUT=$($DC sudo -n pkg-install -o APT::Update::Pre-Invoke::=id 2>&1 || true)
check "options are refused" "not allowed" "$OPT_OUT"
DEB_OUT=$($DC sudo -n pkg-install ./x.deb 2>&1 || true)
check "local .deb installs are refused" "not allowed" "$DEB_OUT"
INSTALL_OUT=$($DC bash -c "sudo -n pkg-install --update >/dev/null 2>&1; sudo -n pkg-install jq 2>&1" || true)
check "real install works" "newest version|setting up jq" "$INSTALL_OUT"

# Git wrapper
echo "[15] Git wrapper"
BARE_GIT=$($DC git 2>&1 || true)
if echo "$BARE_GIT" | grep -q 'unbound variable'; then
  echo "  ✗ bare git crashes with unbound variable"
  FAIL=$((FAIL+1))
else
  echo "  ✓ bare git exits cleanly"
  PASS=$((PASS+1))
fi

# Managed policy
echo "[16] Managed policy file"
MANAGED_LS=$(docker exec claude-sandbox ls -l /etc/claude-code/managed-settings.json 2>&1)
check "root-owned and read-only" "^-r--r--r-- .* root root" "$MANAGED_LS"
MANAGED=$($DC cat /etc/claude-code/managed-settings.json 2>&1)
check "deny list present" "git push" "$MANAGED"

# Odoo tunnel
echo "[17] Odoo tunnel"
TUNNEL_PS=$(docker compose ps odoo-tunnel 2>&1)
check "odoo-tunnel is running" "Up|running" "$TUNNEL_PS"
TUNNEL_PORT=$(docker compose port odoo-tunnel 8069 2>&1)
check "bound to loopback only" "^127.0.0.1:" "$TUNNEL_PORT"

# Summary
echo ""
echo "=== Results ==="
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo "  WARN: $WARN"
echo ""
if [ "$FAIL" -gt 0 ]; then
  echo "Some tests failed. Check output above."
  exit 1
else
  echo "All tests passed."
fi
