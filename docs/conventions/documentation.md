# Documentation Conventions

All documentation **MUST** be written explaining **ONLY** the purpose of the function.

## Where to Write Documentation

Colocate the documentation to the file as comment blocks for **ALL** file types (gleam, sql, ts):

- **ONLY** write documentation for exported structures (functions, types, variables, etc.)
- **ONLY** write documentation for complex structures
- **NEVER** write documentation for simple or non-exported structures

---

## Gleam Documentation

Use Gleam's built-in documentation format:

````gleam
/// Calculate the weighted lexeme score based on word frequencies.
///
/// # Examples
///
/// ```gleam
/// let lexeme = Lexeme(id: "1", lemma: "run", words: [...])
/// calculate_lexeme_score(lexeme)  // -> 0.85
/// ```
///
pub fn calculate_lexeme_score(lexeme: Lexeme) -> Float {
  // Implementation
}
````

### Rules

- Use `///` for public functions and types
- Include `# Examples` section for complex functions
- Document the **purpose**, not the **implementation**
- Keep descriptions concise and clear

---

## SQL Documentation

Document SQL queries with SQL comments:

```sql
-- Get words that are currently being studied (score < 0.9)
-- Returns: word id, form, translation, current score
SELECT
    w.id,
    w.form,
    t.translation,
    t.score
FROM words w
JOIN translations t ON w.id = t.word_id
WHERE t.score < 0.9
ORDER BY t.score ASC
LIMIT $1;
```

### Rules

- Use SQL comments (`--`) at the top of the file
- Describe what the query does
- Document return values
- Note any special conditions or filters

---

## TypeScript Documentation

Use JSDoc for TypeScript code:

```typescript
/**
 * Calculate the adaptive difficulty score for a word.
 *
 * @param currentScore - The current mastery score (0.0 - 1.0)
 * @param grade - The self-assessment grade (1-5)
 * @returns The adjusted score clamped between 0.0 and 1.0
 */
function calculateScore(currentScore: number, grade: number): number {
  // Implementation
}
```

### Rules

- Use JSDoc (`/** */`) for exported functions
- Include `@param` for each parameter
- Include `@returns` for return value description
- Document the **purpose**, not the **implementation**

---

## Complex Documentation

Complex documentation must be colocated to relevant files. See [Code Types - Documentation](./code-types.md#documentation) for more information.

Complex documentation can be:

- Business logic workflow order
- Complex SQL query explanation
- Metric calculation explanation
- Architecture decision records

### Example: Business Logic Documentation

Location: `src/business_logic/context_generation/docs/workflow.md`

```markdown
# Context Generation Workflow

## Overview

The context generation workflow is responsible for generating study sentences.

## Steps

1. **Select Words**: Choose 3-7 target words from studying set
2. **Select Anchors**: Choose anchor words for scaffolding
3. **Generate Prompt**: Build LLM prompt with constraints
4. **Call LLM**: Send to OpenRouter for generation
5. **Validate**: Ensure all target words appear
6. **Store**: Save context for study session

## Anti-Drowning Protection

The workflow enforces the 25-lexeme limit before selecting new words.
```

---

## Global Documentation

Global documentation must live in the `/docs` directory so it's accessible by:

- The whole repository
- GitHub (for project documentation)

### Structure

```
/docs/
  ├── README.md                    ← Project overview
  ├── architecture/                ← Architecture docs
  │   ├── overview.md
  │   └── decisions/               ← ADRs
  ├── api/                         ← API documentation
  └── conventions/                 ← This directory
```

### Rules

- High-level documentation in `/docs/`
- Keep conventions in `/docs/conventions/`
- Architecture decisions in `/docs/architecture/decisions/`
- API documentation in `/docs/api/`
