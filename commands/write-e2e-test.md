---
name: write-e2e-test
description: Create or update a Patrol E2E test for a critical user flow.
---

Create or update a Patrol E2E test.

1. Follow `../skills/write-flutter-tests/integration-tests.md`.
2. Enforce `../rules/flutter-test-best-practices.mdc`.
3. Start from `../templates/integration_test_template.dart`.
4. Use page objects from `patrol_test/page_objects/` for interactions.
5. Use selector priority: keys first, semantics second, text fallback.
6. Keep one main path per test; avoid branching in test body.
7. Keep credentials in `--dart-define` / `.patrol.env` (no hardcoded secrets).
8. Run affected Patrol tests and fix failures.

