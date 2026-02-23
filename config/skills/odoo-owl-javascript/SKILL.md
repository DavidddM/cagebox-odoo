---
name: odoo-owl-javascript
description: OWL component patterns, hooks inventory, RPC, registries, dialog/notification services, custom field widgets, custom services, import paths, and patching for Odoo 17-19. Consult for any JS/OWL frontend work.
---

# Odoo OWL Framework and JavaScript

> OWL component patterns, hooks inventory, RPC, registries, dialog/notification services, custom field widgets, custom services, import paths, and patching for Odoo 17–19. Consult for any JS/OWL frontend work.

---

## OWL Version

All three versions use OWL 2.x. The OWL 1→2 transition happened during Odoo 16.

---

## Component Pattern (all versions)

```javascript
import { Component, useState, onWillStart, onMounted, onWillUnmount } from "@odoo/owl";
import { useService } from "@web/core/utils/hooks";
import { registry } from "@web/core/registry";

class MyComponent extends Component {
    static template = "my_module.MyComponent";
    static props = ["*"];

    setup() {
        this.orm = useService("orm");
        this.state = useState({ value: 0 });

        onWillStart(async () => { /* async init */ });
        onMounted(() => { /* DOM ready */ });
        onWillUnmount(() => { /* cleanup */ });
    }
}
```

---

## RPC — Key Change Between v17 and v18

```javascript
// v17: service-based
this.rpc = useService("rpc");
const result = await this.rpc("/my/route", { key: "val" });

// v18/v19: direct import
import { rpc } from "@web/core/network/rpc";
const result = await rpc("/my/route", { key: "val" });
```

**ORM service (stable across all versions):**
```javascript
const orm = useService("orm");
await orm.call(model, method, args, kwargs);
await orm.create(model, values);
await orm.read(model, ids, fields);
await orm.searchRead(model, domain, fields, options);
```

---

## Hooks Inventory

### Core Utility Hooks (`@web/core/utils/hooks`)

| Hook | Signature | Description |
|------|-----------|-------------|
| `useAutofocus` | `({ refName?, selectAll?, mobile? } = {})` → `Ref` | Focuses a `t-ref="autofocus"` element when it appears |
| `useBus` | `(bus, eventName, callback)` → `void` | Attaches listener to EventBus, auto-removes on unmount |
| `useService` | `(serviceName)` → `ServiceValue` | Retrieves service from `env.services` |
| `useSpellCheck` | `({ refName? } = {})` → `void` | Activates spellcheck only on focus |
| `useChildRef` | `()` → `ForwardRef` | Creates callable ref for child component |
| `useForwardRefToParent` | `(refName)` → `Ref` | Forwards ref to parent component |
| `useOwnedDialogs` | `()` → `addDialog(Component, props, options?)` | Auto-closes owned dialogs on unmount |
| `useRefListener` | `(ref, ...listener)` → `void` | Manages event listener on a ref element |

```js
import { useService, useBus, useAutofocus, useOwnedDialogs } from "@web/core/utils/hooks";

setup() {
    this.orm = useService("orm");
    this.inputRef = useAutofocus({ selectAll: true });
    useBus(this.env.bus, "ROUTE_CHANGE", this.onRouteChange);
    this.addDialog = useOwnedDialogs();
}
```

> **Changed in v18:** `SERVICES_METADATA` moved from `@web/env` into `@web/core/utils/hooks`. Added `useServiceProtectMethodHandling` for test patching.

> **Changed in v19:** `useService` auto-wraps reactive services with `useState()`. `useAutofocus` gained ShadowRoot support.

### Timing Hooks (`@web/core/utils/timing`)

| Hook | Signature | Description |
|------|-----------|-------------|
| `useDebounced` | `(callback, delay, options?)` → `Function & { cancel }` | Debounced callback, auto-cancelled on unmount |
| `useThrottleForAnimation` | `(func)` → `Function & { cancel }` | Throttles to `requestAnimationFrame` |

```js
import { useDebounced, useThrottleForAnimation } from "@web/core/utils/timing";

setup() {
    this.debouncedSearch = useDebounced(this.search, 300);
    this.throttledDrag = useThrottleForAnimation(this.onDrag);
}
```

