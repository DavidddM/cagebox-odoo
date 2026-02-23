---
name: odoo-migrations
description: Migration script structure, openupgradelib utilities, upgrade-util patterns, noupdate handling, version detection, common failure fixes, and complete script examples for Odoo 17-19. Consult before writing any migration script.
---

# Odoo Migrations and Upgrades

> Migration script structure, `openupgradelib` utilities, `upgrade-util` patterns, noupdate handling, version detection, common failure fixes, and complete script examples for Odoo 17–19. Consult before writing any migration script.

---

## Migration Script Structure

```
my_module/migrations/18.0.2.0/
├── pre-rename.py    # Before module update
├── post-migrate.py  # After module update
└── end-cleanup.py   # After ALL modules updated
```

**Function signature:** `def migrate(cr, version):`

**Pre-scripts:** SQL only (models not loaded). **Post-scripts:** Full ORM via `api.Environment(cr, SUPERUSER_ID, {})`. **End-scripts:** All modules loaded.

> **v18+:** Strict signature checking enforced — only `(cr, version)` and `(_cr, _version)` valid. OpenUpgradelib patches this to also allow `(env, version)`.

---

## Version Detection and Conditional Migration

The `version` parameter receives the **previously installed version** of the module (before the upgrade). Format: `"18.0.1.2.3"` or `"1.2.3"` (module-only).

A script runs if: `installed_version < script_version <= current_disk_version`.

### `0.0.0` Special Folder

Scripts in `migrations/0.0.0/` run on **every** version change: `pre` runs first, `post`/`end` run last.

### Conditional Migration Pattern

```python
from odoo.tools.parse_version import parse_version

def migrate(cr, version):
    if not version:
        return  # Fresh install

    if parse_version(version) < parse_version('18.0.2.0'):
        cr.execute("ALTER TABLE ...")
```

### `ir_module_module` Version Fields

```python
# Confusing naming in Odoo:
installed_version = fields.Char('Latest Version', compute='_get_latest_version')  # disk version
latest_version = fields.Char('Installed Version', readonly=True)  # DB version
```

- `latest_version`: stored in DB, updated after successful upgrade. This is what migration scripts receive as `version`.
- `installed_version`: computed field, reads from `__manifest__.py` on disk. This is the target.

---

## `openupgradelib` Utilities

OCA library for migration scripts. Install: `pip install openupgradelib`

```python
from openupgradelib import openupgrade
```

> **v17+:** `load_data()` requires `env` as first arg instead of `cr`.

> **v18+:** `ir.property` table removed — `rename_fields()` skips property renaming for v18+. `convert_to_company_dependent()` is **NOT usable in v18+**.

### Function Reference

| Function | Signature | Use |
|----------|-----------|-----|
| `rename_columns` | `(cr, {table: [(old, new)]})` | Rename SQL columns. Pre-migrate. |
| `rename_tables` | `(cr, [(old, new)])` | Rename SQL tables + sequences/indexes/constraints. Pre-migrate. |
| `rename_models` | `(cr, [(old_model, new_model)])` | Rename model refs in ir_model, ir_model_data, etc. Does NOT rename SQL table. |
| `rename_fields` | `(env, [(model, table, old, new)])` | Full field rename: SQL + ir_model_fields + translations + properties. |
| `rename_xmlids` | `(cr, [(old_id, new_id)], allow_merge=False)` | Rename XML IDs in ir_model_data. |
| `copy_columns` | `(cr, {table: [(old, new, type)]})` | Copy column values to new column. Pre-migrate. |
| `move_field_m2o` | `(cr, pool, old_model, field, m2o_field, new_model, new_field, ...)` | Move field from model A to model B via M2O. Post-migrate. |
| `logged_query` | `(cr, query, args=None)` | Execute SQL with DEBUG logging. Returns `cr.rowcount`. |
| `add_fields` | `(env, [(field, model, table, type, sql_type, module, init_val)])` | Pre-create field column + ir_model_fields entry. |
| `map_values` | `(cr, source_col, target_col, [(old, new)], table=...)` | Map old values to new. Post-migrate. |
| `column_exists` | `(cr, table, column)` → bool | Check PostgreSQL catalog. |
| `table_exists` | `(cr, table)` → bool | Check PostgreSQL catalog. |
| `update_module_moved_fields` | `(cr, model, fields, old_module, new_module)` | Update ir_model_data when fields move modules. |
| `update_module_moved_models` | `(cr, model, old_module, new_module)` | Update all entries when model moves modules. |
| `merge_records` | `(env, model, record_ids, target_id, ...)` | Merge multiple records into one. **Run in end-migrate.** |
| `load_data` | `(env, module, filename, mode='init')` | Load XML/CSV data file. Key for noupdate records. |
| `set_xml_ids_noupdate_value` | `(env, module, xml_ids, value)` | Flip noupdate flag on specific XML IDs. |
| `add_xmlid` | `(cr, module, xmlid, model, res_id, noupdate=False)` | Insert ir_model_data entry for existing record. |
| `delete_records_safely_by_xml_id` | `(env, xml_ids, delete_childs=False)` | Safely unlink records by XML ID with savepoints. |
| `chunked` | `(records, single=True)` | Memory-efficient iteration over large recordsets. |
| `get_legacy_name` | `(original_name)` → str | Generate versioned legacy name. |

