---
name: odoo-security
description: Access control lists, record rules, group definitions, and sudo() behavior for Odoo 17-19. Consult when configuring module security, writing access rules, or debugging permission issues.
---

# Odoo Security

> Access control lists, record rules, group definitions, and `sudo()` behavior for Odoo 17–19. Consult when configuring module security, writing access rules, or debugging permission issues.

---

## `ir.model.access.csv`

Stable across all versions.

```csv
id,name,model_id/id,group_id/id,perm_read,perm_write,perm_create,perm_unlink
access_my_model_user,access_my_model_user,model_my_model,base.group_user,1,1,1,0
access_my_model_manager,access_my_model_manager,model_my_model,my_module.group_manager,1,1,1,1
```

Default-deny: no access if no matching rule exists. Access rights are **additive** across groups.

---

## Record Rules (`ir.rule`)

```xml
<record model="ir.rule" id="rule_multi_company">
    <field name="name">Multi-company</field>
    <field name="model_id" ref="model_my_model"/>
    <field name="global" eval="True"/>
    <field name="domain_force">
        ['|', ('company_id', '=', False), ('company_id', 'in', company_ids)]
    </field>
</record>
```

**Global rules** (no groups): intersect (AND). **Group rules**: unify (OR), then intersect with globals.

**Domain variables:** `user`, `company_ids`, `time`.

---

## Group Definition

```xml
<record id="group_manager" model="res.groups">
    <field name="name">Manager</field>
    <field name="category_id" ref="base.module_category_sales"/>
    <field name="implied_ids" eval="[(4, ref('group_user'))]"/>
</record>
```

**`implied_ids`:** Adding user to this group auto-adds them to implied groups.

---

## `sudo()` Behavior (all versions)

Bypasses: access rights (ir.model.access) and record rules (ir.rule).

Does NOT bypass: hard-coded `has_group()` checks, field-level `groups` in views.