### Hotkey Hook (`@web/core/hotkeys/hotkey_hook`)

```js
import { useHotkey } from "@web/core/hotkeys/hotkey_hook";

setup() {
    useHotkey("control+s", () => this.save(), { bypassEditableProtection: true });
    useHotkey("escape", () => this.discard());
}
```

Options: `{ allowRepeat?, bypassEditableProtection?, global?, area?: () => HTMLElement, isAvailable?: () => boolean }`

### Command Hook (`@web/core/commands/command_hook`)

```js
import { useCommand } from "@web/core/commands/command_hook";

setup() {
    useCommand("Save Record", () => this.save(), { hotkey: "control+s", category: "default" });
}
```

### Popover Hook (`@web/core/popover/popover_hook`)

```js
import { usePopover } from "@web/core/popover/popover_hook";

setup() {
    this.popover = usePopover(MyPopoverContent, { position: "bottom-start" });
}
onButtonClick(ev) {
    this.popover.open(ev.target, { value: 42 });
}
```

Options: `{ onClose?, popoverClass?, position?, animation?, arrow?, fixedPosition?, useBottomSheet? }`

> **Changed in v19:** Added `useBottomSheet` option.

### Tooltip Hook (`@web/core/tooltip/tooltip_hook`)

| Hook | Signature | Description |
|------|-----------|-------------|
| `useTooltip` | `(refName, params)` → `void` | Attaches tooltip to referenced element |

### Position Hook

| Hook | Signature | Description |
|------|-----------|-------------|
| `usePosition` | `(refName, getTarget, options?)` → `{ lock(), unlock() }` | Keeps popper positioned relative to target |

> **Changed in v18:** Import path moved from `@web/core/position_hook` to `@web/core/position/position_hook`.

### Transition Hook (`@web/core/transition`)

| Hook | Signature | Description |
|------|-----------|-------------|
| `useTransition` | `({ name, initialVisibility?, ... })` → `{ shouldMount, className, stage }` | CSS transition state for mount/unmount |

### Dropdown Hooks (`@web/core/dropdown/dropdown_hooks`)

| Hook | Versions | Description |
|------|----------|-------------|
| `useDropdownState` | **v18+** | Creates reactive state for controlling a Dropdown |
| `useDropdownCloser` | **v18+** | Controls to close a wrapping dropdown |
| `useDropdownGroup` | **v18+** | Manages dropdown group membership |
| `useDropdownNesting` | **v18+** | Handles nested dropdown behavior |
| `useDropdownNavigation` | **v17 only** | Replaced by `useNavigation` in v18 |

### Dropzone Hooks (`@web/core/dropzone/dropzone_hook`)

| Hook | Versions | Description |
|------|----------|-------------|
| `useDropzone` | **v18+** | Standard file drop zone overlay |
| `useCustomDropzone` | **v18+** | Custom dropzone with user-provided component |

### Other Hooks

| Hook | Import | Versions | Description |
|------|--------|----------|-------------|
| `useActiveElement` | `@web/core/ui/ui_service` | all | Traps focus within referenced DOM node |
| `useOwnDebugContext` | `@web/core/debug/debug_context` | all | Creates debug context in sub-environment |
| `useEnvDebugContext` | `@web/core/debug/debug_context` | all | Returns debug context from environment |
| `useDebugCategory` | `@web/core/debug/debug_context` | all | Activates a debug category |
| `useRegistry` | `@web/core/registry_hook` | **v18+** | Reactive state tracking a registry's entries |
| `useSortable` | `@web/core/utils/sortable_owl` | all | Drag-and-drop sortable |
| `useAutoresize` | `@web/core/utils/autoresize` | all | Auto-resizes textarea/input |
| `useFileViewer` | `@web/core/file_viewer/file_viewer_hook` | all | Opens/closes file viewer overlay |
| `useNavigation` | `@web/core/navigation/navigation` | **v18+** | Keyboard navigation within container |
| `useVirtual` | — | **v17 only** | Virtual scrolling for lists |
| `useVirtualGrid` | — | **v18+** | Grid-aware virtual scrolling (replaced `useVirtual`) |
| `useEmojiPicker` | `@web/core/emoji_picker/emoji_picker` | all | Sets up emoji picker popover |

