# Colocation

The conventions define how different types of code should be organized within the codebase. There are two main categories:

1. **Colocated Types** - Code that should be placed as close as possible to where it's used
2. **Non-Colocated Types** - Code that encapsulates broader workflows or libraries

**ALL** directories **MUST** encapsulate all logic that is **ONLY** used in that directory.

---

## Colocated Types

Colocated types are code artifacts that should be placed as close as possible to where they are used. The principle is **inline when possible, colocate when shared**.

### Views

`.ghtml` templates and their compiled `.gleam` modules.

#### File Locations

**Global:**

```
/apps/proxima_lexeme/src/views/{view_name}/
├── {view_name}.ghtml     ← view input (snake_case)
└── {view_name}.gleam     ← compiled view output
```

**Local:**

```
**/views/{view_name}/
├── {view_name}.ghtml
└── {view_name}.gleam
```

#### Naming Convention

**ALL** ghtml files **MUST** be in `snake_case`.

#### Rules

- Place views in the closest `views/` directory to where they are used
- If used by multiple route groups, place in `/apps/proxima_lexeme/src/views/`
- Views should be self-contained (template + compiled output in same directory)

---

### Queries

`.sql` functions and their compiled `.gleam` modules.

#### File Locations

**Global:**

```
/apps/proxima_lexeme/src/queries/{query_name}/
├── {query_name}.sql      ← query input (snake_case)
└── {query_name}.gleam    ← compiled query output
```

**Local:**

```
**/queries/{query_name}/
├── {query_name}.sql
└── {query_name}.gleam
```

#### Naming Convention

**ALL** sql files **MUST** be in `snake_case`.

#### Rules

- Place queries in the closest `queries/` directory to where they are used
- If used by multiple route groups, place in `/apps/proxima_lexeme/src/queries/`
- Each `.sql` file should contain exactly ONE SQL query
- File name becomes the function name (snake_case)

#### Squirrel Integration

Queries use Squirrel for type-safe SQL generation:

```bash
# Generate type-safe functions from SQL files
gleam run -m squirrel

# Check SQL is up-to-date (for CI)
gleam run -m squirrel check
```

---

### Utilities

`.gleam` functions that must not be inlined to the file (shared helper functions).

#### File Locations

**Global:**

```
/apps/proxima_lexeme/src/utilities/
├── {utility_name}.gleam                ← snake_case
└── {utility_name}/
    └── {sub_utility_name}.gleam
```

**Local:**

```
**/utilities/
├── {utility_name}.gleam
└── {utility_name}/
    └── {sub_utility_name}.gleam
```

#### Naming Convention

**ALL** gleam files **MUST** be in `snake_case`.

#### Rules

- Only extract to utilities when the function is used by multiple files
- Keep utilities close to their primary usage
- Use for: helper functions, formatting utilities, validation logic

---

### Constants

`.gleam` constants that must not be inlined to the file.

#### File Locations

**Global:**

```
/apps/proxima_lexeme/src/constants/
└── {constant's_domain_name}.gleam      ← snake_case
```

**Local:**

```
**/constants/
└── {constant's_domain_name}.gleam
```

#### Naming Convention

**ALL** gleam files **MUST** be in `snake_case`.

#### Rules

- Group constants by domain (e.g., `scoring_constants.gleam`, `api_constants.gleam`)
- Only extract when constants are shared across multiple files
- Prefer inlining for file-specific constants

---

### Factories

