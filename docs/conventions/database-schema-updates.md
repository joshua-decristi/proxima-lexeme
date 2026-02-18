# Database Schema Updates

Conventions for updating the PostgreSQL database schema using pgschema after initial setup.

See [Database Conventions](./database.md) for general database naming conventions and factory requirements.

---

## Overview

We use **pgschema** for declarative schema management with a Terraform-style workflow:

| Phase      | Command         | Purpose                          |
| ---------- | --------------- | -------------------------------- |
| **Plan**   | `make db-plan`  | Preview changes before applying  |
| **Review** | Read `plan.txt` | Verify correctness and safety    |
| **Apply**  | `make db-apply` | Execute changes to database      |
| **Sync**   | `make db-dump`  | Pull current state from database |

---

## Schema File Structure

All schema files live in `src/schema/` organized by **business domain** and define the **desired state** of the database:

```
src/schema/
├── main.sql                          # Entry point with \i directives
│
├── lexemes/                          # Business domain: lexemes
│   ├── lexemes.sql                   # Table
│   ├── lexemes_factory.gleam         # Factory (colocated)
│   └── indexes/                      # Indexes colocated with table
│       ├── idx_lexemes_lemma.sql
│       └── idx_lexemes_score.sql
│
├── words/                            # Business domain: words
│   ├── words.sql                     # Table
│   ├── words_factory.gleam           # Factory (colocated)
│   └── indexes/                      # Indexes colocated with table
│       ├── idx_words_lexeme_id.sql
│       └── idx_words_form.sql
│
├── translations/                     # Business domain: translations
│   ├── translations.sql              # Table
│   ├── translations_factory.gleam    # Factory (colocated)
│   └── indexes/                      # Indexes colocated with table
│       ├── idx_translations_word_id.sql
│       └── idx_translations_user_id.sql
│
├── word_statistics/                  # Business domain: materialized view
│   ├── word_statistics.sql           # Materialized view
│   ├── word_statistics_factory.gleam # Factory (colocated)
│   └── indexes/                      # Indexes on materialized view
│       └── idx_word_statistics_count.sql
│
├── get_target_lexemes/               # View (no indexes)
│   ├── get_target_lexemes.sql
│   └── get_target_lexemes_factory.gleam
│
└── functions/                        # Shared functions (cross-domain)
    ├── update_timestamp.sql
    └── calculate_lexeme_score.sql
```

**Organization Principles:**

1. **By Business Domain**: Schema objects are grouped by domain (e.g., `lexemes/`, `words/`, `translations/`)
2. **Colocated Indexes**: Indexes live in `indexes/` subdirectory within their table/materialized view's domain
3. **Colocated Factories**: Factories are colocated with their schema in the same directory
4. **Views Without Indexes**: Views don't have indexes, so they only contain `.sql` and `_factory.gleam`
5. **Shared Functions**: Functions that cross multiple domains live in `functions/`

### Naming Conventions

| Object Type        | Convention                       | Examples                                       |
| ------------------ | -------------------------------- | ---------------------------------------------- |
| Tables             | plural nouns, snake_case         | `lexemes`, `words`, `study_sessions`           |
| Views              | actions (verbs), snake_case      | `get_target_lexemes`, `calculate_progress`     |
| Functions          | actions (verbs), snake_case      | `update_score`, `get_next_words`               |
| Materialized Views | plural nouns, snake_case         | `cached_lexemes`, `word_statistics`            |
| Indexes            | snake*case, prefixed with `idx*` | `idx_lexemes_lemma`, `idx_words_lexeme_id`     |
| Factories          | colocated with schema            | `lexemes_factory.gleam`, `words_factory.gleam` |

**main.sql** (entry point):

```sql
-- Include all schema objects using \i directives
-- Organized by business domain

-- Lexemes domain
\i lexemes/lexemes.sql
\i lexemes/indexes/idx_lexemes_lemma.sql
\i lexemes/indexes/idx_lexemes_score.sql

-- Words domain
\i words/words.sql
\i words/indexes/idx_words_lexeme_id.sql
\i words/indexes/idx_words_form.sql

-- Translations domain
\i translations/translations.sql
\i translations/indexes/idx_translations_word_id.sql
\i translations/indexes/idx_translations_user_id.sql

-- Materialized views
\i word_statistics/word_statistics.sql
\i word_statistics/indexes/idx_word_statistics_count.sql

-- Views
\i get_target_lexemes/get_target_lexemes.sql
\i get_user_progress/get_user_progress.sql

-- Functions (cross-domain)
\i functions/update_timestamp.sql
\i functions/calculate_lexeme_score.sql
```

