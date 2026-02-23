---
name: odoo-module-structure
description: Module directory layout, __manifest__.py keys, asset bundling, and data file loading rules for Odoo 17-19. Consult when creating new modules, adding assets, or troubleshooting data file load order.
---

# Odoo Module Structure and Manifest

> Module directory layout, `__manifest__.py` keys, asset bundling, and data file loading rules for Odoo 17–19. Consult when creating new modules, adding assets, or troubleshooting data file load order.

---

## `__manifest__.py` Keys

**Required:** Only `name` (str) is strictly required.

**Core optional keys (all versions):**

| Key | Type | Default | Notes |
|-----|------|---------|-------|
| `version` | str | `'1.0'` | Format: `{odoo_version}.{major}.{minor}.{patch}` e.g. `'18.0.1.0.0'` |
| `depends` | list | `[]` | Module dependencies. Always include `base`. |
| `data` | list | `[]` | Data file paths, loaded on install/update, **in order listed** |
| `demo` | list | `[]` | Demo data files. Loaded only when demo mode enabled. Implicitly `noupdate=1`. |
| `assets` | dict | `{}` | Asset bundles: `{'bundle_name': ['path/to/files']}` |
| `license` | str | — | Required for Odoo Apps store. Values: `'LGPL-3'`, `'AGPL-3'`, `'GPL-3'` |
| `application` | bool | `False` | Full application vs helper module |
| `auto_install` | bool/list | `False` | `True` = install when all deps met. `list` = install when subset met. `[]` = always. |
| `installable` | bool | `True` | Whether module can be installed |
| `external_dependencies` | dict | `{}` | `{'python': [...], 'bin': [...]}` |
| `pre_init_hook` | str | — | Function name: `func(cr)` |
| `post_init_hook` | str | — | Function name: `func(cr, registry)` |
| `uninstall_hook` | str | — | Function name: `func(cr, registry)` |

**Deprecated keys:** `active` (use `auto_install`), `css` (use `assets`), `qweb` (use `assets`).

> **Changed in v19:** `__openerp__.py` manifest support removed entirely. Only `__manifest__.py` is recognized.

---

## Module Directory Layout

```
my_module/
├── __init__.py
├── __manifest__.py
├── controllers/
│   ├── __init__.py
│   └── main.py
├── data/
│   └── data.xml
├── demo/
│   └── demo.xml
├── models/
│   ├── __init__.py
│   └── my_model.py
├── report/
│   ├── __init__.py
│   └── report_templates.xml
├── security/
│   ├── ir.model.access.csv
│   └── security.xml
├── static/
│   ├── description/
│   │   └── icon.png          # 128×128 PNG
│   └── src/
│       ├── js/
│       ├── scss/
│       ├── xml/
│       └── components/
├── tests/
│   ├── __init__.py
│   └── test_my_model.py
├── views/
│   └── my_model_views.xml
└── wizard/
    ├── __init__.py
    └── my_wizard.py
```

Every Python sub-directory with `.py` files **must** have `__init__.py`. Every model file **must** be imported transitively from the root `__init__.py`.

---

## Asset Bundling

Assets are declared in the `assets` manifest key using bundle names and glob paths:

```python
'assets': {
    'web.assets_backend': [
        'my_module/static/src/**/*',
    ],
}
```

**Directives (all versions):** `append` (default), `('prepend', path)`, `('before', target, path)`, `('after', target, path)`, `('replace', target, path)`, `('remove', target)`, `('include', bundle)`.

**`ir.asset` model** provides database-level asset management. Records with `sequence < 16` process before manifest assets; `≥ 16` after.

| Feature | v17 | v18 | v19 |
|---------|-----|-----|-----|
| JS test bundle | `web.qunit_suite_tests` | **`web.assets_unit_tests`** | `web.assets_unit_tests` |
| Test framework | QUnit | **Hoot** | Hoot |
| Test file naming | `*.js` | `*.test.js` convention | **`*.test.js` required** |
| `.hoot.js` globals | N/A | N/A | **New** |

> **v17:** `/** @odoo-module **/` header required in JS files.

> **v18+:** `/** @odoo-module **/` header optional.

---

## Data File Loading Rules

1. Dependencies load first.
2. Files within `data` list load **in order listed**.
3. `noupdate="1"` records created on install only, skipped on update.
4. CSV files are always `noupdate="0"`.
5. Records loaded via `demo` key are implicitly `noupdate="1"`.

**Recommended load order in manifest:**
```python
'data': [
    'security/groups.xml',          # 1st: groups
    'security/ir.model.access.csv', # 2nd: access rights
    'security/rules.xml',           # 3rd: record rules
    'data/data.xml',                # 4th: master data
    'views/views.xml',              # 5th: views
    'views/menus.xml',              # 6th: menus
],
```

> **Changed in v19:** Demo data loading disabled by default. Use `--with-demo` flag to enable.