### View/Field-Level Hooks

| Hook | Import | Description |
|------|--------|-------------|
| `useInputField` | `@web/views/fields/input_field_hook` | Manages input for field editing with validation |
| `useNumpadDecimal` | `@web/views/fields/numpad_decimal_hook` | Replaces numpad decimal with locale separator |
| `useTranslationDialog` | `@web/views/fields/translation_button` | Opens translation dialog |
| `useSetupAction` | `@web/webclient/actions/action_hook` | Wires action lifecycle |
| `useRecordObserver` | `@web/model/record_hook` (approx) | Observes record changes |
| `useTagNavigation` | `@web/core/record_selectors/tag_navigation_hook` | Keyboard nav between tags |

> **Changed in v19:** `useTagNavigation(refName, deleteTag)` → `useTagNavigation(refName, options = {})`.

### Hooks Added/Removed by Version

**Added in v18:** `useCustomDropzone`, `useDropdownCloser`, `useDropdownGroup`, `useDropdownNesting`, `useDropdownState`, `useDropzone`, `useFileUploader`, `useFormViewInDialog`, `useMagicColumnWidths`, `useNavigation`, `useRegistry`, `useVirtualGrid`

**Removed in v18:** `useDropdownNavigation`, `useGetDefaultCondition`, `useGetDomainTreeDescription`, `useLoadDisplayNames`, `useSetupView`, `useVirtual`

**Added in v19:** `useColorPicker`, `useDeleteRecords`, `useExportRecords`, `usePicker`, `useSquareSelection`, `useViewportChange`

**Removed in v19:** `useClickHandler`, `useGetTreeDescription`, `useLoadFieldInfo`, `useLoadPathDescription`, `useMakeGetConditionDescription`, `useMakeGetFieldDef`, `useViewArch`

---

## Dialog Service

### Opening a Dialog

```js
import { useOwnedDialogs } from "@web/core/utils/hooks";
import { ConfirmationDialog } from "@web/core/confirmation_dialog/confirmation_dialog";

setup() {
    this.addDialog = useOwnedDialogs();
}

onDeleteClick() {
    this.addDialog(ConfirmationDialog, {
        title: "Delete Record?",
        body: "This action cannot be undone.",
        confirm: async () => {
            await this.deleteRecord();
        },
        cancel: () => {},
        confirmLabel: "Delete",
        confirmClass: "btn-danger",
    });
}
```

### `dialog.add()` Signature

```js
dialog.add(DialogComponent, props, options?)
```

- **Returns:** `() => void` — function to programmatically close the dialog
- `options.onClose` — `() => void` callback when dialog is closed

### `ConfirmationDialog` Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `close` | `Function` | (injected) | Close function — injected by dialog service |
| `title` | `string` | `"Confirmation"` | Dialog title |
| `body` | `string` | (required v17, optional v19) | Dialog body text |
| `confirm` | `Function?` | — | Confirm callback. If returns `false`, dialog stays open |
| `confirmLabel` | `string?` | `"Ok"` | Confirm button label |
| `confirmClass` | `string?` | `"btn-primary"` | Confirm button CSS class |
| `cancel` | `Function?` | — | Cancel callback |
| `cancelLabel` | `string?` | `"Cancel"` | Cancel button label |
| `dismiss` | `Function?` | — | Called on backdrop click / ESC |

**`AlertDialog`** extends `ConfirmationDialog` with `title` default `"Alert"` and additional `contentClass` string prop.

**Import:** `import { AlertDialog } from "@web/core/confirmation_dialog/confirmation_dialog";`

> **Changed in v19:** `body` prop changed from required to optional. `closeAll()` accepts params, added `isBeingClosed` double-close guard. `onRemove` is now async.

---

## Notification Service

