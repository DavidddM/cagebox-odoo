---
name: odoo-server-config
description: CLI flags, odoo.conf parameters, addons_path resolution, database management, logging, dev mode, cron, performance tuning, and server_wide_modules for Odoo 17-19. Consult when configuring servers, debugging, or optimizing performance.
---

# Odoo Server Configuration

> CLI flags, `odoo.conf` parameters, `addons_path` resolution, database management, logging, dev mode, cron, performance tuning, and `server_wide_modules` for Odoo 17–19. Consult when configuring servers, debugging, or optimizing performance.

---

## Key CLI Flags

```bash
odoo-bin -d mydb -i module1,module2    # install modules
odoo-bin -d mydb -u module1            # update modules
odoo-bin --dev=all -d mydb             # development mode
odoo-bin shell -d mydb                 # interactive Python shell
odoo-bin scaffold my_module ./addons   # create module skeleton
```

---

## `addons_path` Resolution

Comma-separated list of absolute directory paths. Paths stripped of whitespace, expanded, resolved to absolute.

> **v17/v18:** Stored as comma-separated string. Invalid paths raise hard error.

> **Changed in v19:** Stored as `list[str]`. Invalid paths **warned and skipped** instead of error. Uses `ChainMap` priority: `_runtime_options` > `_cli_options` > `_env_options` > `_file_options` > `_default_options`.

### Module Search Order

Module discovery uses `odoo.addons.__path__`. `get_module_path()` returns the **first match**. First path wins.

### Enterprise Overlay

Enterprise modules override Community purely through **path order**:

```ini
addons_path = /path/to/enterprise,/path/to/community,/path/to/custom
```

Enterprise must appear **before** community. No special overlay mechanism.

### Runtime Modification

`addons_path` cannot be changed at runtime meaningfully. `odoo.addons.__path__` is populated once at startup by `initialize_sys_path()`.

---

## Database Management

All mutating DB operations require `list_db=True` and master password.

### Create

```python
exp_create_database(db_name, demo, lang, user_password='admin', login='admin', country_code=None, phone=None)
```

Process: `CREATE DATABASE` with `LC_COLLATE 'C'` → `pg_trgm` + optional `unaccent` → install `base`.

### Duplicate

```python
exp_duplicate_database(db_original_name, db_name, neutralize_database=False)
```

Creates via `CREATE DATABASE ... TEMPLATE`, copies filestore, generates new `dbuuid`.

### Drop

```python
exp_drop(db_name)
```

Drops PostgreSQL database AND deletes filestore directory.

### List

**Endpoint:** `POST /web/database/list` (auth `none`). **Function:** `exp_list()` → `list_dbs()`.

Logic: if `list_db` is `False`: raises `AccessDenied`. If `dbfilter` empty and `db_name` set: returns `db_name` split by commas. Otherwise: queries `pg_database` for databases owned by current user.

> **Changed in v19:** Returns `sorted(config['db_name'])` directly (a list, since `db_name` is now `list` type).

### `dbfilter`

Python regex. Placeholders: `%h` (full hostname), `%d` (first subdomain).

```ini
dbfilter = ^%d$           # DB name must match first subdomain
dbfilter = ^mydb$         # Only expose 'mydb'
```

### `db_maxconn` — Connection Pooling

Default: `64`. Single global `ConnectionPool` shared across all databases. Gevent workers can use separate `db_maxconn_gevent` limit.

---

## Logging

### `log_level` Values

| Value | Effect |
|---|---|
| `info` | Default |
| `debug` | `odoo:DEBUG`, `odoo.sql_db:INFO` |
| `debug_sql` | `odoo.sql_db:DEBUG` — log all SQL queries |
| `debug_rpc` | `odoo:DEBUG`, `odoo.http.rpc.request:DEBUG` |
| `debug_rpc_answer` | `odoo:DEBUG`, `odoo.http.rpc:DEBUG` — includes responses |
| `warn` | `odoo:WARNING`, `werkzeug:WARNING` |
| `error` | `odoo:ERROR`, `werkzeug:ERROR` |
| `critical` | `odoo:CRITICAL`, `werkzeug:CRITICAL` |
| `runbot` | `odoo:RUNBOT` (level 25), `werkzeug:WARNING` |

### `log_handler` Syntax

Format: `PREFIX:LEVEL`. Common patterns:

```ini
log_handler = :INFO                              # Root logger at INFO
log_handler = odoo.addons.my_module:DEBUG        # Debug specific addon
log_handler = odoo.models:WARNING                # Silence ORM noise
log_handler = odoo.sql_db:DEBUG                  # Log all SQL queries
log_handler = werkzeug:WARNING                   # Silence werkzeug
log_handler = odoo.http.rpc.request:DEBUG        # Debug RPC requests
```

Application order: `DEFAULT_LOG_CONFIGURATION` → `PSEUDOCONFIG_MAPPER[log_level]` → `log_handler` entries. Last value for a given logger wins.

### In-Code Pattern

```python
import logging
_logger = logging.getLogger(__name__)
```

For `odoo/addons/sale/models/sale_order.py`, `__name__` → `odoo.addons.sale.models.sale_order`.

### `log_db` — Database Logging

Set to database name or connection URI. Logs written to `ir_logging` table. Special value `%d` = current database. `log_db_level` default: `'warning'`.

### Log Format

Hardcoded, not configurable: `%(asctime)s %(pid)s %(levelname)s %(dbname)s %(name)s: %(message)s %(perf_info)s`

Colored output automatic on POSIX TTYs (or when `ODOO_PY_COLORS` env var set).

### `--syslog`

Enables syslog output. **Mutually exclusive with `--logfile`** (hard error if both set). Platform sockets: Linux `/dev/log`, macOS `/var/run/log`, Windows NT Event Log. Syslog format: `Odoo Server {version}:%(dbname)s:%(levelname)s:%(name)s:%(message)s`.

---

## `odoo.conf` Parameter Reference

### Paths & Data

| Parameter | Default | CLI Flag | Description |
|---|---|---|---|
| `data_dir` | `~/.local/share/Odoo` | `-D` | Root for filestore, sessions, addons data |
| `addons_path` | auto-detected | `--addons-path` | Addon directories |
| `server_wide_modules` | `base,web` (v17/v18), `base,rpc,web` (v19) | `--load` | Modules loaded for all DBs before registry |
| `upgrade_path` | (empty) | `--upgrade-path` | Additional migration script paths |

### Database

| Parameter | Default | CLI Flag | Description |
|---|---|---|---|
| `db_host` | `False`/`''` (v19) | `--db_host` | PostgreSQL host |
| `db_port` | `False`/`None` (v19) | `--db_port` | PostgreSQL port |
| `db_user` | `False`/`''` (v19) | `-r` | PostgreSQL user |
| `db_password` | `False`/`''` (v19) | `-w` | PostgreSQL password |
| `db_name` | `False`/`[]` (v19) | `-d` | Database name(s) |
| `db_template` | `template0` | `--db-template` | Template for new DBs |
| `db_sslmode` | `prefer` | `--db_sslmode` | SSL mode |
| `db_maxconn` | `64` | `--db_maxconn` | Max connections |
| `dbfilter` | `''` | `--db-filter` | Regex filter |

> **v18+:** `db_replica_host`, `db_replica_port` added.

> **v19:** `db_name` stored as list. `db_app_name` added (default: `odoo-{pid}`). Env vars: `PGDATABASE`, `PGHOST`, etc.

### Security

| Parameter | Default | CLI Flag | Description |
|---|---|---|---|
| `admin_passwd` | `'admin'` | — (file only) | Master password. Stored hashed (pbkdf2_sha512) |
| `list_db` | `True` | `--no-database-list` | Enable DB listing/management |
| `proxy_mode` | `False` | `--proxy-mode` | Trust `X-Forwarded-*` headers |

### HTTP

| Parameter | Default | CLI Flag | Description |
|---|---|---|---|
| `http_port` | `8069` | `-p` | HTTP port |
| `http_interface` | `''` (v17/v18), `'0.0.0.0'` (v19) | `--http-interface` | Bind address |
| `http_enable` | `True` | `--no-http` | Disable HTTP |
| `gevent_port` | `8072` | `--gevent-port` | WebSocket/longpolling port |

> **v17 only:** `longpolling_port` exists as deprecated alias.

> **v18+:** `longpolling_port` removed.

> **v19:** `http_interface` default `'0.0.0.0'`, will change to `127.0.0.1` in v20. Hidden `--xmlrpc-*` aliases removed.

### Testing

| Parameter | Default | CLI Flag | Description |
|---|---|---|---|
| `test_enable` | `False` | `--test-enable` | Run tests after install/update |
| `test_tags` | `None` | `--test-tags` | Filter spec. Implicitly enables `test_enable` |
| `without_demo` | `False` (v17/v18) | `--without-demo` | Disable demo data |

