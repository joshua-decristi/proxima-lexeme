# Client Side Code Conventions

**IMPORTANT: Client-side code should be EXTREMELY RARE in this project.**

We use [Data-Star](https://data-star.dev/) as our frontend framework, which enables reactive web apps with **no user-written JavaScript**. Most interactivity is handled via Data-Star's declarative `data-*` attributes.

## File Naming Convention

**ALL** typescript files **MUST** be in `kebab-case`.

Examples:

- `progress-bar.ts`
- `word-highlighter.ts`
- `error-message.ts`
- `study-card.ts`

## Core Philosophy

> **State belongs in the backend. The backend drives the frontend.**

Following [The Tao of Datastar](https://data-star.dev/guide/the_tao_of_datastar):

1. **State in the Right Place** - Most state lives in the backend, not the frontend
2. **Use Signals Sparingly** - Only use signals for user interactions (toggles, form inputs)
3. **Patch Elements & Signals** - Backend drives frontend by patching HTML and signals
4. **In Morph We Trust** - Send large chunks of DOM; morphing updates only what changed
5. **No User-JS** - Reactive frontends without writing JavaScript

---

## When to Write Client-Side Code

### RARELY - Default to Data-Star Attributes

Before writing any TypeScript, ask: **"Can this be done with Data-Star attributes?"**

**Use Data-Star attributes for:**

- Reactive signal binding (`data-signals:*`, `data-bind:*`)
- Event handling (`data-on:*`)
- Showing/hiding elements (`data-show`)
- Text content updates (`data-text`)
- Backend requests (`@get`, `@post`, `@put`, `@delete`)
- Element attribute binding (`data-attr:*`)

### Valid Use Cases for TypeScript

Only write TypeScript when **Data-Star attributes cannot accomplish the task**:

1. **Web Components** - Encapsulated custom elements with complex behavior
2. **External Scripts** - Pure functions that process data and return results
3. **Browser API Integration** - Accessing browser APIs not exposed by Data-Star
4. **Third-Party Library Integration** - Analytics, maps, charts, etc.

---

## Data-Star First Approach

### Example: Reactive Counter

**❌ Don't write JavaScript:**

```typescript
// AVOID: This can be done with Data-Star
class Counter extends HTMLElement {
  count = 0;
  // ... custom element implementation
}
```

**✅ Use Data-Star attributes:**

```html
<div data-signals:count="0">
  <span data-text="$count"></span>
  <button data-on:click="$count++">Increment</button>
  <button data-on:click="$count--">Decrement</button>
</div>
```

### Example: Form Validation

**❌ Don't validate in JavaScript:**

```typescript
// AVOID: Do validation server-side
function validateForm() { ... }
```

**✅ Send to backend:**

```html
<form data-on:submit="@post('/validate')">
  <input data-bind:email type="email" />
  <button>Submit</button>
</form>
```

### Example: Data Fetching

**❌ Don't fetch in JavaScript:**

```typescript
// AVOID: Use Data-Star's @get/@post
fetch('/api/data').then(...)
```

**✅ Use Data-Star actions:**

```html
<div data-init="@get('/load-data')">
  <!-- Content loaded from backend -->
</div>
```

---

## Web Components (When You Must)

Web components are for **complex, encapsulated UI elements** that cannot be built with Data-Star attributes alone.

### Guidelines

- Always encapsulate state
- Pass data via attributes (**props down**)
- Communicate via custom events (**events up**)
- Let Data-Star handle reactivity

### Pattern

```html
<!-- Data-Star drives the component via attributes -->
<div data-signals:result="''">
  <input data-bind:inputValue />
  <my-validator data-attr:value="$inputValue" data-on:validated="$result = evt.detail.isValid"></my-validator>
  <span data-text="$result ? 'Valid' : 'Invalid'"></span>
</div>
```

```typescript
// src/client/components/MyValidator.ts
class MyValidator extends HTMLElement {
  static get observedAttributes() {
    return ["value"];
  }

  attributeChangedCallback(name: string, oldValue: string, newValue: string) {
    if (name === "value") {
      const isValid = this.validate(newValue);
      // Event up to Data-Star
      this.dispatchEvent(new CustomEvent("validated", { detail: { isValid } }));
    }
  }

  private validate(value: string): boolean {
    // Complex validation logic
    return value.length > 5;
  }
}

customElements.define("my-validator", MyValidator);
```

### File Location

```
/src/client/
  └── components/
    └── MyValidator.ts
```

Or colocated with usage:

```
/src/routes/study_session/
  ├── handler.gleam
  └── client/
    └── ProgressIndicator.ts
```

---

## External Scripts (When You Must)

For pure utility functions that process data.

### Guidelines

- Keep functions pure (input → output)
- Pass data via arguments
- Return results (don't modify global state)
- Let Data-Star handle reactivity

### Pattern

```html
<div data-signals:result>
  <input data-bind:foo data-on:input="$result = formatInput($foo)" />
  <span data-text="$result"></span>
</div>
```

```typescript
// src/client/utils/formatters.ts
export function formatInput(data: string): string {
  return `You entered: ${data.toUpperCase()}`;
}
```

### Async Functions

If async, dispatch custom events:

```html
<div data-signals:result>
  <button data-on:click="fetchData(el, $query)" data-on:datareceived="$result = evt.detail.data">Fetch</button>
</div>
```

```typescript
// src/client/utils/api.ts
export async function fetchData(element: HTMLElement, query: string): Promise<void> {
  const data = await fetch(`/api/search?q=${query}`).then((r) => r.json());
  element.dispatchEvent(new CustomEvent("datareceived", { detail: { data } }));
}
```

---

## SSE (Server-Sent Events)

Data-Star uses SSE for real-time updates. The backend sends events to update the frontend.

### Backend Sends Events

```gleam
// Use pre-rendered HTML from ghtml templates
import app/shared/views/status_message

// Backend sends SSE events to update frontend
let status_html = status_message.render("Updated!")
sse.PatchElements(status_html)

sse.PatchSignals("{score: 0.85}")
sse.ExecuteScript("console.log('Updated')")
```

### Frontend Receives

```html
<!-- Long-lived connection for real-time updates -->
<div data-init="@get('/sse/stream')">
  <!-- DOM updated automatically via SSE -->
</div>
```

**No client-side code needed.**

---

## HTTP Status Codes

Following Data-Star's philosophy ([I'm a Teapot](https://data-star.dev/essays/im_a_teapot)):

- **Use only 2xx and 3xx status codes for human-facing UIs**
- Never expose 4xx or 5xx to humans
- Handle errors gracefully in the UI

```html
<!-- File: /src/routes/shared/views/error_message.ghtml -->
<div class="error">Something went wrong. Please try again.</div>
```

```gleam
// File: /src/routes/shared/views/error_message.ghtml

// ✓ GOOD: Return 200 with error UI
pub fn handle_error() {
  let html = error_message.render()
  wisp.html_response(html, 200)
}

// ✗ BAD: Return 500 to humans
pub fn handle_error_bad() {
  wisp.internal_server_error()
}
```

---

## CQRS Pattern

Use Command Query Responsibility Segregation for real-time apps:

```html
<!-- Single long-lived GET for updates -->
<div id="main" data-init="@get('/cqrs/stream')">
  <!-- Short-lived POSTs for commands -->
  <button data-on:click="@post('/cqrs/grade')">Submit Grade</button>
</div>
```

- **GET `/cqrs/stream`** - Long-lived SSE connection for real-time updates
- **POST `/cqrs/grade`** - Short-lived command requests

---

## File Structure

### Minimal Client Directory

```
/src/client/
  ├── index.ts              ← Entry point (register web components)
  └── components/           ← Web components (rarely needed)
    ├── Starfield.ts
    └── ProgressBar.ts
```

### Colocation (Preferred)

```
/src/routes/study_session/
  ├── handler.gleam
  ├── view.ghtml            ← Data-Star attributes here
  └── client/               ← Only if absolutely needed
    └── WordHighlighter.ts
```

---

## Build & Integration

### No Bundler Required

Data-Star works without a build step. Simply include the CDN script:

```html
<script type="module" src="https://cdn.jsdelivr.net/gh/starfederation/datastar@1.0.0-beta.11/bundles/datastar.js"></script>
```

### Vite (When Using TypeScript)

If you need to bundle TypeScript (web components):

```typescript
// vite.config.ts
import { defineConfig } from "vite";

export default defineConfig({
  build: {
    lib: {
      entry: "./src/client/index.ts",
      name: "proximaClient",
      fileName: "client",
    },
    outDir: "priv/static/js",
  },
});
```

### Loading Client Code

```html
<!-- Load Data-Star -->
<script type="module" src="https://cdn.jsdelivr.net/gh/starfederation/datastar@1.0.0-beta.11/bundles/datastar.js"></script>

<!-- Load minimal client code (only if needed) -->
<script type="module" src="/static/js/client.js"></script>
```

---

## Checklist Before Writing TypeScript

Before writing any client-side code, verify:

- [ ] Can this be done with `data-on:*` attributes?
- [ ] Can this be done with `data-signals:*` and `data-bind:*`?
- [ ] Can this be done with `@get`/`@post` actions?
- [ ] Can this be done with `data-show`/`data-text`/`data-attr:*`?
- [ ] Is this a reusable UI component that needs encapsulation?
- [ ] Is this integrating with a third-party library?

**If you checked any of the first 4, don't write TypeScript. Use Data-Star.**

---

## Summary

| Approach                 | Use When                                        |
| ------------------------ | ----------------------------------------------- |
| **Data-Star Attributes** | Always default to this                          |
| **Web Components**       | Complex encapsulated UI, reusable components    |
| **External Scripts**     | Pure data transformation, browser API access    |
| **SSE Events**           | Real-time updates, backend-driven state changes |

**Remember: The best client-side code is no client-side code.**

---

## TypeScript Configuration (When You Must)

If you must write TypeScript, use strict configuration:

```json
{
  "compilerOptions": {
    "target": "ESNext",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "lib": ["ESNext", "DOM", "DOM.Iterable"],
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "noUnusedLocals": true
  }
}
```

---

## Integration with Gleam/Wisp

Static assets are served by Wisp from `priv/static/`:

```gleam
// In proxima_lexeme.gleam
pub fn main() {
  let assert Ok(_) = wisp.configure_logger()

  // Serve static files
  let static_dir = priv_dir <> "/static"

  wisp.router()
  |> wisp.static(static_dir)
  // ... other routes
}
```
