---
name: odoo-version-changelog
description: Breaking changes, deprecations, and new features across Odoo 17, 18, and 19. Consult before starting migration work or when targeting a specific version.
---

# Odoo Version Changelog

Concrete breaking changes, deprecations, and new features across Odoo 17→18→19.
Every entry includes old→new code where applicable. Consult before starting migration work or
when targeting a specific version.

---

## 17.0 → 18.0

### Breaking Changes

| Area | Change | Old | New |
|------|--------|-----|-----|
| Views | `<tree>` root tag removed | `<tree>` | `<list>` |
| Views | `tree_view_ref` context key renamed | `tree_view_ref` | `list_view_ref` |
| Views | Kanban template renamed | `t-name="kanban-box"` | `t-name="card"` |
| Views | Chatter XML simplified | Explicit `oe_chatter` div with widgets | `<chatter/>` |
| ORM | `ir.property` table removed | `ir.property` records | Company-dependent fields as real columns |
| ORM | `inselect` removed | `inselect` domain operator | Standard operators |
| ORM | `_flush_search()` deprecated | `_flush_search()` | — |
| JS/RPC | `rpc` usage changed | `useService("rpc")` | `import { rpc } from "@web/core/network/rpc"` |
| JS/Hooks | `usePosition` import path moved | `@web/core/position_hook` | `@web/core/position/position_hook` |
| JS/Hooks | `useVirtual` removed | `useVirtual(...)` | `useVirtualGrid(...)` |
| JS/Hooks | `useDropdownNavigation` removed | `useDropdownNavigation()` | `useNavigation(containerRef, options)` |
| JS/Hooks | `useSetupView` removed | `useSetupView(params)` | Merged into `useSetupAction` |
| JS/Hooks | `SERVICES_METADATA` location | `import from "@web/env"` | `export from "@web/core/utils/hooks"` |
| JS/Module | `/** @odoo-module **/` header | Required | Optional |
| Testing | JS test framework changed | QUnit | Hoot |
| Testing | JS test bundle renamed | `web.qunit_suite_tests` | `web.assets_unit_tests` |
| Testing | JS test file naming convention | `*.js` | `*.test.js` |
| Config | `longpolling_port` removed | `longpolling_port` | `gevent_port` |
| Reporting | Debug mode stripped from `_prepare_html` | Debug param injected | Removed |
| Reporting | `check_access_rights` in report unlink | `check_access_rights` | `check_access` |
| Migration | Strict `migrate()` signature validation | Flexible | Only `(cr, version)` / `(_cr, _version)` |

### Deprecations

| Area | What | Replacement |
|------|------|-------------|
| ORM | `group_operator` field parameter | `aggregator` |
| ORM | `name_get()` (continued from v17) | `_compute_display_name()` |
| JS/Hooks | `useGetDomainTreeDescription` | Refactored into `useGetTreeDescription` + `useMakeGetConditionDescription` |
| JS/Hooks | `useLoadDisplayNames` | Removed |
| JS/Hooks | `useGetDefaultCondition` | Removed |
| Config | `publisher_warranty_url` domain | `services.openerp.com` → `services.odoo.com` |
| ORM | `_search_display_name` introduced | For name search customization |

### New Features

| Area | What | Details |
|------|------|---------|
| Controllers | `auth='bearer'` | Bearer token authentication on routes |
| Cron | `_trigger(at=datetime)` | On-demand scheduling |
| Cron | `_commit_progress(done, remaining)` | Batch processing with intermediate commits |
| ORM | `check_access()`, `has_access()`, `_filtered_access()` | Unified access methods |
| JS/Hooks | `useDropdownState`, `useDropdownCloser`, `useDropdownGroup`, `useDropdownNesting` | Dropdown control hooks |
| JS/Hooks | `useDropzone`, `useCustomDropzone` | File drop zone hooks |
| JS/Hooks | `useFileUploader`, `useFormViewInDialog`, `useMagicColumnWidths`, `useNavigation`, `useRegistry`, `useVirtualGrid` | New utility hooks |
| JS/Notifications | `autocloseDelay` option | Configurable auto-close delay |
| JS/Services | `useServiceProtectMethodHandling` | Test patching for destroyed-component handling |
| Reporting | Three new layout variants | Bubble, Wave, Folder |
| Reporting | `domain` field on `ir.actions.report` | Filter-based visibility |
| Reporting | `css_margins` on `report.paperformat` | CSS-based margins |
| Reporting | `_run_wkhtmltoimage()` method | HTML-to-image conversion |
| Reporting | `_pre_render_qweb_pdf()` method | Cleaner override point |
| Reporting | `get_paperformat_by_xmlid()` method | Resolve paperformat by XML ID |
| Reporting | Temporary session for wkhtmltopdf | `_trace_disable=True` session instead of reusing request |
| Reporting | Barcode caching | `Cache-Control` header on barcode responses |
| Config | `db_replica_host`, `db_replica_port` | Read-replica PostgreSQL support |
| Config | `limit_memory_soft_gevent`, `limit_memory_hard_gevent` | Separate gevent worker memory limits |

