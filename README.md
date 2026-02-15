# Cagebox Odoo — Claude Code Sandbox

Docker sandbox for running Claude Code autonomously with Odoo development tooling. Network-isolated container with a forward proxy whitelist, git push protection, and automatic plugin/MCP setup.

## Prerequisites

- Docker with Compose (Docker Desktop on macOS/Windows, or Docker Engine + Compose plugin on Linux)

## Architecture

Three services on an internal Docker network (no direct internet access):

- **claude-sandbox** — Ubuntu 24.04 with Python 3.12, Node.js 20, Claude Code, and Odoo dependencies
- **db** — PostgreSQL 16
- **squid-proxy** — Forward HTTP proxy bridging internal and external networks, whitelisting specific domains

### Security Model

Five layers of protection:

1. **Container isolation** — Claude runs in a locked-down Ubuntu container with restricted sudo (package installation only) and no host access beyond mounted volumes
2. **Network proxy** — All outbound traffic routes through Squid, which only allows whitelisted domains (PyPI, npm, Anthropic API, GitHub). The GitHub REST API (`api.github.com`) is blocked, preventing programmatic write operations. No direct internet access from the sandbox
3. **Git wrapper** — `git push`, `git remote add/set-url/remove/rename`, `git send-email`, `git request-pull`, `git notes push`, and `git lfs push` are blocked at two levels: a shell wrapper replacing `/usr/bin/git` and a pre-push hook as backup. Both are root-owned and read-only — the container user cannot modify them
4. **Permission deny list** — Claude Code's settings.json blocks push and remote modification commands at the application level, before they reach the git wrapper
5. **Credential scoping** — Designed for use with read-only GitHub tokens. With a fine-grained read-only token, write operations are rejected by GitHub regardless of what happens inside the container

> **Known limitation:** With a write-capable token (such as a classic token with `repo` scope), a sufficiently determined agent could theoretically implement the git push protocol at the raw HTTPS level, bypassing all container-level protections. Squid cannot inspect paths inside HTTPS tunnels, so it cannot distinguish a push from a fetch. A read-only GitHub token eliminates this vector entirely — GitHub rejects the write server-side. Fine-grained read-only tokens are strongly recommended.

## Quickstart

```bash
git clone <this-repo> && cd cagebox-odoo

cp .env.example .env
# Edit .env — see Authentication and GitHub Token below

cp docker-compose.override.example.yml docker-compose.override.yml
# Edit override — mount your Odoo source and addons directories

docker compose build
docker compose up -d
```

## Authentication

Two options for authenticating Claude Code inside the sandbox:

### Option A: OAuth login (recommended for Pro/Max subscribers)

Leave `ANTHROPIC_API_KEY` blank in `.env` and start the container. Then run:

```bash
docker exec -it -u claude claude-sandbox claude login
```

Follow the browser-based OAuth flow. The token is stored in `~/.claude/` inside the container, which is persisted via the `claude-config` volume — you only need to authenticate once.

### Option B: API key

Set `ANTHROPIC_API_KEY` in `.env` with a key from [console.anthropic.com](https://console.anthropic.com). This is pay-per-token and separate from any Pro/Max subscription.

## GitHub Token

For accessing private repositories inside the sandbox, set `GITHUB_TOKEN` in `.env`.

**Recommended: Fine-grained read-only token**

Create a fine-grained token at [github.com/settings/personal-access-tokens/new](https://github.com/settings/personal-access-tokens/new):
- Set "Repository access" to "Only select repositories" and select the repos you need
- Under "Repository permissions", set **Contents** to **Read-only**
- Leave everything else at "No access"

With a read-only token, code cannot be pushed to GitHub even if all sandbox protections are bypassed. This is the strongest guarantee.

**Alternative: Classic token**

Create a classic token at [github.com/settings/tokens/new](https://github.com/settings/tokens/new) with `repo` scope. This grants read AND write access to all repos. The sandbox blocks pushes via git wrapper, pre-push hook, permission deny list, and API blocking — but with a write-capable token, a determined agent could theoretically bypass all container-level protections by implementing the git pack protocol directly over HTTPS to `github.com`. Squid cannot inspect paths inside HTTPS tunnels, so it cannot distinguish a push from a fetch at the network level. A read-only token eliminates this vector entirely by having GitHub reject the write server-side.

The entrypoint automatically rewrites all GitHub URLs (HTTPS, SSH, `git@`) to use token authentication, so `git fetch`, `git pull`, and `git clone` work transparently.

## Monitoring

- **Attach to terminal**: `docker exec -it -u claude claude-sandbox tmux attach -t main` — connects to the sandbox shell. Start Claude Code by running `claude --dangerously-skip-permissions`. Press `Ctrl-B D` to detach without killing the session.
- **Logs**: `docker compose logs -f claude-sandbox`

## Plugins

Claude Code plugins can be auto-installed on first boot. Copy `scripts/setup-plugins.sh.example` to `scripts/setup-plugins.sh`, add your plugin commands, make it executable, and mount it in `docker-compose.override.yml`:

```bash
cp scripts/setup-plugins.sh.example scripts/setup-plugins.sh
chmod +x scripts/setup-plugins.sh
# Edit setup-plugins.sh with your plugin install commands, e.g.:
#   claude plugin marketplace add your-org/your-plugins
#   claude plugin install your-plugin@your-plugins
```

Then uncomment the mount in `docker-compose.override.yml`. Plugins persist across restarts via the `claude-config` volume and only install on first boot.

## MCP Servers

Custom MCP servers can be added on first boot. Copy `scripts/setup-mcps.sh.example` to `scripts/setup-mcps.sh`, add your MCP commands, make it executable, and mount it in `docker-compose.override.yml`:

```bash
cp scripts/setup-mcps.sh.example scripts/setup-mcps.sh
chmod +x scripts/setup-mcps.sh
# Edit setup-mcps.sh with your MCP server commands, e.g.:
#   claude mcp add my-server -- npx -y @some/mcp-server
#   claude mcp add db-server -- npx -y @modelcontextprotocol/server-postgres "postgresql://user:pass@db:5432/mydb"
```

Then uncomment the mount in `docker-compose.override.yml`. MCP servers persist across restarts and only configure on first boot.

## Customization

### Adding domains to the proxy whitelist

Edit `config/squid.conf` and add entries:

```
acl whitelist dstdomain example.com
```

Then restart the proxy: `docker compose restart squid-proxy`

### Mounting project directories

Edit `docker-compose.override.yml`:

```yaml
services:
  claude-sandbox:
    volumes:
      - ~/projects/odoo:/workspace/odoo:ro
      - ~/projects/my-addons:/workspace/my-addons
      - ~/projects/enterprise:/workspace/enterprise:ro
```

### Custom Odoo config

Mount your own config file to skip the auto-generated one:

```yaml
volumes:
  - ./config/odoo.conf:/etc/odoo/odoo.conf
```

## Testing

Run the integration test suite from the host after starting the sandbox:

```bash
./scripts/test-sandbox.sh
```

This verifies container health, git rewrites, push blocking, network filtering, database connectivity, Odoo import, mount permissions, and plugin/MCP installation.

## Build

```bash
docker compose build
docker compose up -d
```

## Rebuild

```bash
docker compose build claude-sandbox
docker compose down
docker compose up -d
```

Preserves all volumes (database, pip cache, claude config, plugins).

## Nuke and rebuild

```bash
docker compose build claude-sandbox
docker compose down -v
docker compose up -d
```

The `-v` flag removes all volumes (pip cache, claude config, database). Use `docker compose down` without `-v` to preserve them.
