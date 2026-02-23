---
name: odoo-common-patterns
description: Mail thread integration, sequences, actions, domains, multi-currency, translations, external IDs, and environment access for Odoo 17-19. Consult for standard implementation patterns.
---

# Odoo Common Patterns and Recipes

> Mail thread integration, sequences, actions, domains, multi-currency, translations, external IDs, and environment access for Odoo 17–19. Consult for standard implementation patterns.

---

## Mail Thread Integration

```python
class MyModel(models.Model):
    _name = 'my.model'
    _inherit = ['mail.thread', 'mail.activity.mixin']

    state = fields.Selection([...], tracking=True)
    name = fields.Char(tracking=True)
```

**Chatter in form view:**
```xml
<!-- v17: explicit -->
<div class="oe_chatter">
    <field name="message_follower_ids" widget="mail_followers"/>
    <field name="activity_ids" widget="mail_activity"/>
    <field name="message_ids" widget="mail_thread"/>
</div>
<!-- v18+: simplified -->
<chatter/>
```

**Posting messages:**
```python
record.message_post(body="Approved", message_type='comment', subtype_xmlid='mail.mt_note')
```

**Context keys:** `mail_create_nosubscribe`, `mail_create_nolog`, `mail_notrack`, `tracking_disable`.

---

## Sequence Generation

```python
name = fields.Char(default=lambda self: _('New'), copy=False, readonly=True)

@api.model_create_multi
def create(self, vals_list):
    for vals in vals_list:
        if vals.get('name', _('New')) == _('New'):
            vals['name'] = self.env['ir.sequence'].next_by_code('my.model') or '/'
    return super().create(vals_list)
```

**Prefix patterns:** `%(year)s`, `%(month)s`, `%(day)s`, `%(y)s`, `%(range_year)s`.

---

## Actions

```xml
<record model="ir.actions.act_window" id="action_my_model">
    <field name="name">Records</field>
    <field name="res_model">my.model</field>
    <field name="view_mode">list,form,kanban</field>  <!-- v18+: 'list' not 'tree' -->
    <field name="domain">[('active', '=', True)]</field>
    <field name="context">{'default_state': 'draft', 'search_default_my_filter': 1}</field>
    <field name="target">current</field>
</record>
```

**Binding for Action menu:** `binding_model_id` + `binding_type='action'`.

**Binding for Print menu:** `binding_type='report'`.

---

## Domain Syntax

```python
# Basic
[('state', '=', 'draft'), ('amount', '>', 100)]  # implicit AND

# Logical operators (prefix notation)
['|', ('state', '=', 'draft'), ('state', '=', 'sent')]          # OR
['&', '|', ('a', '=', 1), ('b', '=', 2), ('c', '=', 3)]        # (a=1 OR b=2) AND c=3
['!', ('active', '=', True)]                                      # NOT

# Operators: =, !=, >, >=, <, <=, like, ilike, in, not in, child_of, parent_of
# v17+ new: 'any', 'not any' for x2many subqueries
[('order_line', 'any', [('qty', '>', 5)])]
```

> **v19:** `odoo.Domain` API added.

---

## Multi-Currency

```python
currency_id = fields.Many2one('res.currency', default=lambda self: self.env.company.currency_id)
amount = fields.Monetary(currency_field='currency_id')

# Conversion:
converted = from_currency._convert(amount, to_currency, company, date, round=True)
```

---

## Translatable Fields

```python
from odoo import _
from odoo.tools import LazyTranslate
_lt = LazyTranslate(__name__)

# Runtime:
raise UserError(_("Cannot delete confirmed record"))

# Class-level (before translations loaded):
STATES = [('draft', _lt("Draft")), ('confirmed', _lt("Confirmed"))]
```

```javascript
// JavaScript:
import { _t } from "@web/core/l10n/translation";
const msg = _t("Hello %s", name);
```

---

## External ID Management

```python
record = self.env.ref('module.xml_id')                    # resolve XML ID
record = self.env.ref('module.xml_id', raise_if_not_found=False)
xml_id = record._ensure_xml_id()                          # create __export__ ID if needed
```

---

## Environment

```python
self.env.cr          # cursor
self.env.uid         # user ID
self.env.user        # user record
self.env.context     # immutable dict
self.env.company     # current company
self.env.companies   # allowed companies
self.env.su          # superuser mode boolean
```

> **Deprecated in v19:** `record._cr`, `record._context`, `record._uid` — use `self.env.cr` etc.
