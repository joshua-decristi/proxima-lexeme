# Placement Rules

The following rules determine where to place files based on their usage patterns.

**ALL** directories **MUST** encapsulate all logic that is **ONLY** used in that directory.

---

## Repository Structure

```
docs/                                    - repository documentation

apps/                                    - all applications in repository
└── proxima_lexeme/                      - core gleam application
    ├── src/
    └── test/                            ← integration/end-to-end tests

packages/                                - any new packages, librarys, or library wrappers
├── business_logic/                      - business_logic gleam package
│   ├── src/
│   └── test/                            ← integration/end-to-end tests
├── data_star/                           - data-star gleam SDK package
│   ├── src/
│   └── test/                            ← integration/end-to-end tests
└── proxima_lexeme_db/                   - database gleam package
    ├── src/
    └── test/                            ← integration/end-to-end tests
```

---

## Summary

| Case       | Usage Pattern                    | Location                                                    |
| ---------- | -------------------------------- | ----------------------------------------------------------- |
| **Case 1** | Used by only one endpoint        | In that endpoint's directory                                |
| **Case 2** | Used by another convention type  | In that convention type's directory                         |
| **Case 3** | Used by one group of routes      | In most specific shared directory                           |
| **Case 4** | Used by > 1 group of root routes | In global location (`/apps/proxima_lexeme/src/views`, etc.) |

---

## Directory Encapsulation Rule

**ALL** directories **MUST** encapsulate all logic that is **ONLY** used in that directory.

This means:

- If a view is only used by `/some-endpoint`, it goes in `/apps/proxima_lexeme/src/routes/some_endpoint/views/`
- If a query is only used by `/some-endpoint`, it goes in `/apps/proxima_lexeme/src/routes/some_endpoint/queries/`
- If a utility is only used by `/some-endpoint`, it goes in `/apps/proxima_lexeme/src/routes/some_endpoint/utilities/`

### Example: Directory Encapsulation

```
apps/
└── proxima_lexeme/
    └── src/
        └── routes/
            └── study_session/
                ├── handler.gleam              ← endpoint handler
                ├── views/
                │   └── study_card/            ← ONLY used by this endpoint
                │       ├── study_card.ghtml
                │       └── study_card.gleam
                ├── queries/
                │   └── get_current_context/   ← ONLY used by this endpoint
                │       ├── get_current_context.sql
                │       └── get_current_context.gleam
                └── utilities/
                    └── score_formatter.gleam  ← ONLY used by this endpoint
```

---

## Case 1: Single Endpoint Usage

**Rule**: When a convention type is used by only one endpoint, locate the file in that endpoint's directory.

### Example 1: View used by single endpoint

**Scenario:** `specific_view.ghtml` is used by `/some-special-endpoint`

```
apps/
└── proxima_lexeme/
    └── src/
        └── routes/
            └── some_special_endpoint/
                ├── handler.gleam
                └── views/
                    └── specific_view/            ← located closest to usage file
                        ├── specific_view.ghtml   ← view input
                        └── specific_view.gleam   ← compiled view output
```

### Example 2: Query used by single endpoint

**Scenario:** `specific_query.sql` is used by `/other-endpoint`

```
apps/
└── proxima_lexeme/
    └── src/
        └── routes/
            └── other_endpoint/
                ├── handler.gleam
                └── queries/
                    └── specific_query/           ← located closest to usage file
                        ├── specific_query.sql    ← query input
                        └── specific_query.gleam  ← compiled query output
```

---

## Case 2: Used by Another Convention Type

**Rule**: When a convention type is used by another convention type, locate the file in that convention type's directory.

### Example 1: Helper used by global view

**Scenario:** `some_helper_function.gleam` is used by `some_global_view.ghtml`

```
apps/
└── proxima_lexeme/
    └── src/
        └── views/
            └── some_global_view/
                ├── utilities/
                │   └── some_helper_function.gleam  ← located closest to its usage
                ├── some_global_view.ghtml          ← view input
                └── some_global_view.gleam          ← compiled view output
```

### Example 2: Query used by business logic

**Scenario:** `specific_query.sql` is used by `business_logic/some_workflow/`

```
packages/
└── business_logic/
    └── src/
        └── some_workflow/
            ├── index.gleam
            └── queries/
                └── specific_query/              ← located closest to usage
                    ├── specific_query.sql
                    └── specific_query.gleam
```