### `@openupgrade.migrate()` Decorator

```python
@openupgrade.migrate()
def migrate(env, version):
    # env is provided automatically for v10+
    pass
```

Wraps with savepoint, optional environment creation, and exception logging. `no_version=True` runs even for fresh installs.

---

## Core Odoo Migration Patterns (without `upgrade-util`)

### Pattern 1: Direct `api.Environment` Construction

```python
from odoo import api, SUPERUSER_ID

def migrate(cr, version):
    env = api.Environment(cr, SUPERUSER_ID, {})
```

### Pattern 2: `odoo.tools.sql` — DDL Helpers

```python
from odoo.tools import sql

sql.drop_constraint(cr, 'table_name', 'constraint_name')
sql.add_foreign_key(cr, 'table_name', 'column', 'ref_table', 'ref_column', 'on_delete')
sql.column_exists(cr, 'table_name', 'column_name')
sql.create_column(cr, 'table_name', 'column_name', 'column_type', comment=None)
sql.rename_column(cr, 'table_name', 'old_name', 'new_name')
columns = sql.table_columns(cr, 'table_name')
```

### Pattern 3: `odoo.tools.SQL` — Safe Query Builder (v17+)

```python
from odoo.tools import SQL

cr.execute(SQL(
    "UPDATE account_move SET state = %s WHERE id = ANY(%s)",
    'posted', [1, 2, 3]
))
```

### Pattern 4: `env.ref()` with Safety

```python
record = env.ref('module.xml_id', raise_if_not_found=False)
if record:
    record.unlink()
```

### Pattern 5: Chart of Accounts Reload

```python
for company in env['res.company'].search([('chart_template', '=', 'nl')], order="parent_path"):
    env['account.chart.template'].try_loading('nl', company, force_create=False)
```

### Pattern 6: Direct `ir_model_data` Manipulation

```python
cr.execute("UPDATE ir_model_data SET name=%s WHERE module=%s AND name=%s",
           ('new_name', 'module', 'old_name'))

cr.execute("""
    INSERT INTO ir_model_data(model, module, name, res_id, noupdate)
    VALUES ('res.bank', 'my_module', 'bank_record', %s, True)
    ON CONFLICT DO NOTHING
""", (record_id,))
```

### Pattern 7: `ir_ui_view` Manipulation

```python
cr.execute("""
    UPDATE ir_ui_view SET inherit_id = NULL, mode = 'primary'
    FROM ir_model_data mdata
    WHERE ir_ui_view.id = mdata.res_id
    AND mdata.model = 'ir.ui.view'
    AND mdata.name = 'my_view' AND mdata.module = 'my_module'
""")
```

### Pattern 8: `ir_config_parameter` Reading

```python
cr.execute("SELECT value::int FROM ir_config_parameter WHERE key = %s", ['my.param'])
result = cr.fetchone()
```

### Pattern 9: `COALESCE` for NULL Handling

```python
cr.execute("""
    UPDATE helpdesk_sla
    SET time_days = COALESCE(time_days, 0),
        time_hours = COALESCE(time_hours, 0)
""")
```

---

## Complete Migration Script Examples

### Pre-migrate: Field Rename + Selection Update + Temp Column

