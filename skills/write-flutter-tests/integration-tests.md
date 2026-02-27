# Integration / E2E Tests

Use for Patrol-based E2E tasks (`patrol_test`) and critical user journey coverage.

## Steps

1. Use Patrol (`patrolTest`) as the default E2E framework when the repository uses Patrol.
2. Place tests under `patrol_test/` and follow existing structure.
3. Cover only critical cross-screen flows for the app, e.g.:
   - login/authentication + initial landing
   - onboarding
   - checkout/purchase or subscription flow (if applicable)
   - primary feature flow (core user value path)
   - settings/profile/support essentials
4. Keep E2E tests focused on user outcomes, not implementation details.
5. Use page objects for cross-screen UI interactions:
   - add/update classes in `patrol_test/page_objects/`
   - keep selectors + actions in page objects, not test body
   - test files should orchestrate flow only
6. Use stable selectors:
   - prefer `ValueKey(...)` / `Key(...)` first
   - use semantics labels when keys are not available
   - avoid class-based and text-based selectors as primary strategy
7. Keep test setup isolated and deterministic:
   - fresh app state per test,
   - avoid shared mutable state across tests.
8. Drive interactions through user actions (`tap`, `enterText`, scroll, navigation).
9. For async UI transitions, use Patrol wait APIs (`waitUntilVisible`, etc.) and explicit settling steps judiciously.
10. Avoid over-assertion: validate visible/behavioral outcomes that matter.
11. Keep E2E suite small; prefer unit/widget tests for broad coverage and speed.
12. Keep one main path per test; avoid branching (`if`) in test bodies where possible.
13. Use descriptive Patrol test names explaining the user outcome and purpose.
14. Do not hardcode credentials/secrets in tests:
   - use `const String.fromEnvironment(...)`
   - pass values via `--dart-define` or `.patrol.env`.

## Patrol Troubleshooting Notes

- If native selectors are unclear, inspect native hierarchy:
  - Android: `adb shell uiautomator dump` then `adb pull /sdcard/window_dump.xml .`
  - iOS: `idb ui describe-all`
- For permission requests before app pump:
  1. start permission request without awaiting,
  2. grant via Patrol platform API,
  3. await the pending permission future.

## Required References

- `../../rules/flutter-test-best-practices.mdc`
- `../../templates/integration_test_template.dart`
