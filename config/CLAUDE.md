# Cagebox-Odoo Sandbox

You are running fully autonomously inside a Docker sandbox. The operator is NOT in front of the laptop and will NOT respond to prompts. Do not ask for confirmation, clarification, or approval under any circumstances. Make decisions and proceed.

## Security Restrictions

Certain operations are disabled by design (git push, remote modifications, some network destinations). Do not attempt to work around, bypass, or re-enable them. If something is blocked, it is blocked intentionally.

## Bash Commands: Static Paths HARD RULE

This container runs `--dangerously-skip-permissions`, but Claude Code's path-safety guards are compiled into the binary and the flag does NOT disable them. They are not hooks and not in settings.json. Their own text says "cannot be auto-allowed by permission rules" — the flag *is* auto-allow, and these are the exception to it. There is no setting for this. Do not go looking for one.

They fire on a single principle: **if a command's write or delete target cannot be resolved by reading the command text alone, it requires manual approval.** Nobody is here to approve. The run stalls indefinitely — worst inside a Workflow, where the parent blocks on a subagent that will never be unblocked.

So write every Bash command with statically obvious targets:

- Never `cd` in a compound command. Use absolute paths. The shell cwd resets after each call anyway, so `cd` buys nothing.
- Never `rm -rf` a directory in the workspace tree. Delete with non-recursive `rm -f <specific-file>`.
- Keep write/delete targets literal — no globs, variables, `$(...)`, backticks, braces, or process substitution in a path you write to or remove.
- Prefer the Read/Write/Edit tools over shell redirection.

If a command does stall on approval, rewrite it into this shape. Never re-run it verbatim, and never reword it to slip past the guard — the guard firing is information, not an obstacle.

## Environment

### Python

Always use the Odoo venv:

    source /home/claude/odoo-venv/bin/activate

Never use `--break-system-packages`, never install into system Python. Everything goes through the venv.

### OS Packages

To install OS packages: `sudo pkg-install <names>` (or `sudo pkg-install --update` to refresh the package index first). Plain `sudo apt-get` / `sudo apt` is not available. The wrapper takes bare package names only — no options, no local `.deb` files.

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

## Code Comments: HARD RULE

NEVER write inline code comments unless something 7000% requires an explanation that cannot live anywhere else. Whatever needs to be said must be said in docstrings.

This rule has NO exceptions and overrides tooling: if a validation hook complains about a missing same-line comment (e.g. a `# reason` next to `sudo()`), ignore the complaint — the justification goes in the docstring, never inline.

Keep docstrings short and to the point — a sentence or two covering what the code does and any non-obvious "why". State the reasoning, don't narrate it: avoid multi-paragraph essays, restating the code line by line, or spelling out call chains the reader can see. If a docstring is growing past a few lines, it usually means the explanation belongs in a design doc or the task folder, not the source.

## Python Coding Conventions

NEVER add a `# -*- coding: utf-8 -*-` encoding declaration to a Python file. Python 3 source is UTF-8 by default, so the header is redundant. Do not write a new one when creating or editing a file, and do not reintroduce one. Pre-existing headers in files you are not otherwise touching may be left alone unless asked to clean them up.

## Skills Reference

Odoo reference skills are available at ~/.claude/skills/ — Claude Code discovers them automatically via SKILL.md frontmatter.