```js
import { useService } from "@web/core/utils/hooks";

setup() {
    this.notification = useService("notification");
}

onSave() {
    this.notification.add("Record saved successfully", { type: "success" });
}

onError() {
    this.notification.add("Something went wrong", {
        type: "danger",
        sticky: true,
        buttons: [{
            name: "Retry",
            primary: true,
            onClick: () => this.retry(),
        }],
    });
}
```

### `notification.add()` Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `title` | `string` | — | Notification title |
| `type` | `"warning" \| "danger" \| "success" \| "info"` | — | Visual type |
| `sticky` | `boolean` | `false` | If `true`, does not auto-close |
| `autocloseDelay` | `number` | `4000` | Auto-close delay in ms (v18+) |
| `className` | `string` | — | Extra CSS class |
| `onClose` | `Function` | — | Callback when notification closes |
| `buttons` | `Array<{ name, icon?, primary?, onClick }>` | — | Action buttons |

> **v17:** No `autocloseDelay` option — hardcoded 4000ms.

> **v18:** Added `autocloseDelay` option. Timer logic in service.

> **v19:** Timer logic removed from service, moved to `Notification` component. Service only manages the registry.

---

## Custom Field Widget

### Standard Field Props

```js
import { standardFieldProps } from "@web/views/fields/standard_field_props";

// standardFieldProps = { id: String (opt), name: String, readonly: Boolean (opt), record: Object }
// Unchanged across v17/v18/v19.
```

### Field Registration Object

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `component` | `Component` | Yes | The OWL component class |
| `displayName` | `string` | Yes | Human-readable name (translatable) |
| `supportedTypes` | `string[]` | Yes | Field types this widget supports |
| `extractProps` | `(fieldInfo, dynamicInfo) => props` | Yes | Extracts widget-specific props from the view node |
| `supportedOptions` | `Array` | No | Metadata for the form builder UI |
| `isEmpty` | `(record, fieldName) => boolean` | No | Custom emptiness check |
| `additionalClasses` | `string[]` | No | CSS classes added to field wrapper |

### Complete Custom Widget Example

```js
/** @odoo-module */
import { Component, useState } from "@odoo/owl";
import { _t } from "@web/core/l10n/translation";
import { registry } from "@web/core/registry";
import { standardFieldProps } from "@web/views/fields/standard_field_props";

export class StarRatingField extends Component {
    static template = "my_module.StarRatingField";
    static props = {
        ...standardFieldProps,
        maxStars: { type: Number, optional: true },
    };
    static defaultProps = {
        maxStars: 5,
    };

    get value() {
        return this.props.record.data[this.props.name] || 0;
    }

    async onStarClick(star) {
        if (!this.props.readonly) {
            await this.props.record.update({ [this.props.name]: star });
        }
    }
}

export const starRatingField = {
    component: StarRatingField,
    displayName: _t("Star Rating"),
    supportedTypes: ["integer", "float"],
    extractProps: ({ options }) => ({
        maxStars: options.max_stars ? Number(options.max_stars) : 5,
    }),
};

registry.category("fields").add("star_rating", starRatingField);
```

```xml
<templates>
    <t t-name="my_module.StarRatingField">
        <div class="d-flex gap-1">
            <t t-foreach="Array.from({length: props.maxStars}, (_, i) => i + 1)" t-as="star" t-key="star">
                <i t-att-class="star &lt;= value ? 'fa fa-star text-warning' : 'fa fa-star-o'"
                   t-on-click="() => this.onStarClick(star)"
                   style="cursor: pointer;" />
            </t>
        </div>
    </t>
</templates>
```

Use in XML view: `<field name="rating" widget="star_rating" options="{'max_stars': 10}"/>`

> **No significant API changes** in field registration between v17/v18/v19.

---

## Custom Service Definition

```js
/** @odoo-module */
import { registry } from "@web/core/registry";
import { reactive } from "@odoo/owl";

export const counterService = {
    dependencies: ["notification"],
    start(env, { notification }) {
        const state = reactive({ count: 0 });

        function increment() {
            state.count++;
            notification.add(`Count is now ${state.count}`, { type: "info" });
        }

        function reset() {
            state.count = 0;
        }

        return { state, increment, reset };
    },
};

registry.category("services").add("counter", counterService);
```