> **Changed in v19:** `--without-demo` inverted to `with_demo` (default `False`). New `--with-demo` flag. `--test-enable`/`--test-tags` imply `--stop-after-init`. New `--reinit` flag.

### Performance

```ini
[options]
workers = 8                    # (CPUs * 2) + 1; -1 for auto in v18+
max_cron_threads = 1
limit_memory_soft = 2147483648  # 2 GiB per worker
limit_memory_hard = 2684354560  # 2.5 GiB per worker
limit_time_cpu = 600
limit_time_real = 1200
proxy_mode = True
```

| Parameter | Default | Description |
|---|---|---|
| `unaccent` | `False` | Enable PostgreSQL `unaccent` extension |
| `transient_age_limit` | `1.0` | Hours before TransientModel cleanup |
| `limit_time_worker_cron` | `0` | Max cron worker lifetime (0=disabled) |

> **v18+:** `limit_memory_soft_gevent`, `limit_memory_hard_gevent` added.

### SMTP

| Parameter | Default | CLI Flag |
|---|---|---|
| `email_from` | `''` | `--email-from` |
| `smtp_server` | `localhost` | `--smtp` |
| `smtp_port` | `25` | `--smtp-port` |
| `smtp_ssl` | `False` | `--smtp-ssl` |
| `smtp_user` | `''` | `--smtp-user` |
| `smtp_password` | `''` | `--smtp-password` |

### Internal / File-Only Options

| Parameter | Default | Description |
|---|---|---|
| `csv_internal_sep` | `,` | CSV field separator |
| `websocket_keep_alive_timeout` | `3600` | WebSocket timeout (seconds) |
| `websocket_rate_limit_burst` | `10` | Max WebSocket messages in burst |

> **v19 new file-only:** `bin_path`, `default_productivity_apps`, `import_file_maxbytes` (10MB), `import_file_timeout` (3s), `import_url_regex`, `proxy_access_token`.

---

## `server_wide_modules`

Modules loaded **before any database registry**. They hook into the server at a global level.

- `base` — core ORM, required always
- `web` — web client, HTTP controllers, static assets
- `rpc` — **v19 only**, split from web for RPC handling

Adding modules: `--load=base,web,my_global_module`. Common additions: `bus` (long polling/websocket).

---

## `ir.cron` — Scheduled Actions

```xml
<record id="cron_my_action" model="ir.cron">
    <field name="name">My Cron Job</field>
    <field name="model_id" ref="model_my_model"/>
    <field name="state">code</field>
    <field name="code">model._cron_process()</field>
    <field name="interval_number">1</field>
    <field name="interval_type">days</field>
    <field name="numbercall">-1</field>
    <field name="doall" eval="False"/>
</record>
```

> **v18/v19:** `_trigger(at=datetime)` for on-demand scheduling, `_commit_progress(done, remaining)` for batch processing, auto-deactivation after 5 consecutive failures over 7+ days.

---

## Development Mode (`--dev`)

### `--dev=all` Expansion

| Sub-option | v17 | v18 | v19 | In `all`? |
|---|---|---|---|---|
| `xml` | Yes | Yes | Yes | Yes |
| `reload` | Yes | Yes | Yes | Yes |
| `qweb` | Yes | Yes | Yes | Yes |
| `access` | No | No | **Yes** | **Yes (v19)** |
| `werkzeug` | No | No | **Yes** | No |
| `replica` | No | No | **Yes** | No |

### `--dev=xml`

Views read from filesystem instead of database (when `arch_updated` is `False`). Disables view caching, QWeb template caching, asset caching, and record rule caching.

Only affects server-side QWeb and `ir.ui.view` records. Client-side assets not reloaded.

### `--dev=reload`

Watches addon paths for `.py` file changes. Auto-restarts on change (after compile check). XML files do NOT trigger restart. Only works in threaded mode.

### `--dev=qweb`

QWeb errors include compiled Python code in exception details.

### `--dev=werkzeug` (v19 only)

Enables interactive Werkzeug HTML debugger for HTTP (non-JSONRPC) requests. **Never use in production.**

### `--dev=access` (v19 only)

`AccessError` exceptions include full traceback in log.

### `--dev=replica` (v19 only)

Simulates read-replica deployment using the same DB host.
