---
name: update-flutter-dependencies
description: Safely upgrade Flutter SDK and Dart/Flutter dependencies with deterministic checks and rollback options.
---

# Update Flutter Dependencies

Use this skill for SDK and package upgrades that must stay stable and reviewable.

## Workflow

1. Capture baseline:
   - `flutter --version`
   - `flutter doctor -v`
   - `flutter pub get`
   - baseline checks (`flutter analyze` + impacted tests)
2. If Flutter SDK upgrade is in scope, upgrade Flutter SDK:
   - `flutter upgrade`
   - record updated `flutter --version`
   - otherwise, keep the current SDK pinned and continue with package updates only
3. Inspect package surface:
   - `flutter pub outdated`
   - identify major updates and likely breaking packages
4. Upgrade in small batches:
   - prefer targeted updates before full upgrade
   - after each batch: `flutter pub get`, `flutter analyze`, impacted tests
5. Fix breaking changes:
   - address compile and analyzer issues first
   - update tests to reflect intended behavior changes
6. Finalize:
   - summarize version deltas
   - list breaking changes handled
   - provide rollback plan

## Guardrails

- Do not mix unrelated refactors.
- Keep every step in a buildable state where possible.
- If failures cascade, split into two PRs:
  - Flutter SDK upgrade
  - package upgrade and fixes
- Always include before/after version snapshot and explicit rollback trigger.

## Required output

1. Before/after Flutter version.
2. Key dependency changes.
3. Validation commands run and their result.
4. Files changed for compatibility fixes.
5. Rollback instructions.
6. Known remaining risks after upgrade.