**Consuming:**
```js
setup() {
    this.counter = useService("counter");
}
onButtonClick() {
    this.counter.increment();
}
```

### Service Object Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `dependencies` | `string[]` | No | Names of services this one depends on |
| `start` | `(env, deps) => ServiceValue` | Yes | Factory function; return value is what `useService()` returns |
| `async` | `string[]` | No | Method names to protect against destroyed component calls |

### Notable Built-in Services

| Service | Dependencies | Return Value |
|---------|-------------|--------------|
| `dialog` | `["overlay"]` | `{ add, closeAll }` |
| `notification` | (none) | `{ add }` |
| `hotkey` | `["ui"]` | `{ add, registerIframe }` |
| `effect` | `["overlay"]` | `{ add }` |
| `popover` | `["overlay"]` | `{ add }` |
| `overlay` | (none) | `{ add, overlays }` |
| `ui` | (none) | `{ activeElement, bus, ... }` |
| `orm` | (none) | ORM methods |
| `rpc` | (none) | RPC function |
| `title` | (none) | `{ current, getParts, setParts }` |
| `router` | (none) | Router utilities |
| `command` | (none) | Command palette API |
| `user` | (none) | Current user info |
| `field` | (none) | Field metadata loading |
| `cookie` | (none) | Cookie get/set (v17 is utility, not service) |
| `file_upload` | (none) | File upload management |
| `localization` | (none) | Locale info |

---

## Registries (all versions)

```javascript
import { registry } from "@web/core/registry";

registry.category("fields").add("my_widget", { component: MyField, supportedTypes: ["char"] });
registry.category("actions").add("my_action", MyActionComponent);
registry.category("services").add("my_service", serviceDefinition);
registry.category("systray").add("my_item", { Component: MySystray }, { sequence: 43 });
registry.category("views").add("my_view", MyView);
```

**Key categories:** `fields`, `views`, `actions`, `services`, `main_components`, `systray`, `effects`, `formatters`, `parsers`, `user_menuitems`, `error_handlers`.

---

## Patching Existing Components (all versions)

```javascript
import { patch } from "@web/core/utils/patch";
import { FormController } from "@web/views/form/form_controller";

patch(FormController.prototype, {
    setup() {
        super.setup();
        // custom logic
    },
});
```

---

## OWL Template Syntax

```xml
<t t-if="condition">...</t>
<t t-foreach="items" t-as="item" t-key="item.id">...</t>  <!-- t-key REQUIRED in Owl -->
<t t-esc="value"/>       <!-- escaped output -->
<t t-out="htmlValue"/>   <!-- raw output (use with Markup); replaces deprecated t-raw -->
<t t-set="var" t-value="expr"/>
<t t-component="props.comp" t-props="props.compProps"/>
<t t-slot="default"/>
<button t-on-click="handler"/>
<div t-att-class="{'active': state.isActive}"/>
<input t-ref="myInput"/>
```

---

## Client Action Example

```javascript
import { Component, useState, onWillStart } from "@odoo/owl";
import { registry } from "@web/core/registry";
import { useService } from "@web/core/utils/hooks";

class MyDashboard extends Component {
    static template = "my_module.MyDashboard";
    static props = ["*"];
    setup() {
        this.action = useService("action");
        this.orm = useService("orm");
    }
}
registry.category("actions").add("my_module.dashboard", MyDashboard);
```

```xml
<record id="action_dashboard" model="ir.actions.client">
    <field name="name">Dashboard</field>
    <field name="tag">my_module.dashboard</field>
</record>
```

---

## Import Path Reference

