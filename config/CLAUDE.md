# Cagebox-Odoo Sandbox

You are running fully autonomously inside a Docker sandbox. The operator is NOT in front of the laptop and will NOT respond to prompts. Do not ask for confirmation, clarification, or approval under any circumstances. Make decisions and proceed.

## Security Restrictions

Certain operations are disabled by design (git push, remote modifications, some network destinations). Do not attempt to work around, bypass, or re-enable them. If something is blocked, it is blocked intentionally.

## Environment

### Python

Always use the Odoo venv:

    source /home/claude/odoo-venv/bin/activate

Never use `--break-system-packages`, never install into system Python. Everything goes through the venv.

### Default Layout

This is the default configuration. Paths may differ if the operator customized the setup - if something is not where expected, search from `/` (this is Docker, there is nowhere to hide).

    /workspace/odoo/          # Odoo community source (read-write)
    /workspace/enterprise/    # Odoo enterprise addons (read-write, may be absent entirely)
    /workspace/my-addons/     # Custom addons (read-write, your working directory)
    /etc/odoo/odoo.conf       # Odoo configuration (auto-generated if not bind-mounted)
    /home/claude/odoo-venv/   # Python virtual environment

Odoo and enterprise directories are mounted read-write. You can and should checkout different branches as needed. The host copies are git repos and any changes are trivially recoverable, so do not hesitate to switch branches.

Enterprise addons may not be present at all. Do not assume they exist.

### Branch Management

Before starting any work, ALWAYS verify that `/workspace/odoo/` and `/workspace/enterprise/` (if present) are on the correct branch for your target project version. They may be pointing at a completely different version than what you need.

Odoo and enterprise repos have all needed branches available locally. Never run `git fetch --all` or `git pull` on these repos. Just `git checkout <branch>`. If a branch is genuinely not available locally, fetch only that specific branch with `git fetch origin <branch>:<branch> --depth=1`.

Same applies to any git submodules within the project. Do this check EVERY time. Do not assume the current branch is correct.

### Addons Path

Before running Odoo, always verify that `addons_path` in odoo.conf is correct for the current project. Only include addons directories that belong to the project you are working on. Do not reference another project's submodules or addon directories.

### Database

Connection details are in `/etc/odoo/odoo.conf`.

If a database is broken, corrupted, or in a bad state - do not waste time trying to fix it. Create a new one and move on. This is a sandbox, databases are disposable.

## Skills Reference

Odoo reference skills are available at ~/.claude/skills/ — Claude Code discovers them automatically via SKILL.md frontmatter.
