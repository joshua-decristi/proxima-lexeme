# Database

This document outlines the database conventions including schema management, naming conventions, factories, seeders, and queries.

**The database package is `packages/proxima_lexeme_db/`** — it contains everything related to the database:

- Schema files
- Connection engine
- Individual factories

---

## Schema Management

The Database Schema **MUST** be written **ONLY** in `.sql` files.

**ALL** schema changes **MUST** be managed by [pgschema](https://www.pgschema.com/).

**ALL** Database Schema files **MUST** be written in [modular schema files](https://www.pgschema.com/workflow/modular-schema-files).

### Schema File Structure

All schema files live in `packages/proxima_lexeme_db/src/schema/` organized by **business domain**:

```
packages/proxima_lexeme_db/
├── src/
│   ├── schema/                             ← Database schema
│   │   ├── main.sql                        # Entry point with \i directives
│   │   │
│   │   ├── lexemes/                        # Business domain: lexemes
│   │   │   ├── lexemes.sql                 # Table
│   │   │   ├── lexemes_factory.gleam       # Factory (colocated)
│   │   │   └── indexes/                    # Indexes colocated with table
│   │   │       ├── idx_lexemes_lemma.sql
│   │   │       └── idx_lexemes_score.sql
│   │   │
│   │   ├── words/                          # Business domain: words
│   │   │   ├── words.sql                   # Table
│   │   │   ├── words_factory.gleam         # Factory (colocated)
│   │   │   └── indexes/                    # Indexes colocated with table
│   │   │       ├── idx_words_lexeme_id.sql
│   │   │       └── idx_words_form.sql
│   │   │
│   │   ├── translations/                   # Business domain: translations
│   │   │   ├── translations.sql            # Table
│   │   │   ├── translations_factory.gleam  # Factory (colocated)
│   │   │   └── indexes/                    # Indexes colocated with table
│   │   │       ├── idx_translations_word_id.sql
│   │   │       └── idx_translations_user_id.sql
│   │   │
│   │   ├── word_statistics/                # Business domain: materialized view
│   │   │   ├── word_statistics.sql         # Materialized view
│   │   │   ├── word_statistics_factory.gleam # Factory (colocated)
│   │   │   └── indexes/                    # Indexes on materialized view
│   │   │       └── idx_word_statistics_count.sql
│   │   │
│   │   ├── get_target_lexemes/             # View (no indexes needed)
│   │   │   ├── get_target_lexemes.sql
│   │   │   └── get_target_lexemes_factory.gleam
│   │   │
│   │   ├── get_user_progress/              # View (no indexes needed)
│   │   │   ├── get_user_progress.sql
│   │   │   └── get_user_progress_factory.gleam
│   │   │
│   │   └── functions/                      # Shared functions (cross-domain)
│   │       ├── update_timestamp.sql
│   │       └── calculate_lexeme_score.sql
│   │
│   └── connection.gleam                    ← Connection engine
│
└── test/                                   ← Database integration tests
    └── migration_test.gleam
```

**Organization Principles:**

1. **By Business Domain**: Schema objects are grouped by domain (e.g., `lexemes/`, `words/`, `translations/`)
2. **Colocated Indexes**: Indexes live in `indexes/` subdirectory within their table/materialized view's domain
3. **Colocated Factories**: Factories are colocated with their schema in the same directory
4. **Views Without Indexes**: Views don't have indexes, so they only contain `.sql` and `_factory.gleam`
5. **Shared Functions**: Functions that cross multiple domains live in `functions/`

See [Database Schema Updates](./database-schema-updates.md) for detailed workflow.

---

## Naming Conventions

### Query-able Structures

**ALL** query-able structures **MUST** be written in `snake_case`.

### Tables & Materialized Views

**ALL** tables & materialized_views **MUST** be written as **plural nouns**.

| Type               | Convention   | Examples                                             |
| ------------------ | ------------ | ---------------------------------------------------- |
| Tables             | plural nouns | `lexemes`, `words`, `translations`, `study_sessions` |
| Materialized Views | plural nouns | `cached_lexemes`, `word_statistics`                  |

### Views & Functions

**ALL** views & functions **MUST** be written as **actions** (verbs).

| Type      | Convention | Examples                                                                  |
| --------- | ---------- | ------------------------------------------------------------------------- |
| Views     | actions    | `get_generated_contexts`, `get_target_lexemes`, `calculate_user_progress` |
| Functions | actions    | `update_lexeme_score`, `get_next_words_to_study`                          |

### Examples

```sql
-- Table: plural noun
CREATE TABLE lexemes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lemma VARCHAR(255) NOT NULL
);

-- Materialized view: plural noun
CREATE MATERIALIZED VIEW word_statistics AS
SELECT
  word_id,
  COUNT(*) as usage_count
FROM translations
GROUP BY word_id;

-- View: action
CREATE VIEW get_target_lexemes AS
SELECT * FROM lexemes
WHERE score < 0.9;

-- Function: action
CREATE OR REPLACE
  FUNCTION
    update_lexeme_score(
      p_lexeme_id UUID,
      p_score FLOAT
    )
  RETURNS VOID AS $$
BEGIN
    UPDATE lexemes SET score = p_score WHERE id = p_lexeme_id;
END;

$$ LANGUAGE plpgsql;
```

---

## Factories & Seeders

### Requirements

- **ALL** query-able structures (e.g., tables, views, materialized views) **MUST** have a factory to generate test data.
- **ALL** factories **MUST** be **colocated** with their schema.
- **ALL** factories **MUST** generate relevant data using [blah](https://github.com/massivefermion/blah).

### Factory Colocation Rule

**Factories MUST be colocated with their schema.** The factory file lives in the same directory as the SQL schema file it generates data for.

**Bad - schema by itself:**

```
schema/lexemes.sql
```

**Good - schema has a factory:**

```
schema/
└── lexemes/
    ├── lexemes.sql              ← schema definition
    └── lexemes_factory.gleam    ← factory generated from schema
```

### Factory Workflow

```
schema ← written in "modular schema files" (e.g., some_table.sql, some_view.sql, or some_materialized_view.sql)
  ↓
squirrel ← converts the "modular schema file" to a gleam type (e.g., some_table.gleam, some_view.gleam, or some_materialized_view.gleam)
  ↓
factory ← use "blah" types to generate relevant fake data from a squirrel generated gleam type
  ↓
tests ← use factory to seed the data before testing
```

### Factory Generation/Update Workflow

```
schema ← Make changes to the Database Schema
  ↓
pgschema ← Run the `pgschema` command
  ↓
plan ← pgschema generates a change plan
  ↓
review ← review the generated change plan
  ↓
apply ← apply the change plan
  ↓
create factory ← use `squirrel` & `blah` to generate a relevant factory from the updated schema
```

### Factory File Structure

Factories are **colocated** with their corresponding schema files within business domain directories:

```
packages/proxima_lexeme_db/src/schema/
├── main.sql
├── lexemes/                          ← Business domain
│   ├── lexemes.sql                   ← table schema
│   ├── lexemes_factory.gleam         ← factory (colocated)
│   └── indexes/
│       └── idx_lexemes_lemma.sql     ← index (colocated)
├── words/                            ← Business domain
│   ├── words.sql                     ← table schema
│   ├── words_factory.gleam           ← factory (colocated)
│   └── indexes/
│       └── idx_words_lexeme_id.sql   ← index (colocated)
└── get_target_lexemes/               ← View (no indexes)
    ├── get_target_lexemes.sql
    └── get_target_lexemes_factory.gleam
```

**Naming:** Factory files follow the pattern `{schema_name}_factory.gleam` in snake_case.

---

## Queries

### Requirements

- **ALL** queries **MUST** be written in `.sql` files.
- **ALL** queries will be converted to gleam functions & types with [squirrel](https://github.com/giacomocavalieri/squirrel).
- **ALL** schemas directly inherit their types from the Database, & queries **NEVER** use the schema managed by pgschema.

### Query File Structure

**Global (within proxima_lexeme_db):**

```
/packages/proxima_lexeme_db/src/queries/{query_name}/
├── {query_name}.sql      ← query input
└── {query_name}.gleam    ← compiled query output (auto-generated)
```

**Local (colocated with usage):**

```
**/queries/{query_name}/
├── {query_name}.sql
└── {query_name}.gleam
```

### Query Naming

Queries should be named as actions in snake_case:

```
get_user_progress.sql
update_lexeme_score.sql
calculate_study_stats.sql
```

### Example Query

```sql
-- src/queries/get_target_lexemes/get_target_lexemes.sql
-- Get lexemes currently being studied (score < 0.9)
-- Returns: lexeme id, lemma, current score
SELECT
  lexeme.id,
  lexeme.lemma,
  lexeme.score
FROM lexemes l
WHERE lexeme.score < 0.9
ORDER BY lexeme.score ASC
LIMIT $1;
```

After running `gleam run -m squirrel`, this generates:

```gleam
// src/queries/get_target_lexemes/get_target_lexemes.gleam (auto-generated)
pub fn get_target_lexemes(limit: Int) -> List(TargetLexeme) {
  // ...
}

pub type TargetLexeme {
  TargetLexeme(id: String, lemma: String, score: Float)
}
```

---

## Database Schema & Type Flow

```
┌──────────────────────────────────────────────────────────────────────────┐
│                        DATABASE SCHEMA FLOW                              │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  packages/proxima_lexeme_db/src/schema/ - Organized by Business Domain   │
│  ├── lexemes/                          ← Business domain                 │
│  │   ├── lexemes.sql                   ← table schema                    │
│  │   ├── lexemes_factory.gleam         ← colocated factory               │
│  │   └── indexes/                      ← colocated indexes               │
│  │       └── idx_lexemes_lemma.sql                                       │
│  ├── words/                            ← Business domain                 │
│  │   ├── words.sql                                                       │
│  │   ├── words_factory.gleam           ← colocated factory               │
│  │   └── indexes/                      ← colocated indexes               │
│  │       └── idx_words_lexeme_id.sql                                     │
│  └── get_target_lexemes/               ← View (no indexes)               │
│      ├── get_target_lexemes.sql                                          │
│      └── get_target_lexemes_factory.gleam                                │
│         ↓                                                                │
│  pgschema apply → PostgreSQL Database                                    │
│         ↓                                                                │
│  squirrel → Gleam Types (packages/proxima_lexeme_db/src/**/queries/**/)  │
│         ↓                                                                │
│  blah → Factory Functions (colocated with schema by domain)              │
│         ↓                                                                │
│  Tests use factories to seed mocked database                             │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

**Important**:

- Schema is organized by **business domain** (e.g., `lexemes/`, `words/`)
- **Indexes are colocated** with their tables/materialized views in `indexes/` subdirectory
- **Factories are colocated** with their schema files in the same domain directory
- Types always flow from the database outward. The database schema is the source of truth.
- Never manually define types that duplicate database structures.

---

## Summary

| Aspect             | Convention                                                        |
| ------------------ | ----------------------------------------------------------------- |
| Schema files       | `.sql` only, managed by pgschema                                  |
| Organization       | By **business domain** (e.g., `lexemes/`, `words/`)               |
| Tables             | plural nouns, snake_case                                          |
| Views              | actions (verbs), snake_case                                       |
| Functions          | actions (verbs), snake_case                                       |
| Materialized Views | plural nouns, snake_case                                          |
| Indexes            | Colocated with table/materialized view in `indexes/` subdirectory |
| Queries            | `.sql` files, actions in snake_case                               |
| Factories          | Required for all query-able structures, colocated with schema     |
| Fake Data          | Generated using blah library                                      |
