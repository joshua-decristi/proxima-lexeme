# Build Process

This document outlines the multi-step build process for transpiling SQL, GHTML, and TypeScript into deployable assets.

---

## Overview

The project uses a multi-stage build process:

```
┌──────────────────────────────────────────────────────┐
│                    BUILD PIPELINE                    │
├──────────────────────────────────────────────────────┤
│                                                      │
│  Backend Service:                                    │
│  ┌─────────┐    ┌──────────────┐    ┌────────────┐   │
│  │ SQL &   │ →  │ Gleam        │ →  │ Build      │   │
│  │ GHTML   │    │ Modules      │    │            │   │
│  └─────────┘    └──────────────┘    └────────────┘   │
│       ↓                ↓                  ↓          │
│   (squirrel)      (ghtml)           (gleam build)    │
│                                                      │
│  Frontend Library Integrations & Web-Components:     │
│  ┌─────────┐    ┌──────────────┐    ┌────────────┐   │
│  │ TS/TSX  │ →  │ JS Bundle    │ →  │ Static     │   │
│  │         │    │              │    │ Build Files│   │
│  └─────────┘    └──────────────┘    └────────────┘   │
│       ↓                ↓                  ↓          │
│    (vite)         (vite bundle)     (priv/static/)   │
│                                                      │
└──────────────────────────────────────────────────────┘
```

---

## Backend Service Build

### Step 1: SQL & GHTML Sources

**Input Files:**

- `.sql` files in `src/queries/`, `src/schema/`, etc.
- `.ghtml` files in `src/views/`, `src/routes/**/views/`, etc.

**Naming Conventions:**

- **ALL** gleam, ghtml, & sql files **MUST** be in `snake_case`

### Step 2: Transpile to Gleam Modules

#### SQL → Gleam (via Squirrel)

```bash
# Generate type-safe Gleam functions from SQL queries
gleam run -m squirrel

# Check SQL is up-to-date (for CI)
gleam run -m squirrel check
```

**Output:** `.gleam` files alongside `.sql` files:

```
src/queries/get_lexemes/
  ├── get_lexemes.sql      ← Source
  └── get_lexemes.gleam    ← Generated
```

#### GHTML → Gleam (via GHTML Compiler)

```bash
# Compile GHTML templates to Gleam
gleam run -m ghtml

# Or part of build process
make build
```

**Output:** `.gleam` files alongside `.ghtml` files:

```
src/views/study_view/
  ├── study_view.ghtml     ← Source
  └── study_view.gleam     ← Generated
```

### Step 3: Build Backend

```bash
# Compile Gleam to Erlang/BEAM
gleam build

# Or with make
make build
```

**Output:**

- Compiled BEAM files in `build/`
- Executable application

---

## Frontend Build

### Step 1: TypeScript Sources

**Input Files:**

- `.ts` and `.tsx` files in `src/client/` (rarely used)

**Naming Conventions:**

- **ALL** typescript, html, & css files **MUST** be in `kebab-case`

### Step 2: Bundle with Vite

```bash
# Build client bundle
npm run build
# or
make client-build
```

**Vite Configuration:**

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

### Step 3: Static Build Files

**Output Directory:** `priv/static/`

```
priv/static/
├── js/
│   └── client.js          ← Bundled client code
├── css/
│   └── styles.css         ← Compiled CSS
└── assets/
    └── ...                ← Images, fonts, etc.
```

---

## Complete Build Workflow

### Development Build

```bash
# Build everything for development
make dev

# Or step by step:
make db-plan            # Plan schema changes
make db-apply           # Apply schema changes
gleam run -m squirrel   # Generate query types
gleam run -m ghtml      # Compile templates
gleam build             # Build backend
npm run build           # Build frontend
```

### Production Build

```bash
# Full production build
make production

# Steps:
# 1. Apply database schema
# 2. Generate Squirrel types
# 3. Compile GHTML templates
# 4. Build Gleam backend
# 5. Bundle client assets
# 6. Copy static files
```

---

## Build Commands

### Make Commands

```bash
# Backend
make build            # Build Gleam backend
make clean            # Clean build artifacts
make dev              # Development build with watch

# Database
make db-plan          # Generate migration plan
make db-apply         # Apply schema changes
make db-dump          # Dump database schema

# SQL
make sql-generate     # Generate Squirrel types
make sql-check        # Check SQL is up-to-date

# Frontend
make client-build     # Build client bundle
make client-dev       # Dev mode with hot reload

# Full build
make all              # Complete build pipeline
```

### Gleam Commands

```bash
# Build
gleam build

# Test (all tests)
gleam test

# Test (individual module with glacier_gleeunit)
gleam run -m glacier_gleeunit src/tests/lexeme_workflow_test

# Generate types from SQL
gleam run -m squirrel
gleam run -m squirrel check

# Compile templates
gleam run -m ghtml
```

**Note:** We use `glacier_gleeunit` instead of `gleeunit` to enable running individual test modules. See [Testing Conventions](./testing.md) for details.

---

## File Naming Reference

| File Type  | Convention | Examples                                      |
| ---------- | ---------- | --------------------------------------------- |
| Gleam      | snake_case | `word_selection.gleam`, `study_handler.gleam` |
| GHTML      | snake_case | `study_view.ghtml`, `error_message.ghtml`     |
| SQL        | snake_case | `get_lexemes.sql`, `update_score.sql`         |
| TypeScript | kebab-case | `progress-bar.ts`, `word-highlighter.ts`      |
| HTML       | kebab-case | `study-card.html`, `error-message.html`       |
| CSS        | kebab-case | `study-styles.css`, `layout-grid.css`         |

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Build and Test

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # Setup Gleam
      - uses: erlef/setup-beam@v1
        with:
          gleam-version: "1.4.0"
          erlang-version: "26"

      # Setup Node
      - uses: actions/setup-node@v4
        with:
          node-version: "20"

      # Install dependencies
      - run: gleam deps download
      - run: npm ci

      # Database
      - run: make db-plan
      - run: make db-apply-auto

      # Generate types
      - run: make sql-generate

      # Build
      - run: make build
      - run: make client-build

      # Test
      - run: make test

      # Verify SQL is up-to-date
      - run: make sql-check
```

---

## Troubleshooting

### Squirrel Errors

If Squirrel fails to generate types:

1. Ensure database is running and accessible
2. Check that SQL files are valid
3. Verify database schema is applied: `make db-apply`

### GHTML Errors

If GHTML compilation fails:

1. Check syntax in `.ghtml` files
2. Ensure all referenced types exist
3. Run `gleam build` to see detailed errors

### Vite Errors

If frontend build fails:

1. Check TypeScript syntax
2. Ensure all imports are valid
3. Run `npm run check` for type checking

---

## Summary

| Stage    | Input          | Tool           | Output                 |
| -------- | -------------- | -------------- | ---------------------- |
| SQL      | `.sql` files   | Squirrel       | `.gleam` query modules |
| GHTML    | `.ghtml` files | GHTML Compiler | `.gleam` view modules  |
| Backend  | `.gleam` files | Gleam Compiler | BEAM bytecode          |
| Frontend | `.ts` files    | Vite           | `priv/static/js/*.js`  |
