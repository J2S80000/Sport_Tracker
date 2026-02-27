---
name: update-flutter-dependencies
description: Upgrade Flutter SDK and Dart/Flutter dependencies safely with analysis, tests, and rollback guidance.
---

Run a controlled dependency upgrade.

1. Follow `../skills/update-flutter-dependencies/SKILL.md`.
2. Keep changes incremental and reviewable.
3. Run `flutter analyze` and impacted tests before finalizing.
4. Document version deltas, breaking changes, and rollback plan.
5. Always include this baseline in validation: `flutter --version` (before/after), `flutter pub outdated`, `flutter analyze`, and impacted `flutter test`.