---

## 18.0 → 19.0

### Breaking Changes

| Area | Change | Old | New |
|------|--------|-----|-----|
| Controllers | Route `type` for JSON | `type='json'` | `type='jsonrpc'` |
| External API | Primary external API | XML-RPC | JSON-2 API (`/json/2/<model>/<method>`) |
| ORM | `read_group` deprecated | `read_group()` | `_read_group()` / `formatted_read_group()` |
| ORM | `record._cr` / `_context` / `_uid` deprecated | `record._cr` | `self.env.cr` |
| ORM | `groups_id` field renamed (reports) | `groups_id` | `group_ids` |
| Config | `addons_path` type changed | Comma-separated string | `list[str]` |
| Config | `db_name` type changed | String | `list` |
| Config | `dev_mode` type changed | String | `list` |
| Config | `server_wide_modules` default | `['base', 'web']` | `['base', 'rpc', 'web']` |
| Config | `http_interface` default | `''` | `'0.0.0.0'` |
| Config | `__openerp__.py` support | Recognized (deprecated) | Removed entirely |
| Config | Hidden `--xmlrpc-*` aliases | Accepted | Removed |
| Config | `without_demo` inverted | `--without-demo` | `--with-demo` (default `False`) |
| Config | `upgrade_path` return type | Comma-separated string | List |
| Config | Invalid `addons_path` entries | Hard error | Warning + skip |
| JS/Hooks | `useClickHandler` removed | `useClickHandler` | — |
| JS/Hooks | `useViewArch` removed | `useViewArch` | — |
| JS/Hooks | Domain tree hooks removed | `useGetTreeDescription`, `useLoadFieldInfo`, `useLoadPathDescription`, `useMakeGetConditionDescription`, `useMakeGetFieldDef` | — |
| JS/Hooks | `useEmojiPicker` signature changed | `(ref, props, options?)` | `(...args)` (wraps `usePicker`) |
| JS/Hooks | `useTagNavigation` signature changed | `(refName, deleteTag)` | `(refName, options = {})` |
| JS/Dialog | `ConfirmationDialog.body` prop | Required (`String`) | Optional |
| JS/Notifications | Timer logic moved | In service | In `Notification` component |
| Reporting | Barcode `quiet` default | `0` | `1` |
| Reporting | Error code in `report_download` | `'code': 200` | `'code': 0` |
| Reporting | `check_wkhtmltopdf` route type | `type='json'` | `type='jsonrpc'` |
| Reporting | wkhtmltopdf detection | Module globals | `WkhtmlInfo` NamedTuple + `lru_cache` |
| Reporting | `forced_vat` conditionals | Present | Removed from layout variants |
| Migration | `tools.config["upgrade_path"]` | Comma-separated string | List |
| Migration | `openupgrade.convert_to_company_dependent()` | Works | **Broken** (`ir.property` removed in v18) |

### Deprecations

| Area | What | Replacement |
|------|------|-------------|
| External API | XML-RPC | JSON-2 API |
| ORM | `read_group()` | `_read_group()` / `formatted_read_group()` |
| ORM | `record._cr`, `record._context`, `record._uid` | `self.env.cr`, `self.env.context`, `self.env.uid` |
| Config | `rcfile` property | `config['config']` |
| Config | `load()` method | `_load_file_options()` |
| Config | `db_replica_host` empty string pattern | `--dev=replica` |

### New Features

