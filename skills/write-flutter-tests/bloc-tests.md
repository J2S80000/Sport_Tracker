# Bloc/Cubit Tests

Use for `bloc_test` and cubit state-flow tests.

## Steps

1. Follow existing test style in nearby files.
2. Reuse shared setup helpers if the repo provides them.
3. Register remaining SUT-specific mocks and SUT.
4. Use `bloc_test` with explicit `build`, `act`, `expect`, and `verify` when relevant.
5. Keep `act` focused on triggering behavior only; do not add `Future.delayed(...)` inside `act`.
6. For debounce/timers/async emissions, use `wait:` in `blocTest` instead of sleeping in `act`.
7. Use `seed:` only when the scenario requires non-default initial state.
8. Use `skip:` only for intentional intermediate states that are not part of the assertion.
9. Use `verify:` for side effects/interactions (repo, tracking, navigation), not as empty placeholder.
10. Build domain models through project builders/factories where possible.
11. Close cubit and reset DI in `tearDown`.

## Required References

- `../../rules/flutter-test-best-practices.mdc`
- `../../templates/bloc_test_template.dart`
