---
name: debug-flutter-issues
description: Systematically diagnose Flutter failures from logs to root cause across Dart, package graph, Android, and iOS.
---

# Debug Flutter Issues

Use for compiler/build/runtime failures.

## Workflow

1. Capture exact failing command and complete logs.
2. Classify failure layer:
   - Dart analyzer/compiler
   - pub dependency resolution
   - Android Gradle/Kotlin/AGP
   - iOS CocoaPods/Xcode/signing
3. Reproduce with minimal scope.
4. Apply smallest deterministic fix.
5. Validate with rerun and impacted tests.

## Guardrails

- Do not propose a fix without a reproducible command or clear log evidence.
- Keep fixes minimal and limited to the failing layer unless a cross-layer root cause is proven.
- Call out unknowns explicitly instead of guessing when logs are incomplete.
- Include one preventive follow-up even when the fix is minimal.

## Output format

- Root cause.
- Applied fix.
- Verification steps.
- Preventive follow-up (optional).
