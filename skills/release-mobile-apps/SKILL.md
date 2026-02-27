---
name: release-mobile-apps
description: Prepare Flutter applications for Android and iOS production publication using official Flutter, Android, and Apple release guidance.
---

# Release Mobile Apps

Use this skill for Android/iOS store publishing preparation.

## Workflow

1. Verify release scope, target version, and rollout plan.
2. Run quality gates:
   - `flutter analyze`
   - test suite relevant to release scope
   - smoke tests on release candidates
3. Android path:
   - validate signing setup and app versioning
   - build release artifact (`flutter build appbundle`)
   - verify Play Console metadata readiness
4. iOS path:
   - validate signing/capabilities and versioning
   - build release artifact (`flutter build ipa` or archive flow)
   - verify App Store Connect metadata readiness
5. Confirm policy/compliance declarations (privacy, permissions, data safety as applicable).
6. Create release notes and rollout strategy.
7. Submit and monitor post-release health metrics.
8. If CI pipeline is missing, create it with `commands/setup-mobile-github-pipeline.md` and `templates/github_actions_flutter_mobile_ci.yml`.

## Guardrails

- Do not mark release ready without artifact build evidence.
- Keep Android/iOS signing and versioning checks explicit.
- Flag missing compliance metadata as blockers, not warnings.
- When evidence is missing, return `BLOCKED` instead of speculative readiness.

## Required output

1. Android readiness status (+ artifact path if built).
2. iOS readiness status (+ artifact/archive status).
3. Validation commands run and outcomes.
4. Blocking gaps before submission.
5. Immediate next actions to unblock release.

## Required references

- `../../docs/mobile-app-publishing-checklist.md`
- `../../docs/mobile-ci-pipeline-checklist.md`
- `../../rules/flutter-development-best-practices.mdc`
- `../../rules/dart-effective-dart.mdc`
