# Widget Tests

Use for `testWidgets` tasks.

## Steps

1. Reuse existing test file style when present.
2. If the repo has shared setup (`TestEnv`, `pumpApp`), use it before custom stubs.
3. Register and stub only widget-specific dependencies.
4. Build test data through existing builders/factories in the project.
5. Prefer localization-aware assertions when the app is localized.
6. Prefer real behavior checks:
   - after user action, assert observable outcome (callback/navigation/dialog/cubit call),
   - for conditional UI, assert shown branch + hidden conflicting branch,
   - avoid tests that only assert icon size/color/margin unless style is the product requirement.
7. If async behavior exists, use `pumpAndSettle()` (or explicit pump sequence) before final assertions.

## Description Style

- Event tests: `WHEN user taps <control> THEN <result>`
- State tests: `GIVEN <state> THEN <rendered result>`
- Do not use `WHEN widget is pumped` or `WHEN page is built`.

## Required References

- `../../rules/flutter-test-best-practices.mdc`
- `../../docs/test-environment-setup.md`
- `../../templates/widget_test_template.dart`