```python
# my_module/migrations/18.0.2.0/pre-migrate.py
def migrate(cr, version):
    # 1. Rename field column before ORM loads
    cr.execute("""
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'project_task' AND column_name = 'planned_hours'
    """)
    if cr.fetchone():
        cr.execute('ALTER TABLE project_task RENAME COLUMN planned_hours TO allocated_hours')
        cr.execute("""
            UPDATE ir_model_fields
            SET name = 'allocated_hours'
            WHERE name = 'planned_hours' AND model = 'project.task'
        """)

    # 2. Map old selection values to new ones
    cr.execute("""
        UPDATE project_task
        SET kanban_state = CASE kanban_state
            WHEN 'draft' THEN 'todo'
            WHEN 'open' THEN 'in_progress'
            WHEN 'pending' THEN 'in_progress'
            WHEN 'close' THEN 'done'
            ELSE kanban_state
        END
        WHERE kanban_state IN ('draft', 'open', 'pending', 'close')
    """)

    # 3. Preserve data from a field being removed
    cr.execute("""
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'project_task' AND column_name = 'legacy_partner_id'
    """)
    if cr.fetchone():
        cr.execute("ALTER TABLE project_task ADD COLUMN IF NOT EXISTS _temp_legacy_partner_id INTEGER")
        cr.execute("UPDATE project_task SET _temp_legacy_partner_id = legacy_partner_id WHERE legacy_partner_id IS NOT NULL")
```

### Post-migrate: ORM Data Migration + Recompute

```python
# my_module/migrations/18.0.2.0/post-migrate.py
from odoo import api, SUPERUSER_ID

def migrate(cr, version):
    env = api.Environment(cr, SUPERUSER_ID, {})

    # 1. Move data from temp column to new M2M
    cr.execute("SELECT id, _temp_legacy_partner_id FROM project_task WHERE _temp_legacy_partner_id IS NOT NULL")
    for task_id, partner_id in cr.fetchall():
        task = env['project.task'].browse(task_id)
        partner = env['res.partner'].browse(partner_id)
        if task.exists() and partner.exists():
            task.write({'partner_ids': [(4, partner.id)]})
    cr.execute("ALTER TABLE project_task DROP COLUMN IF EXISTS _temp_legacy_partner_id")

    # 2. Update noupdate record
    action = env.ref('my_module.action_project_tasks', raise_if_not_found=False)
    if action:
        action.write({'domain': [('active', '=', True), ('stage_id.fold', '=', False)]})

    # 3. Force recompute stored computed field
    tasks = env['project.task'].search([])
    tasks._compute_total_allocated()
    env['project.task'].flush_model()
```

### End-migrate: Cleanup with All Modules Loaded

```python
# my_module/migrations/18.0.2.0/end-migrate.py
from odoo import api, SUPERUSER_ID

def migrate(cr, version):
    env = api.Environment(cr, SUPERUSER_ID, {})

    # 1. Clean up orphaned ir.model.data records
    cr.execute("""
        DELETE FROM ir_model_data
        WHERE model = 'project.task.type' AND module = 'my_module'
        AND NOT EXISTS (SELECT 1 FROM ir_model WHERE model = 'project.task.type')
    """)

    # 2. Flip noupdate for re-update
    cr.execute("""
        UPDATE ir_model_data SET noupdate = FALSE
        WHERE module = 'my_module' AND name = 'default_stage_todo'
    """)

    # 3. Remove deprecated view
    deprecated_view = env.ref('my_module.view_task_form_deprecated', raise_if_not_found=False)
    if deprecated_view:
        child_views = env['ir.ui.view'].search([('inherit_id', 'child_of', deprecated_view.id)], order='id desc')
        for view in child_views:
            try:
                view.unlink()
            except Exception:
                view.active = False

    # 4. Reload chart template
    for company in env['res.company'].search([('chart_template', '=', 'my_chart')], order='parent_path'):
        old_tax = env.ref(f'account.{company.id}_tax_deprecated_5pct', raise_if_not_found=False)
        if old_tax:
            old_tax.active = False
        env['account.chart.template'].try_loading('my_chart', company, force_create=False)
```

---

## `noupdate` Record Handling