| Area | What | Details |
|------|------|---------|
| ORM | `@api.private` decorator | Prevents RPC access to method |
| ORM | `models.Constraint()` | Declarative SQL constraints |
| ORM | `models.Index()` | Declarative SQL indexes |
| ORM | `models.UniqueIndex()` | Declarative unique indexes |
| ORM | `odoo.Domain` API | Domain object class |
| ORM | `_company_field` model attribute | Defaults to `'company_id'` |
| Controllers | `readonly` route parameter | Read-only DB replica routing |
| External API | JSON-2 API | `POST /json/2/<model>/<method>` with Bearer auth |
| Cron | `_notify_progress()` | Progress notification for cron jobs |
| JS/Hooks | `useColorPicker`, `useDeleteRecords`, `useExportRecords`, `usePicker`, `useSquareSelection`, `useViewportChange` | New utility hooks |
| JS/Service | `useService` auto-wraps reactive services | `useState()` applied if `toRaw(service) !== service` |
| JS/Dialog | `closeAll(params)` | Params passed to each dialog's close |
| JS/Dialog | `isBeingClosed` guard | Prevents double-close |
| Config | Config architecture rewrite | `ChainMap` with 5 layers: runtime > CLI > env > file > default |
| Config | Environment variables | `PGDATABASE`, `PGHOST`, `ODOO_RC`, `ODOO_DEV`, etc. |
| Config | `--dev=access` | Full traceback for `AccessError` in logs |
| Config | `--dev=werkzeug` | Interactive Werkzeug HTML debugger |
| Config | `--dev=replica` | Simulated read-replica for development |
| Config | `--reinit` | Reinitialize modules |
| Config | `db_app_name` | Set `application_name` in PostgreSQL |
| Config | `import_file_maxbytes`, `import_file_timeout`, `import_url_regex` | Import file controls |
| Config | `proxy_access_token` | Proxy authentication token |
| Config | `http_socket_activation` | Systemd socket activation support |
| Config | `--test-enable`/`--test-tags` imply `--stop-after-init` | Automatic stop after tests |
| Reporting | `t-autoprefix="true"` on report assets | Auto-prefixing for CSS |
| Reporting | Bubble layout restructured | From flexbox to table for wkhtmltopdf compat |
| Reporting | Barcode imports refactored | `reportlab` → `odoo.tools.barcode` |
| Reporting | Type hints added throughout report engine | `-> list[bytes \| None]`, `-> WkhtmlInfo` |
| PostgreSQL | Minimum version raised | PostgreSQL 12 | PostgreSQL 13 |

---

## Cross-Version Quick Reference

| Feature | v17 | v18 | v19 |
|---------|-----|-----|-----|
| View modifiers | Inline expressions (attrs removed) | Same | Same |
| List view tag | `<tree>` | `<list>` | `<list>` |
| Kanban template | `kanban-box` | `card` | `card` |
| Chatter XML | Explicit widgets | `<chatter/>` | `<chatter/>` |
| `name_get()` | Deprecated | Deprecated | Deprecated |
| `group_operator` | Works | Deprecated → `aggregator` | `aggregator` |
| `column_invisible` | New | Stable | Stable |
| OWL version | OWL 2 | OWL 2 | OWL 2 |
| RPC access (JS) | `useService("rpc")` | `import { rpc }` | `import { rpc }` |
| Route `type` for JSON | `'json'` | `'json'` | `'jsonrpc'` |
| Route `auth='bearer'` | — | New | Available |
| External API | XML-RPC | XML-RPC | JSON-2 API |
| JS test bundle | `web.qunit_suite_tests` | `web.assets_unit_tests` | `web.assets_unit_tests` |
| Test framework | QUnit | Hoot | Hoot |
| SQL constraints | `_sql_constraints` list | Same | + `models.Constraint()` |
| `@api.private` | — | — | New |
| `read_group` | Available | Available | Deprecated |
| Demo data loading | Enabled by default | Disabled by default | Disabled by default |
| Domain class | — | — | `odoo.Domain` |
| PostgreSQL minimum | 12 | 12 | 13 |
| `__openerp__.py` | Recognized (deprecated) | Recognized (deprecated) | Removed |
| `server_wide_modules` | `base,web` | `base,web` | `base,rpc,web` |
| `addons_path` storage | string | string | list |