Test data generators using [blah](https://github.com/massivefermion/blah).

> **Note:** Factories are **colocated with their schema** in business domain directories in `packages/proxima_lexeme_db/src/schema/`. See [Database Conventions](./database.md) for details.

#### File Locations

Factories are **colocated with their corresponding schema files** organized by **business domain** in `packages/proxima_lexeme_db/src/schema/`:

```
packages/proxima_lexeme_db/src/schema/
├── main.sql
├── lexemes/                             ← Business domain
│   ├── lexemes.sql                      ← table schema
│   ├── lexemes_factory.gleam            ← factory (colocated)
│   └── indexes/
│       └── idx_lexemes_lemma.sql        ← index (colocated)
├── words/                               ← Business domain
│   ├── words.sql                        ← table schema
│   ├── words_factory.gleam              ← factory (colocated)
│   └── indexes/
│       └── idx_words_lexeme_id.sql      ← index (colocated)
└── get_target_lexemes/                  ← View (no indexes)
    ├── get_target_lexemes.sql
    └── get_target_lexemes_factory.gleam
```

#### Naming Conventions

**ALL** gleam files **MUST** be in `snake_case`.

Factory files follow the pattern: `{schema_name}_factory.gleam`

#### Rules

- **ALL** query-able structures (tables, views, materialized views) **MUST** have a factory
- **ALL** factories **MUST** be **colocated** with their schema (in the same directory)
- Factories use Squirrel-generated types and blah to generate fake data

#### Factory Colocation Rule

**Bad - schema by itself:**

```
schema/lexemes.sql
```

**Good - schema with colocated factory and indexes (business domain):**

```
schema/
└── lexemes/                             ← Business domain
    ├── lexemes.sql                      ← schema definition
    ├── lexemes_factory.gleam            ← factory generated from schema
    └── indexes/                         ← indexes colocated
        ├── idx_lexemes_lemma.sql
        └── idx_lexemes_score.sql
```

#### Factory Workflow

```
schema ← Database Schema (schema/lexemes/lexemes.sql) ← Business domain
  ↓
squirrel ← Generates gleam type
  ↓
factory ← Uses blah to generate fake data (colocated: lexemes_factory.gleam)
  ↓
tests ← Use factory to seed mocked database
```

---

### Documentation

`.md` files used for more in-depth documentation.

#### File Locations

**Global:**

```
/docs/
├── {documentation_name}.md              ← kebab-case recommended
└── {documentation_name}/
    └── {sub_documentation_name}.md
```

**Local:**

```
**/docs/
└── {documentation_name}.md
```

#### Rules

- Global documentation lives in `/docs/` for whole-repo and GitHub accessibility
- Local documentation for specific modules should be colocated
- Use for: business logic workflows, complex SQL explanations, architecture decisions

---

### Tests

[glacier_gleeunit](https://hexdocs.pm/glacier_gleeunit/index.html) tests used for testing endpoints, queries, workflows, etc.

See [Testing Conventions](./testing.md) for details on running individual tests or the full suite.

#### File Locations

**Global:**

```
/apps/proxima_lexeme/src/tests/
├── {test_name}_test.gleam               ← snake_case
└── {test_name}/
    └── {sub_test_name}_test.gleam
```

**Local:**

```
**/tests/
├── {test_name}_test.gleam
└── {test_name}/
    └── {sub_test_name}_test.gleam
```

#### Naming Convention

**ALL** gleam files **MUST** be in `snake_case`.

#### Rules

- Colocate tests with the code they test when possible
- Global tests in `/apps/proxima_lexeme/src/tests/` for integration and cross-cutting tests
- Follow naming: `{module_name}_test.gleam`
- **ALL** tests involving Database **MUST** use mocked database with factories

---

### Client

Client-side code written in TypeScript. Only runs in the browser (USE RARELY).

#### File Locations

**Global:**

```
/apps/proxima_lexeme/src/client/
├── *.ts                                 ← kebab-case
└── {structure_name}/
    └── *.ts
```

**Local:**

```
**/client/
├── *.ts
└── {structure_name}/
    └── *.ts
```

#### Naming Convention

**ALL** typescript files **MUST** be in `kebab-case`.

#### Use Cases

- Integrate some client library
- Develop a web-component
- Handle browser-specific functionality

#### Rules

- Prefer server-side rendering with Gleam when possible
- Use TypeScript for client-side code (not Gleam compiled to JS)
- Vite handles bundling - TypeScript can be colocated where used

#### Gleam → JS Note

While Gleam CAN compile to JS (thus can run in the browser), the interoperability is difficult to manage. Therefore, client-side code will only be written in TypeScript.

---

## Non-Colocated Types

Non-Colocated types are code artifacts that encapsulate broader concerns and cannot be easily inlined. These represent workflows and libraries that span multiple features.

### Business Logic

Encapsulate logic written in `.gleam` or `.sql` files to handle business-specific workflow logic. Business logic workflows can encapsulate other smaller workflows.

#### File Location

```
/packages/business_logic/src/{specific_workflow_name}/
├── index.gleam                          ← workflow entry point
├── queries/                             ← workflow-specific queries
│   └── some_query/
│       ├── some_query.sql
│       └── some_query.gleam
├── utilities/                           ← workflow-specific utilities
│   └── helper.gleam
└── docs/                                ← workflow documentation
    └── workflow.md
```

#### Examples

- "get_next_words_to_study"
- "handle_adaptive_difficulty"
- "generate_contexts"
- "calculate_specific_metric"

#### Rules

- Each workflow gets its own directory under `/packages/business_logic/src/`
- The entry point is always `index.gleam`
- Can contain nested colocated types (queries, utilities, docs)
- Use for complex, multi-step business processes

#### Example Structure

```
packages/business_logic/src/
└── context_generation/
    ├── index.gleam                      ← entry point
    ├── queries/
    │   └── get_candidate_words/
    │       ├── get_candidate_words.sql
    │       └── get_candidate_words.gleam
    ├── utilities/
    │   └── prompt_builder.gleam
    └── docs/
        └── context_generation.md
```

---

### Libraries

Encapsulate libraries to work well with repositories.

#### File Location

```
/packages/{library_name}/
└── src/
    ├── index.gleam                      ← library entry point
    └── ...                              ← library files
```

#### Examples

- `data_star` - Data-Star framework integration
- `proxima_lexeme_db` - Database package

#### Rules

- Each library gets its own directory under `/packages/`
- The entry point is always `index.gleam`
- Libraries should be self-contained and reusable
- Document public API with Gleam doc comments

#### Example Structure

```
packages/
├── data_star/
│   └── src/
│       ├── index.gleam                  ← entry point
│       ├── attributes.gleam             ← Data-Star attributes
│       └── types.gleam                  ← Type definitions
└── proxima_lexeme_db/
    └── src/
        ├── index.gleam                  ← entry point
        ├── connection.gleam             ← Connection handling
        ├── migrations.gleam             ← Migration utilities
        └── schema/                      ← Database schema & factories
            ├── main.sql
            ├── lexemes/
            │   ├── lexemes.sql
            │   └── lexemes_factory.gleam
            └── words/
                ├── words.sql
                └── words_factory.gleam
```
