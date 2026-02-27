---
name: write-flutter-tests
description: Write and extend Dart/Flutter unit (bloc/cubit), widget, and Patrol E2E tests using bloc_test, mocktail, page objects, and project templates. Use when asked to write, add, update, fix, or refactor Flutter tests or test setup.
---

# Write Flutter Tests

Use this skill as the single entry point for Flutter test work.

## Workflow

1. Detect scope: widget test vs bloc/cubit test vs Patrol E2E test.
2. If the repo has shared test setup helpers (for example `TestEnv`, `pumpApp`), reuse them.
3. Load only the needed guide:
   - Widget: `widget-tests.md`
   - Bloc/Cubit: `bloc-tests.md`
   - Integration/E2E (Patrol): `integration-tests.md`
4. Apply shared constraints from `../../rules/flutter-test-best-practices.mdc`.
5. Start from the matching template:
   - `../../templates/widget_test_template.dart`
   - `../../templates/bloc_test_template.dart`
   - `../../templates/integration_test_template.dart`
6. Run only impacted tests and fix failures.
7. Prefer behavior-first assertions:
   - user action -> observable outcome,
   - expected branch visible + conflicting branch hidden,
   - avoid synthetic-only style assertions unless style is the requirement.

## Description Format

- Event tests: `WHEN user taps <control> THEN <result>`
- State tests: `GIVEN <state> THEN <rendered result>`
- Never write: `WHEN widget is pumped` / `WHEN page is built`

## Progressive Disclosure

- Keep this file short.
- Put implementation detail in:
  - `widget-tests.md`
  - `bloc-tests.md`
  - `integration-tests.md`
  - `../../docs/test-environment-setup.md`

## Guardrails

- Prefer deterministic tests over time-dependent assertions.
- Keep test setup local unless shared helpers already exist.
- Avoid broad snapshot/golden assertions unless explicitly requested.
- Do not present sample test snippets as completed repository changes without file-level confirmation.

## Required output

1. Test type selected and why.
2. Files created/updated.
3. Test commands run and results.
4. Flakiness risks or missing coverage notes.
5. Next test to add (single highest-value gap).
