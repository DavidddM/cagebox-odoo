---
name: odoo-views-ui
description: View definitions, XML syntax, modifier expressions, view inheritance, form/list/kanban patterns, and widget reference for Odoo 17-19. Consult when working with views, UI elements, or view inheritance.
---

# Odoo Views and UI

> View definitions, XML syntax, modifier expressions, view inheritance, form/list/kanban patterns, and widget reference for Odoo 17–19. Consult when working with views, UI elements, or view inheritance.

---

## `attrs` → Inline Modifiers (v17 Breaking Change)

**Odoo 17.0** completely removed `attrs` and `states` XML attributes. Using them raises `ParseError`.

```xml
<!-- OLD (v16 and earlier): -->
<field name="field_a" attrs="{'invisible': [('state', '=', 'done')],
    'readonly': [('field_b', '!=', False)]}"/>
<field name="field_c" states="draft,done"/>

<!-- NEW (v17+): Python expression syntax -->
<field name="field_a" invisible="state == 'done'" readonly="field_b"/>
<field name="field_c" invisible="state not in ('draft', 'done')"/>
```

**Expression evaluation context:** All field names in the view, `parent`, `context`, `uid`, `today`, `now`.

**Inherited view modifier changes:**
```xml
<!-- OLD: -->
<attribute name="attrs">{'readonly': [('x', '=', False)]}</attribute>

<!-- NEW (v17+): additive or full override -->
<attribute name="readonly" add="(not x)" separator=" or "/>
<attribute name="invisible">field_d != 3</attribute>
```

**`column_invisible` (v17+ new):** In list views, `invisible` now hides the cell only. Use `column_invisible` to hide the entire column. `column_invisible` evaluates without row-level values (only `parent` and `context`).

```xml
<field name="secret" column_invisible="1"/>
<field name="late" column_invisible="parent.has_late == False"/>
```

---

## `<tree>` → `<list>` Rename

| Version | Root tag | `view_mode` |
|---------|----------|-------------|
| v17 | `<tree>` (both work) | `tree,form` |
| **v18** | **`<list>`** (breaking) | **`list,form`** |
| v19 | `<list>` | `list,form` |

Also: `tree_view_ref` → `list_view_ref` in context (v18+).

---

## Kanban Template Change

| Version | Template name |
|---------|--------------|
| v17 | `t-name="kanban-box"` |
| **v18+** | **`t-name="card"`** |

---

## View Types

**Community (all versions):** Form, List, Kanban, Search, Pivot, Graph, Calendar, Activity.

**Enterprise:** Cohort, Gantt, Map, Grid (v18+).

---

## View Inheritance

```xml
<record id="view_inherited" model="ir.ui.view">
    <field name="inherit_id" ref="base.view_partner_form"/>
    <field name="arch" type="xml">
        <xpath expr="//field[@name='email']" position="after">
            <field name="custom_field"/>
        </xpath>
    </field>
</record>
```

**Position values:** `inside` (default), `after`, `before`, `replace` (`$0` = original), `attributes`, `move`.

**Priority:** Lower `priority` = applied first (default 16). Extension views applied depth-first.

---

## Form View Pattern (v17+)

```xml
<form>
    <header>
        <button name="action_confirm" type="object" string="Confirm"
                class="btn-primary" invisible="state != 'draft'"/>
        <field name="state" widget="statusbar" statusbar_visible="draft,confirmed,done"/>
    </header>
    <sheet>
        <div class="oe_button_box" name="button_box">
            <button class="oe_stat_button" icon="fa-money" name="action_view_invoices" type="object">
                <field name="invoice_count" widget="statinfo"/>
            </button>
        </div>
        <group>
            <group><field name="partner_id"/></group>
            <group><field name="date"/></group>
        </group>
        <notebook>
            <page string="Lines" name="lines">
                <field name="line_ids">
                    <list editable="bottom">  <!-- v18+: <list>, v17: <tree> -->
                        <field name="product_id"/>
                        <field name="quantity"/>
                    </list>
                </field>
            </page>
        </notebook>
    </sheet>
    <!-- v17: explicit chatter widgets; v18+: <chatter/> -->
    <chatter/>
</form>
```

---

## Common Widget Values

`monetary`, `many2one_avatar`, `many2many_tags`, `statusbar`, `priority`, `color`, `image`, `html`, `daterange`, `percentpie`, `statinfo`, `boolean_toggle`, `badge`, `url`, `phone`, `email`.

---

## Field `options` Attribute

```xml
<field name="partner_id" options="{'no_create': True, 'no_open': True}"/>
<field name="tag_ids" widget="many2many_tags" options="{'color_field': 'color'}"/>
<field name="start_date" widget="daterange" options="{'related_end_date': 'end_date'}"/>
```
