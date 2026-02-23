---
name: odoo-orm
description: Models, field types, inheritance patterns, recordset API, decorators, constraints, cache management, and multi-company rules for Odoo 17-19. Consult for any model/field work or ORM method usage.
---

# Odoo ORM — Models, Fields, Inheritance

> Models, field types, inheritance patterns, recordset API, decorators, constraints, cache management, and multi-company rules for Odoo 17–19. Consult for any model/field work or ORM method usage.

---

## Model Types

Stable across v17/v18/v19:

| Type | `_auto` | Table | Vacuum | Use |
|------|---------|-------|--------|-----|
| `models.Model` | `True` | Yes | No | Regular persistent records |
| `models.TransientModel` | `True` | Yes | Yes (daily) | Wizards, temporary data |
| `models.AbstractModel` | `False` | No | No | Mixins (e.g., `mail.thread`) |

---

## Inheritance Patterns

**Extension (in-place):** `_inherit` without `_name` — adds fields/methods to existing model, no new table:
```python
class ResPartner(models.Model):
    _inherit = 'res.partner'
    custom_field = fields.Char()
```

**Prototypal:** `_inherit` with different `_name` — new model, new table, copies all fields:
```python
class SpecialPartner(models.Model):
    _name = 'special.partner'
    _inherit = 'res.partner'
```

**Delegation:** `_inherits` dict — links via M2O, transparent field access:
```python
class ResUsers(models.Model):
    _name = 'res.users'
    _inherits = {'res.partner': 'partner_id'}
    partner_id = fields.Many2one('res.partner', required=True, ondelete='restrict')
```

**Multiple mixin inheritance:**
```python
class MyModel(models.Model):
    _name = 'my.model'
    _inherit = ['mail.thread', 'mail.activity.mixin']
```

---

## Field Types

**Basic fields (all versions):**
`Char`, `Text`, `Html`, `Integer`, `Float`, `Monetary`, `Boolean`, `Date`, `Datetime`, `Selection`, `Binary`, `Image`, `Reference`

**Relational fields:**
`Many2one(comodel_name)`, `One2many(comodel_name, inverse_name)`, `Many2many(comodel_name)`, `Many2oneReference`

**Special fields:**
- **`fields.Properties`** (v17+): Dynamic JSONB-backed user-defined properties. `definition` param points to parent field storing property definitions.
- No native `fields.Json` type exists in v17–v19.

| Change | Version |
|--------|---------|
| `fields.Properties` added | **v17** |
| `group_operator` → `aggregator` renamed | **v18** (old name deprecated) |
| `models.Constraint()`, `models.Index()`, `models.UniqueIndex()` | **v19** (declarative) |

---

## Field Parameters

**Common:** `string`, `help`, `readonly`, `required`, `index` (True/`'btree'`/`'btree_not_null'`/`'trigram'`), `default`, `groups`, `copy`, `store`, `company_dependent`, `translate`

**Compute-related:** `compute`, `inverse`, `search`, `related`, `precompute`, `compute_sudo`, `recursive`

**Many2one-specific:** `comodel_name`, `ondelete` (`'set null'`/`'restrict'`/`'cascade'`), `auto_join`, `delegate`, `check_company`, `domain`, `context`

**Many2many-specific:** `comodel_name`, `relation`, `column1`, `column2`

**Selection-specific:** `selection`, `selection_add` (with position tuples), `ondelete` (dict)

**Aggregation (version difference):**
```python
# v17:
quantity = fields.Float(group_operator='sum')
# v18+ (preferred):
quantity = fields.Float(aggregator='sum')
```

---

## `Command` Objects for x2many Writes

```python
from odoo import Command

Command.create(values)        # (0, 0, {values}) — create and link
Command.update(id, values)    # (1, id, {values}) — update linked record
Command.delete(id)            # (2, id, 0) — unlink and delete from DB
Command.unlink(id)            # (3, id, 0) — remove link only
Command.link(id)              # (4, id, 0) — add link to existing
Command.clear()               # (5, 0, 0) — remove all links
Command.set(ids)              # (6, 0, [ids]) — replace all links
```

**Cannot use** `delete`, `unlink`, `clear` inside `create()`.

---

## Recordset API Methods

