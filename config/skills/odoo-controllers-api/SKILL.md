---
name: odoo-controllers-api
description: HTTP route definitions, controller patterns, request helpers, and external API access (XML-RPC / JSON-2) for Odoo 17-19. Consult when building web endpoints, integrating external systems, or working with API authentication.
---

# Odoo Web Controllers and API

> HTTP route definitions, controller patterns, request helpers, and external API access (XML-RPC / JSON-2) for Odoo 17–19. Consult when building web endpoints, integrating external systems, or working with API authentication.

---

## `http.route` Parameters

| Parameter | v17 | v18 | v19 |
|-----------|-----|-----|-----|
| `type` | `'json'`, `'http'` | `'json'`, `'http'` | **`'jsonrpc'`**, `'http'` |
| `auth` | `'user'`, `'public'`, `'none'` | + **`'bearer'`** | `'user'`, `'public'`, `'none'`, `'bearer'` |
| `readonly` | — | — | **New** (read-only DB replica) |
| `csrf` | True for HTTP, False for JSON | Same | Same |

```python
from odoo import http
from odoo.http import request

class MyController(http.Controller):
    # v17/v18:
    @http.route('/api/data', type='json', auth='user')
    def get_data(self, **kw):
        return {'result': 'ok'}

    # v19:
    @http.route('/api/data', type='jsonrpc', auth='user')
    def get_data(self, **kw):
        return {'result': 'ok'}
```

---

## Request Helpers

```python
request.env['model'].search([])
request.render('template_id', values)
request.make_response(data, headers=[], status=200)
request.make_json_response(data, status=200)
request.redirect('/url')
```

---

## External API

### v17/v18: XML-RPC

```python
import xmlrpc.client
common = xmlrpc.client.ServerProxy(f'{url}/xmlrpc/2/common')
uid = common.authenticate(db, user, password, {})
models = xmlrpc.client.ServerProxy(f'{url}/xmlrpc/2/object')
ids = models.execute_kw(db, uid, password, 'res.partner', 'search', [[['is_company','=',True]]])
```

### v19: JSON-2 API (primary, XML-RPC deprecated)

```python
import requests
response = requests.post(
    f"{url}/json/2/res.partner/search",
    headers={"Authorization": f"bearer {api_key}", "Content-Type": "application/json"},
    json={"domain": [["is_company", "=", True]]}
)
```

Endpoint: `POST /json/2/<model>/<method>`. Auth via Bearer header. Database via `X-Odoo-Database` header.