| What | Import Path | Versions |
|------|-------------|----------|
| `Component`, `useState`, `useRef`, `useEffect`, `useEnv`, `useSubEnv`, `useChildSubEnv` | `@odoo/owl` | all |
| `onWillStart`, `onMounted`, `onWillUpdateProps`, `onWillUnmount`, `onWillDestroy`, `onPatched` | `@odoo/owl` | all |
| `useComponent`, `useExternalListener` | `@odoo/owl` | all |
| `status`, `toRaw`, `markRaw`, `markup`, `reactive`, `xml` | `@odoo/owl` | all |
| `EventBus`, `App` | `@odoo/owl` | all |
| `useService`, `useBus`, `useAutofocus`, `useOwnedDialogs`, `useChildRef`, `useForwardRefToParent`, `useSpellCheck`, `useRefListener` | `@web/core/utils/hooks` | all |
| `useDebounced`, `useThrottleForAnimation` | `@web/core/utils/timing` | all |
| `debounce`, `throttleForAnimation`, `batched` | `@web/core/utils/timing` | all |
| `useHotkey` | `@web/core/hotkeys/hotkey_hook` | all |
| `getActiveHotkey` | `@web/core/hotkeys/hotkey_service` | all |
| `useCommand` | `@web/core/commands/command_hook` | all |
| `usePopover` | `@web/core/popover/popover_hook` | all |
| `useTooltip` | `@web/core/tooltip/tooltip_hook` | all |
| `usePosition` | `@web/core/position_hook` (v17), `@web/core/position/position_hook` (v18+) | all |
| `useTransition`, `Transition` | `@web/core/transition` | all |
| `useActiveElement` | `@web/core/ui/ui_service` | all |
| `useSortable` | `@web/core/utils/sortable_owl` | all |
| `useAutoresize` | `@web/core/utils/autoresize` | all |
| `useFileViewer` | `@web/core/file_viewer/file_viewer_hook` | all |
| `useOwnDebugContext`, `useDebugCategory`, `useEnvDebugContext` | `@web/core/debug/debug_context` | all |
| `useDropdownState`, `useDropdownCloser` | `@web/core/dropdown/dropdown_hooks` | 18/19 |
| `useDropzone`, `useCustomDropzone` | `@web/core/dropzone/dropzone_hook` | 18/19 |
| `useRegistry` | `@web/core/registry_hook` | 18/19 |
| `useNavigation` | `@web/core/navigation/navigation` | 18/19 |
| `registry` | `@web/core/registry` | all |
| `_t` | `@web/core/l10n/translation` | all |
| `browser` | `@web/core/browser/browser` | all |
| `cookie` | `@web/core/browser/cookie` | all |
| `routeToUrl` | `@web/core/browser/router_service` | all |
| `Domain` | `@web/core/domain` | all |
| `loadBundle` | `@web/core/assets` | all |
| `session` | `@web/session` | all |
| `evaluateBooleanExpr`, `evaluateExpr` | `@web/core/py_js/py` | all |
| `url` | `@web/core/utils/urls` | all |
| `fuzzyLookup` | `@web/core/utils/search` | all |
| `renderToString` | `@web/core/utils/render` | all |
| `humanNumber`, `formatFloat` | `@web/core/utils/numbers` | all |
| `deepEqual`, `omit` | `@web/core/utils/objects` | all |
| `shallowEqual` | `@web/core/utils/arrays` | all |
| `checkFileSize` | `@web/core/utils/files` | all |
| `Dialog` | `@web/core/dialog/dialog` | all |
| `ConfirmationDialog`, `AlertDialog` | `@web/core/confirmation_dialog/confirmation_dialog` | all |
| `Dropdown` | `@web/core/dropdown/dropdown` | all |
| `DropdownItem` | `@web/core/dropdown/dropdown_item` | all |
| `CheckBox` | `@web/core/checkbox/checkbox` | all |
| `localization` | `@web/core/l10n/localization` | all |
| `standardFieldProps` | `@web/views/fields/standard_field_props` | all |
| `useInputField` | `@web/views/fields/input_field_hook` | all |
| `useNumpadDecimal` | `@web/views/fields/numpad_decimal_hook` | all |
| `useSetupAction` | `@web/webclient/actions/action_hook` | all |
| `x2ManyCommands`, `ORM` | `@web/core/orm_service` | all |
| `rpc` | `@web/core/network/rpc` | 18/19 |
| `download` | `@web/core/network/download` | all |
| `SERVICES_METADATA` | `@web/env` (v17), `@web/core/utils/hooks` (v18+) | varies |

---

## Legacy Widget System

Present but deprecated in all three versions. All new development must use OWL. The old `Widget` class coexists with OWL but receives no new features.