**Note on Organization**: Schema is organized by **business domain**. Each domain directory contains:

1. The table/materialized view SQL file
2. The colocated factory (e.g., `lexemes_factory.gleam`)
3. An `indexes/` subdirectory with all indexes for that domain

---

## Update Workflow

### 1. Making Schema Changes

Edit the SQL files in `src/schema/` to represent the **desired state**:

**Example: Adding a column**

```sql
-- src/schema/tables/words.sql
CREATE TABLE words (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    form VARCHAR(255) NOT NULL,
    lexeme_id UUID REFERENCES lexemes(id),
    frequency INTEGER,  -- NEW COLUMN
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 2. Generate Migration Plan

Always generate a plan to preview changes before applying:

```bash
# Generate plan (outputs plan.txt and plan.json)
make db-plan

# Review the plan
cat plan.txt
```

**Plan Output Example**:

```
Plan: 1 to modify.

Summary by type:
  tables: 1 to modify

Tables:
  ~ words
    + frequency (column)

Transaction: true

DDL to be executed:
--------------------------------------------------
ALTER TABLE words ADD COLUMN frequency INTEGER;

Do you want to apply these changes? (yes/no):
```

### 3. Apply Changes

After reviewing the plan, apply changes to the database:

```bash
# Apply changes (interactive - requires confirmation)
make db-apply

# Or apply from pre-generated plan
make db-apply-plan
```

### 4. Regenerate Query Types

After schema changes, regenerate Squirrel query types:

```bash
# Generate type-safe Gleam functions from queries
gleam run -m squirrel

# Verify types are correct
gleam build
```

### 5. Verify and Commit

```bash
# Run tests to ensure nothing broke
make test

# Commit schema changes and generated code
# Add the business domain directory (includes schema, factory, and indexes)
git add src/schema/words/
# Add any new queries that use the new column
git add src/queries/
# Add generated Squirrel files
git add src/**/queries/**/*.gleam
git commit -m "feat(db): add frequency column to words table"
```

---

## Complete Example: Adding a New Table (Business Domain)

```bash
# Step 1: Create the business domain directory with schema, factory, and indexes
# Using plural noun, snake_case for the domain name
mkdir -p src/schema/study_sessions/indexes

# Create the table schema
cat > src/schema/study_sessions/study_sessions.sql << 'EOF'
CREATE TABLE study_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) NOT NULL,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP,
    words_studied INTEGER DEFAULT 0
);
EOF

# Create indexes colocated with the table
mkdir -p src/schema/study_sessions/indexes

cat > src/schema/study_sessions/indexes/idx_study_sessions_user_id.sql << 'EOF'
CREATE INDEX idx_study_sessions_user_id ON study_sessions(user_id);
EOF

cat > src/schema/study_sessions/indexes/idx_study_sessions_started_at.sql << 'EOF'
CREATE INDEX idx_study_sessions_started_at ON study_sessions(started_at);
EOF

# Create the colocated factory
cat > src/schema/study_sessions/study_sessions_factory.gleam << 'EOF'
import blah
import squirrel/study_sessions

pub fn create() -> study_sessions.StudySession {
  study_sessions.StudySession(
    id: blah.uuid(),
    user_id: blah.uuid(),
    started_at: blah.timestamp(),
    ended_at: blah.option(blah.timestamp()),
    words_studied: blah.int(0, 100),
  )
}

pub fn create_many(count: Int) -> List(study_sessions.StudySession) {
  blah.list(create, count)
}
EOF

# Step 2: Add to main.sql (include table and its indexes)
echo "\i study_sessions/study_sessions.sql" >> src/schema/main.sql
echo "\i study_sessions/indexes/idx_study_sessions_user_id.sql" >> src/schema/main.sql
echo "\i study_sessions/indexes/idx_study_sessions_started_at.sql" >> src/schema/main.sql

# Step 3: Generate and review plan
make db-plan
cat plan.txt

# Step 4: Apply changes
make db-apply

# Step 5: Create query for new table (action, snake_case)
mkdir -p src/queries/get_study_session
cat > src/queries/get_study_session/get_study_session.sql << 'EOF'
-- Get a study session by ID
-- Returns: session details
SELECT
    s.id,
    s.user_id,
    s.started_at,
    s.ended_at,
    s.words_studied
FROM study_sessions s
WHERE s.id = $1;
EOF

# Step 6: Generate type-safe queries (squirrel creates study_session.gleam)
gleam run -m squirrel

# Step 7: Build and test
gleam build
make test

# Step 8: Commit
git add src/schema/study_sessions/
git add src/queries/get_study_session/
git commit -m "feat(db): add study_sessions table with queries, indexes, and factory

