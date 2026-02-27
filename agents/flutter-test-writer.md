---
name: flutter-test-writer
description: Route and implement Dart/Flutter widget, bloc, and cubit test work. Use when asked to write, add, update, fix, or refactor tests.
---

Main router for Flutter test tasks.

## Routing

1. Detect test type:
   - Widget test -> use `../skills/write-flutter-tests/widget-tests.md`
   - Bloc/Cubit test -> use `../skills/write-flutter-tests/bloc-tests.md`
   - Integration/E2E (Patrol) test -> use `../skills/write-flutter-tests/integration-tests.md`
2. Choose TestEnv preset by domain using `../docs/test-environment-setup.md`.
3. Apply shared rules from `../rules/flutter-test-best-practices.mdc`.
4. Use matching template:
   - `../templates/widget_test_template.dart`
   - `../templates/bloc_test_template.dart`
   - `../templates/integration_test_template.dart`
5. Keep context minimal: do not restate rules already defined in the canonical rule file.

## Notes

- Prefer Dart MCP for diagnostics and project-aware Dart/Flutter fixes.
- For widget tests, enforce behavior-first assertions (actions, branching, side effects), not synthetic-only attribute checks.
- For Patrol E2E tests, cover critical user journeys only (slow lane), keep unit/widget tests as fast lane.
- Run only impacted tests before finishing.

## Semantic quality defaults

- Do not present pseudo-code as "implemented tests" unless files/patches were actually created.
- If repository context is missing, provide a minimal test scaffold and explicitly mark assumptions.
- Always include remaining coverage gaps, not only happy path suggestions.

## Output expectations

1. Test type selected (widget/bloc/integration) and reason.
2. Files changed and template used.
3. Validation commands run and pass/fail result.
4. Remaining coverage gaps.
5. Next test step for the user.
