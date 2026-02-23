---
name: odoo-reporting
description: Report actions, QWeb templates, layout structure, headers/footers, controller routes, wkhtmltopdf gotchas, and version differences for Odoo 17-19. Consult when creating or customizing PDF/HTML reports.
---

# Odoo Reporting

> Report actions, QWeb templates, layout structure, headers/footers, controller routes, wkhtmltopdf gotchas, and version differences for Odoo 17–19. Consult when creating or customizing PDF/HTML reports.

---

## Report Action Definition (all versions)

```xml
<record id="report_my_doc" model="ir.actions.report">
    <field name="name">My Document</field>
    <field name="model">my.model</field>
    <field name="report_type">qweb-pdf</field>
    <field name="report_name">my_module.report_my_document</field>
    <field name="print_report_name">'Document - %s' % (object.name)</field>
    <field name="binding_model_id" ref="model_my_model"/>
    <field name="paperformat_id" ref="my_module.paperformat_a4"/>
</record>
```

> **v18+:** New `domain` field on `ir.actions.report` for filter-based visibility. New `get_valid_action_reports()` method.

---

## QWeb Report Template

```xml
<template id="report_my_document">
    <t t-call="web.html_container">
        <t t-foreach="docs" t-as="o">
            <t t-call="web.external_layout">
                <div class="page">
                    <h2><span t-field="o.name"/></h2>
                    <table class="table table-sm">
                        <t t-foreach="o.line_ids" t-as="line">
                            <tr>
                                <td><span t-field="line.product_id.name"/></td>
                                <td><span t-field="line.price_subtotal"/></td>
                            </tr>
                        </t>
                    </table>
                </div>
            </t>
        </t>
    </t>
</template>
```

**Template variables:** `docs` (recordset), `doc_ids`, `doc_model`, `user`, `res_company`, `time`, `web_base_url`, `context_timestamp`.

**Key directives:** `t-field` (formatted output), `t-esc` (escaped), `t-out` (raw, replaces deprecated `t-raw`), `t-call`, `t-foreach`, `t-if`, `t-set`.

---

## Custom Report Model

```python
class CustomReport(models.AbstractModel):
    _name = 'report.my_module.report_my_document'

    def _get_report_values(self, docids, data=None):
        return {
            'doc_ids': docids,
            'doc_model': 'my.model',
            'docs': self.env['my.model'].browse(docids),
            'extra_data': self._compute_extra(docids),
        }
```

Model name **must** follow pattern `report.<report_name>`.

---

## Layout Structure

### `web.external_layout` — Dispatcher

Resolves company, then delegates to the company's chosen layout variant via `company.external_report_layout_id`. Fallback: `web.external_layout_standard`.

Company resolution order: `company_id` context var → `o.company_id.sudo()` → `res_company`.

**Identical across v17, v18, v19.**

### Layout Variants

| Record XML ID | Name | Sequence | Versions |
|---|---|---|---|
| `report_layout_standard` | Light | 2 | all |
| `report_layout_boxed` | Boxed | 3 | all |
| `report_layout_bold` | Bold | 4 | all |
| `report_layout_striped` | Striped | 5 | all |
| `report_layout_bubble` | Bubble | 6 | **v18+** |
| `report_layout_wave` | Wave | 7 | **v18+** |
| `report_layout_folder` | Folder | 8 | **v18+** |

Each variant template has three structural divs: `div.header`, `div.article`, `div.footer`.

### `web.internal_layout` — When to Use

| Aspect | `external_layout` | `internal_layout` |
|---|---|---|
| Header | Company logo, address, tagline | Timestamp, company name, page numbers |
| Footer | Company footer text, page numbers | None |
| Use case | Customer-facing (invoices, quotations) | Internal documents |
| Layout variants | Dispatches to Standard/Bold/Striped/etc. | Fixed simple layout |

### Override Header/Footer for a Specific Report

```xml
<template id="custom_header_for_my_report"
          inherit_id="web.external_layout_standard" priority="99">
    <xpath expr="//div[hasclass('header')]" position="replace">
        <div t-attf-class="header o_company_#{company.id}_layout">
            <t t-if="report_type == 'pdf' and o._name == 'sale.order'">
                <!-- Custom header for this report -->
            </t>
            <t t-else="">$0</t>
        </div>
    </xpath>
</template>
```

**Alternative:** Override the report template itself to use a custom layout via `t-call`.

### Override Header/Footer Globally

Inherit the specific layout variant (e.g., `web.external_layout_standard`). You must inherit each variant separately — there is no single "all layouts" inheritance point.

### Custom Layout from Scratch

```xml
<template id="external_layout_custom" name="Custom Layout">
    <div class="header">
        <img t-if="company.logo" t-att-src="image_data_uri(company.logo)"
             style="max-height: 50px;" alt="Logo"/>
    </div>
    <div class="article" t-att-data-oe-model="o and o._name"
         t-att-data-oe-id="o and o.id"
         t-att-data-oe-lang="o and o.env.context.get('lang')">
        <t t-out="0"/>
    </div>
    <div class="footer">
        <div class="text-center">Page <span class="page"/> / <span class="topage"/></div>
    </div>
</template>

<record id="report_layout_custom" model="report.layout">
    <field name="view_id" ref="external_layout_custom"/>
    <field name="name">Custom</field>
    <field name="sequence">10</field>
</record>
```

