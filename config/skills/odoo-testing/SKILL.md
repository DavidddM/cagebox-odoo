---
name: odoo-testing
description: Test base classes, tagging, CLI syntax, Form helper, tour testing, and JS test framework changes for Odoo 17-19. Consult when writing or running tests.
---

# Odoo Testing

> Test base classes, tagging, CLI syntax, Form helper, tour testing, and JS test framework changes for Odoo 17–19. Consult when writing or running tests.

---

## Test Base Classes (all versions)

| Class | Behavior |
|-------|----------|
| `TransactionCase` | Single transaction, savepoint per test method. **Primary class.** |
| `SingleTransactionCase` | Single transaction, no isolation between methods |
| `HttpCase` | Extends TransactionCase. Adds `url_open()`, `start_tour()`, `browser_js()` |

**`SavepointCase`:** Merged into `TransactionCase` in v16. No longer documented in v17+. Replace with `TransactionCase`.

---

## `tagged()` Decorator and Test Tags

```python
from odoo.tests import TransactionCase, tagged

@tagged('-at_install', 'post_install')
class TestMyFeature(TransactionCase):
    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        cls.partner = cls.env['res.partner'].create({'name': 'Test'})

    def test_create(self):
        record = self.env['my.model'].create({'partner_id': self.partner.id})
        self.assertEqual(record.state, 'draft')
```

**Built-in tags:** `standard` (implicit default), `at_install` (implicit default), `post_install` (explicit).

---

## `--test-tags` CLI Syntax

```
[-][tag][/module][:class][.method]
```

```bash
odoo-bin -d mydb -i my_module --test-tags /my_module           # all tests in module
odoo-bin -d mydb -i my_module --test-tags :TestMyFeature       # specific class
odoo-bin -d mydb -i my_module --test-tags :TestMyFeature.test_create  # specific method
odoo-bin -d mydb -i my_module --test-tags -at_install,+post_install   # post_install only
```

> **Changed in v19:** `--test-enable` and `--test-tags` now imply `--stop-after-init` automatically.

---

## `Form` Test Helper (all versions)

```python
from odoo.tests import Form

form = Form(self.env['sale.order'])
form.partner_id = self.partner
with form.order_line.new() as line:
    line.product_id = self.product
    line.product_uom_qty = 5
order = form.save()
```

---

## Tour Testing

```python
@tagged('-at_install', 'post_install')
class TestTour(HttpCase):
    def test_shop(self):
        self.start_tour('/shop', 'shop_buy_product', login='admin')
```

Tour JS definition (all versions):
```javascript
import { registry } from "@web/core/registry";
registry.category("web_tour.tours").add("my_tour", {
    url: "/web",
    test: true,
    steps: () => [
        { trigger: ".o_menu_brand", run: "click" },
        { trigger: ".o_kanban_view" },
    ],
});
```

---

## JS Test Framework

| Feature | v17 | v18/v19 |
|---------|-----|---------|
| Framework | QUnit | **Hoot** |
| Bundle | `web.qunit_suite_tests` | **`web.assets_unit_tests`** |
| File naming | `*.js` | **`*.test.js`** (required in v19) |
