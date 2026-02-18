# Data-Star Conventions

[Data-Star](https://data-star.dev/) is our frontend framework. It enables reactive web apps with **no user-written JavaScript** through declarative HTML attributes.

## Quick Reference

| Attribute                 | Purpose                     | Example                             |
| ------------------------- | --------------------------- | ----------------------------------- |
| `data-signals:*`          | Initialize reactive signals | `data-signals:count="0"`            |
| `data-bind:*`             | Two-way bind to form inputs | `data-bind:email`                   |
| `data-text`               | Display signal value        | `data-text="$count"`                |
| `data-show`               | Toggle visibility           | `data-show="$isOpen"`               |
| `data-attr:*`             | Set element attributes      | `data-attr:aria-expanded="$isOpen"` |
| `data-on:*`               | Handle events               | `data-on:click="$count++"`          |
| `data-init`               | Execute on mount            | `data-init="@get('/load')"`         |
| `@get/@post/@put/@delete` | Backend requests            | `@post('/submit')`                  |

---

## Core Principles

### 1. State in the Backend

> Most state should live in the backend. Since the frontend is exposed to the user, the backend should be the source of truth for your application state.

**Do:**

```html
<!-- Fetch state from backend -->
<div data-init="@get('/user/profile')">
  <span data-text="$user.name"></span>
</div>
```

**Don't:**

```html
<!-- Don't maintain complex state in signals -->
<div data-signals:user="{name: 'John', email: 'john@example.com', ...}"></div>
```

### 2. Use Signals Sparingly

> Overusing signals typically indicates trying to manage state on the frontend. Favor fetching current state from the backend rather than pre-loading and assuming frontend state is current.

**Good signal uses:**

- User interactions (toggles, modals)
- Form input binding
- Temporary UI state

```html
<!-- ✓ GOOD: UI state -->
<div data-signals:menuOpen="false">
  <button data-on:click="$menuOpen = !$menuOpen">Toggle</button>
  <nav data-show="$menuOpen">...</nav>
</div>

<!-- ✓ GOOD: Form binding -->
<input data-bind:email type="email" />
<button data-on:click="@post('/submit', {email: $email})">Submit</button>
```

### 3. In Morph We Trust

> Morphing ensures that only modified parts of the DOM are updated, preserving state and improving performance.

**Do:**

```html
<!-- Send complete HTML fragments -->
<div id="context" data-init="@get('/context/next')">
  <!-- Entire context card replaced -->
</div>
```

**Don't:**

```html
<!-- Don't try to update individual elements manually -->
<script>
  document.getElementById("score").textContent = "0.85";
</script>
```

### 4. Props Down, Events Up

When using web components, always follow this pattern:

```html
<div data-signals:result="''">
  <input data-bind:value />
  <my-component
    data-attr:input="$value" <!-- Props down (attribute) -->
    data-on:result="$result = evt.detail" <!-- Events up (custom event) -->
  ></my-component>
  <span data-text="$result"></span>
</div>
```

---

## File Organization

### Data-Star Attributes Go in HTML/GHTML

Data-Star attributes are written directly in HTML templates (`.ghtml` files compiled to Gleam using [ghtml](https://hexdocs.pm/ghtml/)).

```
/src/routes/study_session/
  ├── handler.gleam          ← Route handler
  └── views/
    └── study_view/
      ├── study_view.ghtml   ← Data-Star attributes here
      └── study_view.gleam   ← Compiled output
```

### Example View

```html
<!-- study_view.ghtml -->
<div data-signals:revealed="false" data-signals:grade="0" data-init="@get('/context/current')">
  <!-- Context Display -->
  <div id="context-card" data-on:click="$revealed = true">
    <p data-text="$context.text"></p>

    <!-- Hidden until revealed -->
    <div data-show="$revealed">
      <p data-text="$context.translation"></p>

      <!-- Grade Buttons -->
      <div class="grades">
        <button data-on:click="$grade = 1; @post('/grade', {grade: 1})">1</button>
        <button data-on:click="$grade = 2; @post('/grade', {grade: 2})">2</button>
        <button data-on:click="$grade = 3; @post('/grade', {grade: 3})">3</button>
        <button data-on:click="$grade = 4; @post('/grade', {grade: 4})">4</button>
        <button data-on:click="$grade = 5; @post('/grade', {grade: 5})">5</button>
      </div>
    </div>
  </div>

  <!-- Loading Indicator -->
  <div data-show="$_loading">Loading...</div>
</div>
```

---

## Patterns

### Pattern 1: CQRS (Command Query Responsibility Segregation)

For real-time collaborative features:

```html
<!-- Single long-lived GET for updates -->
<div id="app" data-init="@get('/stream')">
  <!-- Short-lived POSTs for commands -->
  <button data-on:click="@post('/study/grade', {grade: 4})">Grade 4</button>

  <!-- Real-time updates arrive via SSE -->
  <div data-text="$progress.knownLexemes"></div>
</div>
```

**Backend:**

```gleam
// GET /stream - Long-lived SSE connection
pub fn stream(req: Request) -> Response {
  wisp.stream_response(fn(send) {
    // Send initial state
    send(sse.PatchSignals("{knownLexemes: 47}"))

    // Stream updates as they happen
    // ...
  })
}

// POST /study/grade - Short-lived command
pub fn grade(req: Request) -> Response {
  // Process grade
  // Update database
  // Broadcast to all connected clients via SSE
  wisp.ok()
}
```

### Pattern 2: Loading Indicators

```html
<button data-indicator:_loading data-on:click="@post('/generate-context')">
  Generate Context
  <span data-show="$_loading">Loading...</span>
</button>
```

The `data-indicator:_loading` automatically creates a signal that is `true` while the request is in flight.

### Pattern 3: Accessibility

```html
<button data-on:click="$menuOpen = !$menuOpen" data-attr:aria-expanded="$menuOpen ? 'true' : 'false'">Toggle Menu</button>

<div data-attr:aria-hidden="$menuOpen ? 'false' : 'true'" data-show="$menuOpen">Menu Content</div>
```

### Pattern 4: Form Handling

```html
<form data-on:submit="@post('/login', {email: $email, password: $password})">
  <input data-bind:email type="email" data-attr:aria-invalid="$errors.email ? 'true' : 'false'" />
  <span data-text="$errors.email" data-show="$errors.email"></span>

  <input data-bind:password type="password" />

  <button data-indicator:_loading>
    Login
    <span data-show="$_loading">...</span>
  </button>
</form>
```

---

## Expressions

Data-Star expressions are evaluated in a sandboxed context. You can use:

### Signals

Prefix with `$`:

```html
<span data-text="$count"></span>

<button data-on:click="$count++">+</button>
```

### JavaScript Operators

```html
<!-- Ternary -->
<div data-text="$grade >= 4 ? 'Good!' : 'Keep practicing'"></div>

<!-- Logical -->
<div data-show="$isAuthenticated && $isPremium">Premium Content</div>

<!-- Comparison -->
<button data-on:click="$score < 0.9 && @post('/review')">Review</button>
```

### Element Reference

The `el` variable references the element:

```html
<div data-text="el.offsetHeight"></div>
```

### Multiple Statements

Separate with semicolons:

```html
<button data-on:click="$revealed = true; $grade = 0; @post('/reveal')">Reveal Answer</button>
```

---

## Backend Integration

### Sending HTML Fragments (Using GHTML)

Use `.ghtml` templates instead of raw HTML strings. GHTML compiles to type-safe Gleam code.

**File: `/src/routes/context/views/context_card.gleam`**

```gleam
// Auto-generated from context_card.ghtml - DO NOT EDIT MANUALLY
pub fn render(context: Context) -> String {
  // Compiled HTML output
}
```

**File: `/src/routes/context/views/context_card/context_card.ghtml`**

```html
<div id="context-card" class="card">
  <p>{context.text}</p>
  <span data-text="$context.score"></span>
</div>
```

**Handler:**

```gleam
import app/context/views/context_card

pub fn get_context(req: Request) -> Response {
  let context = get_next_context()
  let html = context_card.render(context)

  wisp.html_response(html, 200)
}
```

### Sending SSE Events

```gleam
import datastar_sdk

pub fn stream(req: Request) -> Response {
  wisp.stream_response(fn(send) {
    let sse = datastar_sdk.new(send)

    // Patch signals
    sse.patch_signals("{score: 0.85, knownWords: 47}")

    // Patch elements using pre-rendered HTML
    let status_html = status_component.render("Updated!")
    sse.patch_elements(status_html)

    // Execute script
    sse.execute_script("console.log('Updated')")
  })
}
```

---

## HTTP Status Codes

Following Data-Star's philosophy:

- **2xx** - Success (render the HTML/SSE)
- **3xx** - Redirect (follow the redirect)
- **4xx/5xx** - Only for machine-to-machine APIs, never for human UIs

For errors in human-facing UIs:

```gleam
// File: /src/routes/shared/views/error_message.ghtml
// <div class="error">{message}</div>

import app/shared/views/error_message

// ✓ GOOD: Return 200 with error UI
pub fn handle_error() {
  let html = error_message.render("Invalid email address")
  wisp.html_response(html, 200)
}

// ✗ BAD: Return 500 to humans
pub fn handle_error_bad() {
  wisp.internal_server_error()
}
```

---

## Common Mistakes

### ❌ Managing Complex State in Signals

```html
<!-- BAD: Don't replicate your database in signals -->
<div data-signals:lexemes="[{id: 1, lemma: 'run'}, ...]"></div>
```

### ❌ Writing JavaScript Instead of Using Attributes

```html
<!-- BAD: Don't write JS -->
<button onclick="handleClick()">Click</button>

<!-- GOOD: Use data-on -->
<button data-on:click="@post('/click')">Click</button>
```

### ❌ Manually Updating the DOM

```html
<!-- BAD: Don't manipulate DOM -->
<script>
  document.getElementById("x").style.display = "none";
</script>

<!-- GOOD: Use data-show -->
<div data-show="$isVisible"></div>
```

### ❌ Over-Fetching with Multiple Small Requests

```html
<!-- BAD: Multiple requests -->
<div data-init="@get('/user')">
  <span data-text="$user.name"></span>
</div>
<div data-init="@get('/progress')">
  <span data-text="$progress.score"></span>
</div>

<!-- GOOD: Single request with all data -->
<div data-init="@get('/dashboard')">
  <span data-text="$user.name"></span>
  <span data-text="$progress.score"></span>
</div>
```

---

## Resources

- [Data-Star Guide](https://data-star.dev/guide)
- [The Tao of Datastar](https://data-star.dev/guide/the_tao_of_datastar)
- [Reference Documentation](https://data-star.dev/reference)
- [Examples](https://data-star.dev/examples)
- [SDKs](https://data-star.dev/reference/sdks) (we'll create a Gleam SDK)

---

## Summary

1. **Default to Data-Star attributes** - No JavaScript needed
2. **Keep state in the backend** - Don't replicate data in signals
3. **Use signals sparingly** - Only for UI state and form binding
4. **Trust morphing** - Send large HTML fragments
5. **Props down, events up** - For web components
6. **Only 2xx/3xx** - For human-facing UIs
7. **CQRS for real-time** - Long-lived GET + short-lived POSTs

**The best frontend code is declarative HTML attributes.**
