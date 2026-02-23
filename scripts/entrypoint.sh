#!/bin/bash
set -euo pipefail

if [ -f /run/secrets/anthropic_key ]; then
    export ANTHROPIC_API_KEY=$(cat /run/secrets/anthropic_key)
fi

rm -f /home/claude/.gitconfig

if [ -n "${GITHUB_TOKEN:-}" ]; then
  HOME=/home/claude git config --global url."https://${GITHUB_TOKEN}@github.com/".insteadOf "git@github.com:"
  HOME=/home/claude git config --global --add url."https://${GITHUB_TOKEN}@github.com/".insteadOf "ssh://git@github.com/"
  HOME=/home/claude git config --global --add url."https://${GITHUB_TOKEN}@github.com/".insteadOf "https://github.com/"
else
  HOME=/home/claude git config --global url."https://github.com/".insteadOf "git@github.com:"
  HOME=/home/claude git config --global --add url."https://github.com/".insteadOf "ssh://git@github.com/"
fi

if [ -n "${GIT_USER_NAME:-}" ]; then
    HOME=/home/claude /usr/local/lib/git-bin/git config --global user.name "$GIT_USER_NAME"
fi
if [ -n "${GIT_USER_EMAIL:-}" ]; then
    HOME=/home/claude /usr/local/lib/git-bin/git config --global user.email "$GIT_USER_EMAIL"
fi

chown root:root /home/claude/.gitconfig
chmod 444 /home/claude/.gitconfig

su claude -c 'source /home/claude/odoo-venv/bin/activate && pip install --quiet "setuptools<81"'
for req in /workspace/*/requirements.txt; do
    [ -f "$req" ] && su claude -c "source /home/claude/odoo-venv/bin/activate && pip install --quiet -r $req" || true
done

if [ ! -f /etc/odoo/odoo.conf ]; then
    sudo mkdir -p /etc/odoo
    ADDONS_PATH="/workspace/odoo/addons,/workspace/my-addons"
    if [ -d /workspace/enterprise ]; then
        ADDONS_PATH="$ADDONS_PATH,/workspace/enterprise"
    fi
    cat > /tmp/odoo.conf <<EOF
[options]
db_host = ${ODOO_DB_HOST:-db}
db_port = ${ODOO_DB_PORT:-5432}
db_user = ${ODOO_DB_USER:-odoo}
db_password = ${ODOO_DB_PASSWORD:-odoo}
addons_path = $ADDONS_PATH
data_dir = /var/lib/odoo
admin_passwd = admin
list_db = True
without_demo = all
EOF
    sudo mv /tmp/odoo.conf /etc/odoo/odoo.conf
fi

if [ ! -f /home/claude/.claude/CLAUDE.md ]; then
    cp /config/CLAUDE.md /home/claude/.claude/CLAUDE.md
    chown claude:claude /home/claude/.claude/CLAUDE.md
fi

if [ ! -d /home/claude/.claude/skills ]; then
    cp -r /config/skills /home/claude/.claude/skills
    chown -R claude:claude /home/claude/.claude/skills
fi

if [ -f /scripts/setup-tools.sh ]; then
    su -c '/scripts/setup-tools.sh' claude
fi

if [ ! -L /home/claude/.claude.json ]; then
    rm -f /home/claude/.claude.json
    ln -s /home/claude/.claude/claude.json /home/claude/.claude.json
fi

su claude -c 'tmux new-session -d -s main -x 220 -y 50'
exec su claude -c 'exec tail -f /dev/null'
