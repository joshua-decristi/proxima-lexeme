# Conventions

## File Structure

```
docs/                                    - repository documentation

apps/                                    - all applications in repository
└── proxima_lexeme/                      - core gleam application
    └── src/

packages/                                - any new packages, librarys, or library wrappers
├── business_logic/                      - business_logic gleam package
│   └── src/
├── data_star/                           - data-star gleam SDK package
│   └── src/
└── proxima_lexeme_db/                   - database gleam package
    └── src/
```

**ALL files are still colocated** — library wrappers, databases, business_logic, etc are stored in `/packages` directory.
**ALL apps are located in `/apps`**

## Core Principle: Co-location > Separation of Concerns

This project follows a **co-location** philosophy where code is organized by feature and proximity to usage, rather than by technical layer (models, views, controllers).

## Frontend Philosophy

We use **[Data-Star](https://data-star.dev/)** as our frontend framework, enabling reactive web apps with **no user-written JavaScript**. All interactivity is handled via declarative HTML attributes (`data-*`).

> **The best client-side code is no client-side code.**

See [Data-Star Conventions](./data-star.md) for detailed usage patterns.

## File Naming Conventions

| File Type        | Convention | Example                |
| ---------------- | ---------- | ---------------------- |
| Gleam modules    | snake_case | `word_selection.gleam` |
| GHTML templates  | snake_case | `study_view.ghtml`     |
| SQL files        | snake_case | `get_lexemes.sql`      |
| TypeScript files | kebab-case | `progress-bar.ts`      |
| HTML files       | kebab-case | `error-message.html`   |
| CSS files        | kebab-case | `study-card.css`       |

### Other Naming Conventions

| Item      | Convention | Example                   |
| --------- | ---------- | ------------------------- |
| Types     | PascalCase | `type Lexeme { ... }`     |
| Functions | snake_case | `fn calculate_score(...)` |
| Constants | PascalCase | `const MaxLexemes = 25`   |
| Variables | snake_case | `let word_count = ...`    |
| Records   | PascalCase | `Lexeme(id, lemma, ...)`  |

## Overview

The conventions define how different types of code should be organized within the codebase. There are two main categories:

1. **Colocated Types** - Code that should be placed as close as possible to where it's used
2. **Non-Colocated Types** - Code that encapsulates broader workflows or libraries

See [Code Types](./code-types.md) for detailed documentation on both categories.

## Quick Reference

| Type      | Description                            | Global Location                                 | Local Location        |
| --------- | -------------------------------------- | ----------------------------------------------- | --------------------- |
| `views`   | `.ghtml` templates & compiled `.gleam` | `/apps/proxima_lexeme/src/views/{name}/*`       | `**/views/{name}/*`   |
| `queries` | `.sql` functions & compiled `.gleam`   | `/apps/proxima_lexeme/src/queries/{name}/*`     | `**/queries/{name}/*` |
| `schema`  | Database schema by business domain     | `/apps/proxima_lexeme/src/schema/{domain}/**/*` | N/A                   |

**Note:** Schema is organized by **business domain** (e.g., `lexemes/`, `words/`). Each domain contains:

- Schema SQL file (e.g., `lexemes.sql`)
- Colocated factory (e.g., `lexemes_factory.gleam`)
- Colocated indexes in `indexes/` subdirectory

## File Conventions

### Directory Encapsulation

**ALL** directories **MUST** encapsulate all logic that is **ONLY** used in that directory. This follows the [Placement Rules](./placement-rules.md) which outline the colocation rules.

```
apps/
└── proxima_lexeme/
    └── src/
        └── routes/
            └── some_endpoint/
                ├── handler.gleam              ← endpoint handler
                ├── views/
                │   └── specific_view/         ← ONLY used by this endpoint
                │       ├── specific_view.ghtml
                │       └── specific_view.gleam
                └── queries/
                    └── specific_query/        ← ONLY used by this endpoint
                        ├── specific_query.sql
                        └── specific_query.gleam
```

## Import Organization

```gleam
// 1. Gleam standard library
import gleam/dict
import gleam/list
import gleam/option.{type Option, Some, None}

// 2. Third-party packages
import wisp.{type Request, type Response}
import gleam_json

// 3. Internal modules
import app/web.{type Context}
import models/lexeme
import logic/scoring
```

## Key Rules

1. **ALWAYS** inline Colocated Types to usage file when possible
2. **ALWAYS** colocate to closest directory as possible
3. **ALL** directories **MUST** encapsulate all logic ONLY used in that directory
4. **ALL** gleam, ghtml, & sql files **MUST** be in `snake_case`
5. **ALL** typescript, html, & css files **MUST** be in `kebab-case`
6. When shared by root (e.g., two root routes or route & business_logic), locate in global directory
7. **NEVER write JavaScript** - Use Data-Star attributes instead (see [Data-Star Conventions](./data-star.md))

See the detailed convention files for specific rules and examples.