```python
Model.create(vals_list)          # dict or list of dicts → recordset
Model.write(vals)                # → True
Model.unlink()                   # → True
Model.search(domain, offset=0, limit=None, order=None)  # → recordset
Model.search_count(domain, limit=None)  # → int (limit respected since v16+)
Model.search_read(domain, fields, offset, limit, order)  # → list[dict]
Model.search_fetch(domain, field_names, offset, limit, order)  # NEW v17+
records.fetch(field_names)       # NEW v17+ — efficient field prefetch
Model.browse(ids)                # → recordset (no existence check)
records.read(fields)             # → list[dict]
records.copy(default=None)       # → new record
records.exists()                 # → subset that exists in DB
records.ensure_one()             # raises ValueError if len != 1
records.filtered(func)           # callable or field name (truthy check)
records.filtered_domain(domain)  # preserves order (v16+)
records.mapped(func)             # field path → list; M2O/O2M → recordset
records.sorted(key, reverse)     # key = field name or callable
records.grouped(key)             # → dict: key → recordset
```

**Environment alteration:**
```python
record.with_context(**kwargs)    # add/replace context keys
record.with_user(user)           # switch user (access rights apply)
record.with_company(company)     # switch company context
record.sudo()                    # superuser (bypasses access rights + rules)
```

---

## `name_get` Deprecation

| Version | Status | Replacement |
|---------|--------|-------------|
| v17 | **Deprecated** | `_compute_display_name()` |
| v18 | Deprecated; name search via `_search_display_name` | Same |
| v19 | Fully legacy | Same |

```python
# OLD (deprecated):
def name_get(self):
    return [(r.id, f"[{r.code}] {r.name}") for r in self]

# NEW (v17+):
def _compute_display_name(self):
    for rec in self:
        rec.display_name = f"[{rec.code}] {rec.name}"
```

---

## Decorators

| Decorator | Status | Notes |
|-----------|--------|-------|
| `@api.model` | Stable | Method operates on model, not specific records |
| `@api.depends(*fields)` | Stable | Compute dependency tracking, supports dot paths |
| `@api.depends_context(*keys)` | Stable | Context keys for non-stored computes |
| `@api.onchange(*fields)` | Works in all versions | Not formally deprecated, but computed fields preferred |
| `@api.constrains(*fields)` | Stable | Raise `ValidationError` on failure |
| `@api.autovacuum` | Stable | Called by daily vacuum cron |
| `@api.model_create_multi` | Stable | Still applied to `create()` override |
| `@api.ondelete(at_uninstall=False)` | Stable (v15+) | Business logic check during unlink |
| **`@api.private`** | **v19 only** | Prevents RPC access to method |

**Removed:** `@api.one` (pre-v13), `@api.multi` (v13+).

---

## SQL Constraints

```python
# v17/v18 (traditional):
_sql_constraints = [
    ('check_price', 'CHECK(price > 0)', 'Price must be positive.'),
    ('unique_name', 'UNIQUE(name)', 'Name must be unique.'),
]

# v19 (new declarative, additive):
_check_price = models.Constraint('CHECK(price > 0)', 'Price must be positive.')
_name_idx = models.Index('(name)')
_unique_code = models.UniqueIndex('(code)')
```

Old `_sql_constraints` list syntax still works in v19.

---

## Cache Management

v16+ API, used in v17/v18/v19:

```python
self.env.flush_all()                          # flush everything
Model.flush_model(['field1', 'field2'])       # flush model fields
records.flush_recordset(['field1'])            # flush specific records
self.env.invalidate_all()                     # invalidate everything
Model.invalidate_model(['field1'])            # invalidate model
records.invalidate_recordset(['field1'])       # invalidate records
```

---

## Multi-Company

```python
class MyModel(models.Model):
    _name = 'my.model'
    _check_company_auto = True  # auto-check company consistency on write/create

    company_id = fields.Many2one('res.company', default=lambda self: self.env.company)
    partner_id = fields.Many2one('res.partner', check_company=True)
```

> **v19:** `_company_field` model attribute added (defaults to `'company_id'`).

---

## Key ORM Changes by Version

**v17:** `name_get()` deprecated, `search_fetch()`/`fetch()` added, `_read_group()` new signature, JSONB translations, SQL wrapper object.

**v18:** `group_operator` → `aggregator`, `_flush_search()` deprecated, `_search_display_name` for name search, `check_access()`/`has_access()`/`_filtered_access()` unified access methods, `inselect` removed.

**v19:** `@api.private` decorator, `models.Constraint()`/`models.Index()`, `read_group` deprecated → `_read_group`/`formatted_read_group`, `record._cr`/`_context`/`_uid` deprecated (use `self.env.cr` etc.), `odoo.Domain` API, `json` controllers renamed to `jsonrpc`, demo data not loaded by default.