---

## Case 3: Used by One Group of Routes

**Rule**: When a convention type is used by one group of routes, locate the file in the most specific shared directory.

### Example: View shared within route group

**Scenario:** `specific_view.ghtml` is used by `/route-group/special-endpoint` AND `/route-group/other-endpoint`

```
apps/
└── proxima_lexeme/
    └── src/
        └── routes/
            └── route_group/
                ├── views/
                │   └── specific_view/          ← located closest to ALL usage files
                │       ├── specific_view.ghtml
                │       └── specific_view.gleam
                ├── special_endpoint/
                │   └── handler.gleam
                └── other_endpoint/
                    └── handler.gleam
```

---

## Case 4: Used by Multiple Root Routes

**Rule**: When a convention type is used by more than one group of root routes (`/apps/proxima_lexeme/src/routes/*`), locate the file in the global location (`/apps/proxima_lexeme/src/views`, `/apps/proxima_lexeme/src/queries`, `/apps/proxima_lexeme/src/utilities`, etc.)

### Example: View shared across route groups

**Scenario:** `specific_view.ghtml` is used by `/special-endpoint` AND `/other-endpoint` (different root routes)

```
apps/
└── proxima_lexeme/
    └── src/
        ├── routes/
        │   ├── special_endpoint/
        │   │   └── handler.gleam
        │   └── other_endpoint/
        │       └── handler.gleam
        └── views/
            └── specific_view/                  ← located in global location
                ├── specific_view.ghtml
                └── specific_view.gleam
```

### Example: Query shared across business logic and routes

**Scenario:** `get_user_progress.sql` is used by both a route and business logic

```
apps/
└── proxima_lexeme/
    └── src/
        ├── routes/

        │   └── dashboard/
        │       └── handler.gleam               ← uses get_user_progress
        └── queries/
            └── get_user_progress/              ← located in global location
                ├── get_user_progress.sql
                └── get_user_progress.gleam

packages/
└── business_logic/
    └── src/
        └── progress_calculation/
            └── index.gleam                     ← also uses get_user_progress
```

---

## Decision Flowchart

```
Is the file used by multiple root-level routes?
├── YES → Place in global location (/apps/proxima_lexeme/src/views/, /apps/proxima_lexeme/src/queries/, /apps/proxima_lexeme/src/utilities/, etc.)
└── NO → Is it used by multiple endpoints in the same group?
    ├── YES → Place in the shared group directory
    └── NO → Is it used by another convention type?
        ├── YES → Place in that convention type's directory
        └── NO → Place in the single endpoint's directory
```

---

## Test Placement

Tests follow Gleam's standard convention:

### Global Tests (Integration/End-to-End)

**Location:** `apps/{app_name}/test/` or `packages/{package_name}/test/`

```
apps/
└── proxima_lexeme/
    └── test/                              ← integration/end-to-end tests for the app
        ├── routes_test.gleam
        ├── workflows_test.gleam
        └── integration_test.gleam

packages/
├── business_logic/
│   └── test/                              ← integration/end-to-end tests for the package
│       └── workflow_integration_test.gleam
├── data_star/
│   └── test/
│       └── attribute_test.gleam
└── proxima_lexeme_db/
    └── test/
        └── migration_test.gleam
```

**Purpose:** These tests are for **integration/end-to-end tests** that span multiple modules or test the package/app as a whole.

**NOT for:** Testing specific sub-domains or individual modules within the package/app.

### Colocated Tests (Unit Tests)

**Location:** `**/tests/` directory colocated with the code being tested

```
apps/
└── proxima_lexeme/
    └── src/
        └── routes/
            └── study_session/
                ├── handler.gleam
                └── tests/                  ← unit tests for this endpoint
                    └── handler_test.gleam

packages/
└── business_logic/
    └── src/
        └── context_generation/
            ├── index.gleam
            └── tests/                      ← unit tests for this workflow
                └── index_test.gleam
```

**Purpose:** Tests for specific modules, endpoints, or sub-domains.

---

## File Naming

Remember the file naming conventions:

| File Type             | Convention | Example                                 |
| --------------------- | ---------- | --------------------------------------- |
| Gleam, GHTML, SQL     | snake_case | `study_view.ghtml`, `get_lexemes.sql`   |
| TypeScript, HTML, CSS | kebab-case | `progress-bar.ts`, `error-message.html` |