**Critical:** `div.article` **must** have `data-oe-model` and `data-oe-id` attributes for per-record PDF splitting to work.

---

## Paper Format

```xml
<record id="paperformat_a4" model="report.paperformat">
    <field name="name">A4 Custom</field>
    <field name="format">A4</field>
    <field name="orientation">Portrait</field>
    <field name="margin_top">40</field>
    <field name="margin_bottom">28</field>
    <field name="margin_left">7</field>
    <field name="margin_right">7</field>
    <field name="header_spacing">35</field>
    <field name="dpi">90</field>
</record>
```

> **v18+:** New `css_margins` field on `report.paperformat`. New `get_paperformat_by_xmlid()` method.

**wkhtmltopdf 0.12.6** required for all versions.

---

## Report Controller Routes

| Route | Auth | Description |
|-------|------|-------------|
| `/report/<converter>/<reportname>/<docids>` | `user` | Render report (converter: `html`, `pdf`, `text`) |
| `/report/download` | `user` | Download report (used by JS action manager) |
| `/report/barcode/<type>/<value>` | `public` | Generate barcode image |
| `/report/check_wkhtmltopdf` | `user` | Check wkhtmltopdf status |

> **v18+:** `readonly=True` added to report routes. Barcode caching headers added.

> **v19:** Barcode default `quiet` changed from `0` to `1`. `check_wkhtmltopdf` route type changed to `jsonrpc`.

### Extending the Controller

```python
from odoo.addons.web.controllers.report import ReportController
from odoo import http

class CustomReportController(ReportController):
    @http.route()
    def report_routes(self, reportname, docids=None, converter=None, **data):
        response = super().report_routes(reportname, docids=docids, converter=converter, **data)
        return response
```

### Custom Filename (`print_report_name`)

Python expression evaluated with `safe_eval`. Variables: `object` (browse record), `time` (module).

```python
"'INV-%s-%s' % (object.name, time.strftime('%Y%m%d'))"
```

Only evaluated for **single record** prints. Multi-record falls back to report `name` field.

---

## wkhtmltopdf Gotchas

### CSS Limitations

wkhtmltopdf uses QtWebKit (circa 2012). **Does NOT work:** `display: flex` (broken in headers/footers), `display: grid`, `position: sticky`, CSS custom properties, `object-fit`. **Works:** `display: table`, `float`, Bootstrap 5 grid, `position: absolute/relative/fixed`.

Prefer `float` and `display: table` over flexbox. Odoo's report SCSS overrides flexbox to float-based layout via the `o_body_pdf` class.

### Header/Footer Overlap

`header_spacing` (default 35mm) on `report.paperformat` controls the gap. Per-report override via `data-report-*` HTML attributes:

| Override | Description |
|----------|-------------|
| `data-report-margin-top` | Top margin |
| `data-report-margin-bottom` | Bottom margin |
| `data-report-header-spacing` | Header spacing |
| `data-report-dpi` | DPI |
| `data-report-landscape` | Landscape orientation |

### Page Break Control

```css
.page-break-before { page-break-before: always; }
.page-break-after { page-break-after: always; }
.no-split { page-break-inside: avoid; }
```

`page-break-inside: avoid` does NOT work on `<tr>` elements.

### Image Loading

Images referenced via relative URLs require wkhtmltopdf to make HTTP requests back to Odoo. Use `image_data_uri()` to inline as base64:

```xml
<img t-att-src="image_data_uri(company.logo)" alt="Logo"/>
```

`--disable-local-file-access` is always passed (hardcoded security measure).

> **v18:** Session handling refactored — temporary session with `_trace_disable=True` created instead of reusing request session.

### External Fonts

Bundle fonts as static files and reference via `@font-face`. Register in report asset bundle:

```xml
<template id="report_assets_common" inherit_id="web.report_assets_common">
    <xpath expr="." position="inside">
        <link rel="stylesheet" href="/my_module/static/src/scss/report_fonts.scss"/>
    </xpath>
</template>
```

`--javascript-delay` default: 1000ms. Increase via `report.print_delay` system parameter.

### Table Splitting

Tables >4 MiB are split into 500-row segments by `_split_table()`. `<thead>` is repeated by wkhtmltopdf but stripped when `_split_table` splits.

### Workers Requirement

With `--workers=1`, wkhtmltopdf HTTP callback deadlocks. Minimum **2 workers** for PDF generation. In development, use `--dev=all` with `--workers=0` (threaded mode).

### Debug Mode and Reports

Running in debug mode can cause random missing headers/footers because debug splits asset bundles into individual files.

> **v18:** Debug mode parameter injection removed from `_prepare_html`.

---

## Extra Context Injection

**Method 1: Custom report model** — override `_get_report_values()` (recommended).

**Method 2: Context via URL** — `/report/pdf/my_module.my_report/42?context={"key":"value"}`.

**Method 3: Override `_render_template`:**

```python
class IrActionsReport(models.Model):
    _inherit = 'ir.actions.report'

    def _render_template(self, template, values=None):
        if values is None:
            values = {}
        values['current_date'] = fields.Date.today()
        return super()._render_template(template, values)
```

---

## Watermark Injection

No built-in watermark mechanism. Two approaches:

1. **CSS background image** on `div.article`
2. **Post-processing PDF** via PyPDF2 — override `_render_qweb_pdf`

> **v18+:** `_pre_render_qweb_pdf` provides a cleaner hook point for PDF modification.