| Method | Needs openupgradelib | Stage | Overwrites customizations | Granularity |
|--------|---------------------|-------|--------------------------|-------------|
| `load_data(mode='init')` | Yes (or use convert_xml_import) | post/end | Yes (whole file) | File-level |
| `convert_xml_import(mode='init')` | No | post/end | Yes (whole file) | File-level |
| SQL noupdate flip | No | pre/post | Only on next upgrade | Record-level |
| `set_xml_ids_noupdate_value()` | Yes | post/end | Only on next upgrade | Record-level |
| Direct ORM write | No | post/end | No | Field-level |
| `--init` flag | No | Manual | Yes (whole module) | Module-level |

### `convert_xml_import()` without openupgradelib

```python
from odoo.tools import convert_xml_import, file_open

def migrate(cr, version):
    env = api.Environment(cr, SUPERUSER_ID, {})
    with file_open('my_module/data/noupdate_fix.xml', 'rb') as fp:
        convert_xml_import(env, 'my_module', fp, mode='init', noupdate=False)
```

### `forcecreate` Attribute

Records with `forcecreate="1"` (default) are always created if missing, even when `noupdate="1"`. Records with `forcecreate="0"` are only created during init.

---

## Common Migration Failures

| # | Error / Symptom | Fix |
|---|----------------|-----|
| 1 | `ProgrammingError: column "old_name" does not exist` | Pre-migrate: rename SQL column with `ALTER TABLE ... RENAME COLUMN` or `openupgrade.rename_columns()` |
| 2 | `MissingError: Record does not exist` after model rename | Pre-migrate: `UPDATE ir_model_data SET model='new.model' WHERE model='old.model'` |
| 3 | `ValueError` on selection field after upgrade | Pre-migrate: `UPDATE table SET field = 'new_value' WHERE field = 'old_value'` |
| 4 | `IntegrityError: NOT NULL violation` on new required field | Pre-migrate: `ALTER TABLE ADD COLUMN ... DEFAULT ...` or `openupgrade.add_fields()` |
| 5 | `TypeError: 'migrate' signature should be '(cr, version)'` (v18+) | Use exactly `def migrate(cr, version):`. With openupgradelib, use `@openupgrade.migrate()` decorator |
| 6 | `ir.property` errors after v17→v18 | Migrate property values to new column format in pre-migrate |
| 7 | `View error: Field 'x' does not exist` | Pre-migrate: deactivate broken view. For attrs: convert to inline expressions |
| 8 | `CacheMiss` / `RecursionError` during recompute | Explicitly recompute: `records._compute_field()` then `flush_model()` |
| 9 | `IntegrityError: duplicate key` on ir_model_data | Check existence before renaming. Use `rename_xmlids(allow_merge=True)` |
| 10 | Module upgrade hangs / circular dependency | Break cycle by moving shared code to third module |
| 11 | `KeyError: 'field_name'` in pre-migrate | Move to post-migrate or use raw SQL instead of ORM |
| 12 | Data file loads in wrong order | Ensure files loaded in dependency order. Use `load_data()` per file |

---

## `upgrade-util` (Odoo SA)

Odoo's proprietary migration utility for Odoo.sh and enterprise. Install: `pip install git+https://github.com/odoo/upgrade-util@master`

```python
from odoo.upgrade import util

util.rename_field(cr, "model.name", "old_field", "new_field")
util.remove_field(cr, "model.name", "field_name", drop_column=True)
util.rename_model(cr, "old.model", "new.model")
util.remove_model(cr, "model.name")
util.rename_xmlid(cr, "old_module.old_id", "new_module.new_id", noupdate=True)
util.update_record_from_xml(cr, "module.xml_id")
env = util.env(cr)
```

---

## Breaking Changes Summary

**v16→v17:** `attrs`/`states` removed from views, `name_get()` deprecated, `_read_group()` new signature, OWL 1→2, `column_invisible` introduced.

**v17→v18:** `<tree>` → `<list>`, `group_operator` → `aggregator`, `ir.property` removed, `kanban-box` → `card`, `<chatter/>` tag, QUnit → Hoot, `web.assets_unit_tests` bundle.

**v18→v19:** `type='json'` → `type='jsonrpc'`, XML-RPC deprecated for JSON-2 API, `@api.private`, `read_group` deprecated, `record._cr/_context/_uid` deprecated, demo data not loaded by default.
