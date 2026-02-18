# Testing Conventions

## Core Principle: Test-Driven Development (TDD)

**ALL** code **MUST** be written using test-driven-development (TDD).

**ALWAYS** write test cases **BEFORE** writing any production code.

---

## Testing Framework

We use **[glacier](https://hexdocs.pm/glacier/)** instead of `gleeunit`. This allows running:

1. **All tests at once** - via `gleam test`
2. **Individual test modules** - via `gleam run -m glacier_gleeunit <module_name>`
3. **Multiple specific test modules** - via `gleam run -m glacier_gleeunit <module1> <module2>`

---

## Database Testing

**ALL** tests involving the Database **MUST** use a mocked Database with a Factory to seed the database.

```gleam
// Example test using factory
import glacier
import glacier/should
import factories/lexeme_factory

pub fn get_target_lexemes_test() {
  // Arrange: Seed database with factory
  let mock_lexemes = lexeme_factory.create_many(5)

  // Act: Run the query
  let result = queries/get_target_lexemes/get_target_lexemes.get_target_lexemes(10)

  // Assert: Verify results
  result |> should.equal(mock_lexemes)
}
```

---

## Frontend Testing

**NEVER** test frontend code.

**ONLY** test:

- Service code
- Business logic

The frontend uses Data-Star with declarative HTML attributes, and the backend is the source of truth. Testing should focus on:

1. Backend route handlers
2. Business logic workflows
3. Database queries
4. Utility functions

---

## Common Tests

### Route Tests

**ALL** routes return html with 200's & 300's status codes.

**NEVER** use 400's or 500's status codes for human-facing UIs.

```gleam
// GOOD: Return 200 with error UI
pub fn handle_error() {
  let html = error_message.render("Invalid input")
  wisp.html_response(html, 200)
}

// BAD: Return 500 to humans
pub fn handle_error_bad() {
  wisp.internal_server_error()
}
```

### Edge Case Handling

**ALWAYS** handle edge-cases in tests.

```gleam
pub fn calculate_score_edge_cases_test() {
  // Empty input
  calculate_score([]) |> should.equal(0.0)

  // Single item
  calculate_score([1.0]) |> should.equal(1.0)

  // Maximum values
  calculate_score([1.0, 1.0, 1.0]) |> should.equal(1.0)

  // Negative scores (should be clamped)
  calculate_score([-0.5]) |> should.equal(0.0)
}
```

---

## Unit Tests

Tests are reserved for complex logic (e.g., workflows, routes, jobs, etc).

### Rule

**If the function is complex → test**

**NEVER** test simple logic:

```gleam
// NEVER test this - it's simple arithmetic
fn sum(x: Int, y: Int) -> Int {
  x + y
}

// Test this - it has business logic
fn calculate_lexeme_score(lexeme: Lexeme) -> Float {
  // Complex weighted calculation based on word frequencies
  // and mastery scores across all word forms
}
```

### What to Test

| Test Type             | When to Use              | Example                                    |
| --------------------- | ------------------------ | ------------------------------------------ |
| **Route Tests**       | All route handlers       | Testing that `/study` returns correct HTML |
| **Workflow Tests**    | Business logic workflows | Testing context generation workflow        |
| **Query Tests**       | Complex SQL queries      | Testing that query returns correct data    |
| **Utility Tests**     | Complex helper functions | Testing score calculation logic            |
| **Integration Tests** | Multi-component flows    | Testing full study session flow            |

### What NOT to Test

| Don't Test          | Reason                          |
| ------------------- | ------------------------------- |
| Simple arithmetic   | Trivial logic                   |
| Data accessors      | Just returning a field          |
| Simple conditionals | One-line if statements          |
| Frontend code       | Use Data-Star, test backend     |
| Generated code      | Squirrel output, factory output |

---

## Test File Structure

**Global Tests (Integration/End-to-End):**

Following Gleam's conventions, global tests are located at the package/app level:

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
│   └── test/                              ← integration/end-to-end tests for the package
│       └── attribute_test.gleam
└── proxima_lexeme_db/
    └── test/                              ← integration/end-to-end tests for the package
        └── migration_test.gleam
```

**Purpose:** These tests are for **integration/end-to-end tests** that span multiple modules or test the package/app as a whole. They are **NOT** for testing any specific sub-domain of the package/app.

**Colocated Tests (Unit Tests):**

For testing specific modules or sub-domains, place tests close to the code they test:

```
apps/
└── proxima_lexeme/
    └── src/
        └── routes/
            └── study_session/
                ├── handler.gleam
                └── tests/
                    └── handler_test.gleam

packages/
└── business_logic/
    └── src/
        └── context_generation/
            ├── index.gleam
            └── tests/
                └── index_test.gleam
```

---

## Test Naming

Test functions should describe what they're testing:

```gleam
// Good names
calculate_lexeme_score_with_empty_words_test()
get_target_lexemes_returns_only_studying_test()
handle_grade_updates_score_correctly_test()

// Bad names
test1()
test_calculate()
my_test()
```

---

## Test Organization

```gleam
// apps/proxima_lexeme/test/lexeme_workflow_test.gleam
// OR for colocated: apps/proxima_lexeme/src/routes/study_session/tests/handler_test.gleam
import glacier
import glacier/should
import factories/lexeme_factory
import factories/word_factory

// Group related tests
pub fn lexeme_scoring_tests() {
  glacier.describe("lexeme scoring", [
    calculate_empty_lexeme_score_test,
    calculate_partial_mastery_score_test,
    calculate_full_mastery_score_test,
  ])
}

pub fn calculate_empty_lexeme_score_test() {
  let lexeme = lexeme_factory.create_empty()
  lexeme.calculate_score() |> should.equal(0.0)
}

pub fn calculate_partial_mastery_score_test() {
  let lexeme = lexeme_factory.with_score(0.75)
  lexeme.calculate_score() |> should.equal(0.75)
}

pub fn calculate_full_mastery_score_test() {
  let lexeme = lexeme_factory.with_score(1.0)
  lexeme.calculate_score() |> should.equal(1.0)
}
```

---

## Running Tests

### Run All Tests

```bash
# Run all tests at once
gleam test
```

### Run Individual Test Modules

With `glacier`, you can run specific test modules:

```bash
# Run a single test module (global test)
gleam run -m glacier apps/proxima_lexeme/test/lexeme_workflow_test

# Run a single test module (colocated test)
gleam run -m glacier apps/proxima_lexeme/src/routes/study_session/tests/handler_test

# Run multiple specific test modules
gleam run -m glacier apps/proxima_lexeme/test/lexeme_workflow_test apps/proxima_lexeme/test/context_generation_test

# Run all tests in a directory (via pattern)
gleam run -m glacier apps/proxima_lexeme/test/routes_*
```

### Key Benefits

- **Fast iteration** - Run only the tests you're working on
- **Focused debugging** - Isolate failing tests quickly
- **CI/CD compatible** - Full test suite runs with `gleam test`

---

## Summary

| Rule           | Description                        |
| -------------- | ---------------------------------- |
| TDD            | Write tests BEFORE production code |
| Framework      | Use `glacier` (not `gleeunit`)     |
| Run Individual | `gleam run -m glacier <module>`    |
| Run All        | `gleam test`                       |
| Database       | Always mock with factories         |
| Frontend       | NEVER test frontend code           |
| Routes         | Only 200s and 300s status codes    |
| Edge Cases     | Always test edge cases             |
| Simple Logic   | NEVER test trivial functions       |
| Complex Logic  | ALWAYS test business logic         |