- Add study_sessions business domain
- Schema: study_sessions/study_sessions.sql
- Factory: study_sessions/study_sessions_factory.gleam
- Indexes: study_sessions/indexes/ (colocated)
  - idx_study_sessions_user_id.sql
  - idx_study_sessions_started_at.sql
- Add get_study_session query"
```

---

## Syncing Schema

### When to Sync

Sync (dump) the database schema when:

- Changes were made directly to the database (not through pgschema)
- You want to verify schema files match the database
- Starting work on a new feature and want fresh state

### Sync Workflow

```bash
# Dump current database state to schema files
make db-dump

# Review changes
git diff src/schema/

# Commit if changes are expected
git add src/schema/
git commit -m "chore(db): sync schema from database"
```

**Warning**: `make db-dump` overwrites schema files. Review changes carefully before committing.

### Verify Schema Sync

```bash
# Check if schema files match database
make db-verify
```

This command:

1. Dumps current database to temporary location
2. Compares with `src/schema/`
3. Reports any differences

---

## Rollback Workflow

<Warning>
Rolling back schema changes is inherently risky and may result in data loss. Always test rollback procedures in non-production environments and ensure you have complete database backups.
</Warning>

### Rollback Steps

```bash
# Step 1: Revert schema files to previous version
# Revert all files in the business domain directory
git checkout HEAD~1 src/schema/problematic_domain/

# Step 2: Generate rollback plan
make db-plan

# Step 3: Review rollback plan carefully
cat plan.txt

# Step 4: Apply rollback
make db-apply

# Step 5: Verify rollback success
make db-verify
```

---

## Safety Features

### Schema Fingerprinting

pgschema uses **fingerprinting** to detect concurrent schema changes:

1. **During Plan**: Captures a snapshot (fingerprint) of current database state
2. **During Apply**: Verifies database hasn't changed since plan was generated
3. **On Mismatch**: Aborts apply with error

**Error Example**:

```
Error: schema fingerprint mismatch detected - the database schema has
changed since the plan was generated.

Expected fingerprint: 965b1131737c955e
Current fingerprint:  abc123456789abcd

To resolve:
1. Regenerate plan: make db-plan
2. Review new plan: cat plan.txt
3. Apply again: make db-apply
```

### Transaction Safety

pgschema automatically handles transactions:

- **Transactional mode** (default): All changes run in single transaction with automatic rollback on failure
- **Non-transactional mode**: Some operations (like `CREATE INDEX CONCURRENTLY`) run outside transactions

Plan output indicates transaction mode:

```
Transaction: true   # Changes will run in transaction
Transaction: false  # Some changes cannot run in transaction
```

### Lock Timeout

Use `--lock-timeout` in production to prevent indefinite blocking:

```bash
# In Makefile or CI/CD
pgschema apply ... --lock-timeout 30s
```

---

## CI/CD Integration

### Automated Schema Checks

```yaml
# .github/workflows/schema-check.yml
name: Schema Check

on: [pull_request]

jobs:
  schema:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Generate Plan
        run: |
          make db-plan
          cat plan.txt

      - name: Check for Destructive Changes
        run: |
          if jq -e '.summary.to_destroy > 0' plan.json; then
            echo "::error::Destructive changes detected! Manual review required."
            exit 1
          fi

      - name: Upload Plan
        uses: actions/upload-artifact@v4
        with:
          name: migration-plan
          path: |
            plan.txt
            plan.json
```

### Production Deployment

```bash
# Generate plan for production
make db-plan

# Review plan thoroughly
cat plan.txt

# Commit plan for audit trail
git add plan.txt plan.json
git commit -m "chore(db): production migration plan"

# Apply with auto-approve (after review)
make db-apply-auto
```

---

## Environment Variables

Create `.env` file for pgschema (auto-loaded):

```bash
# .env
PGHOST=localhost
PGPORT=5432
PGDATABASE=proxima_lexeme
PGUSER=proxima
PGPASSWORD=proxima
```

With `.env` file, commands don't need connection flags:

```bash
# These work without --host, --db, etc.
make db-plan
make db-apply
make db-dump
```

---

## Common Patterns

### Adding an Index

Indexes are **colocated** with their table/materialized view in the business domain's `indexes/` subdirectory:

```sql
-- src/schema/words/indexes/idx_words_lexeme_id.sql
CREATE INDEX CONCURRENTLY idx_words_lexeme_id ON words(lexeme_id);
```

Note: Use `CONCURRENTLY` for production to avoid locking.

Then add to `main.sql`:

```sql
\i words/indexes/idx_words_lexeme_id.sql
```

### Adding a View

Views are organized as their own business domain (views don't have indexes):

```bash
# Create the view domain directory
mkdir -p src/schema/get_user_progress

