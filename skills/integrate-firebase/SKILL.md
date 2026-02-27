---
name: integrate-firebase
description: Integrate Firebase into Flutter apps using FlutterFire CLI and production-safe setup patterns across Android and iOS.
---

# Integrate Firebase

Use this skill for end-to-end Firebase integration in Flutter apps.

## Workflow

1. Confirm Firebase services required for the project:
   - Authentication
   - Analytics
   - Crashlytics
   - Cloud Messaging
   - Remote Config
2. Set up project with FlutterFire CLI and generate `firebase_options.dart`.
3. Initialize Firebase in app bootstrap and environment-aware startup.
4. Add required platform configuration for Android and iOS.
5. Integrate services incrementally and verify each one.
6. Add minimal smoke tests and runtime verification points.
7. Confirm release-readiness and observability setup.

## Guardrails

- Avoid hardcoding secrets.
- Keep service wrappers injectable and testable.
- Add error handling and fallback behavior for remote dependencies.
- Validate behavior in both debug and release-capable builds.
- Do not claim Android/iOS integration is complete without naming changed config files.
- In simulation/planning mode, never use `integrated/completed`; use `planned/not executed`.

## Required output

1. Enabled Firebase services and where they are wired.
2. Android/iOS configuration files changed.
3. Validation commands run and runtime checks performed.
4. Known gaps or follow-up production steps.

## Required references

- `../../docs/firebase-integration-checklist.md`
- `../../rules/flutter-development-best-practices.mdc`
- `../../rules/dart-effective-dart.mdc`