# Create the view (action/verb name in snake_case)
cat > src/schema/get_user_progress/get_user_progress.sql << 'EOF'
CREATE VIEW get_user_progress AS
SELECT
    u.id as user_id,
    COUNT(DISTINCT l.id) as known_lexemes,
    AVG(t.score) as avg_score
FROM users u
LEFT JOIN translations t ON u.id = t.user_id
LEFT JOIN words w ON t.word_id = w.id
LEFT JOIN lexemes l ON w.lexeme_id = l.id
WHERE t.score >= 0.9
GROUP BY u.id;

COMMENT ON VIEW get_user_progress IS 'Aggregated user learning progress';
EOF

# Create the colocated factory
cat > src/schema/get_user_progress/get_user_progress_factory.gleam << 'EOF'
import blah
import squirrel/get_user_progress

pub fn create() -> get_user_progress.GetUserProgress {
  get_user_progress.GetUserProgress(
    user_id: blah.uuid(),
    known_lexemes: blah.int(0, 1000),
    avg_score: blah.float(0.0, 1.0),
  )
}
EOF
```

Then add to `main.sql`:

```sql
\i get_user_progress/get_user_progress.sql
```

### Adding a Function

Functions should be named as actions (verbs) in snake_case:

```sql
-- src/schema/functions/update_timestamp.sql
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- src/schema/functions/calculate_lexeme_score.sql
CREATE OR REPLACE FUNCTION calculate_lexeme_score(
    p_lexeme_id UUID
) RETURNS FLOAT AS $$
DECLARE
    v_score FLOAT;
BEGIN
    SELECT AVG(score) INTO v_score
    FROM word_scores
    WHERE lexeme_id = p_lexeme_id;

    RETURN COALESCE(v_score, 0.0);
END;
$$ LANGUAGE plpgsql;

-- src/schema/tables/words.sql
CREATE TABLE words (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    form VARCHAR(255) NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER update_words_timestamp
    BEFORE UPDATE ON words
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();
```

---

## Available Make Commands

```bash
# Schema management
make db-plan          # Generate migration plan
make db-apply         # Apply schema changes (interactive)
make db-apply-plan    # Apply from pre-generated plan
make db-apply-auto    # Apply with auto-approve (CI/CD)
make db-dump          # Dump database to schema files
make db-verify        # Verify schema is in sync
make db-reset         # Full reset (DANGER: drops all data)

# Query generation
make sql-generate     # Generate Squirrel functions from queries
make sql-check        # Check SQL is up-to-date (for CI)
```

---

## Important Notes

1. **Schema files are source of truth**: Always edit SQL files in `src/schema/` first, not the database directly

2. **Always plan before apply**: Never run `make db-apply` without first reviewing `plan.txt`

3. **Commit generated code**: Squirrel-generated `.gleam` files in `src/**/queries/` should be committed to git

4. **No migration table**: Unlike traditional migration tools, pgschema doesn't use a migrations table. It compares desired state (files) with current state (database) on every run.

5. **One file per object**: Each table, view, index, and function should have its own file for clarity and easier code review.

6. **Use comments**: Document your schema with SQL `COMMENT ON` statements.

7. **Test migrations locally**: Always test schema changes locally before applying to production.

8. **Coordinate team changes**: Since there's no migration table, coordinate with team members to avoid concurrent schema modifications.

---

## Troubleshooting

### No changes detected

- Ensure you're editing files in `src/schema/`
- Check that files are included in `main.sql` with `\i` directives
- Verify you're targeting the correct schema (`--schema public` is default)

### Fingerprint mismatch

Database was modified since plan was generated. Regenerate plan:

```bash
make db-plan
make db-apply
```

### Permission denied

Ensure database user has:

- `CONNECT` privilege on database
- `USAGE` privilege on schema
- `CREATE` privilege on schema (for new objects)

### Connection issues

```bash
# Test connection
pg_isready -h $PGHOST -p $PGPORT

# Verify credentials
psql "postgres://$PGUSER:$PGPASSWORD@$PGHOST:$PGPORT/$PGDATABASE"
```

---

## References

- [pgschema Documentation](https://www.pgschema.com/)
- [pgschema CLI Reference](https://www.pgschema.com/llms.txt)
- [Plan-Review-Apply Workflow](https://www.pgschema.com/workflow/plan-review-apply)
- [Modular Schema Files](https://www.pgschema.com/workflow/modular-schema-files)
- [Rollback Guide](https://www.pgschema.com/workflow/rollback)
