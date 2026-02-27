---
name: build-flutter-features
description: Build and refactor Flutter features with layered architecture, robust state management, Dart MCP analysis, and optional Figma MCP UI implementation.
---

# Build Flutter Features

Use this skill for non-test Flutter development tasks.

## Workflow

1. Understand the target behavior and constraints.
2. Map changes by layer: presentation -> domain -> data.
3. Keep dependency flow one-directional and injectable.
4. Implement feature changes in small increments.
5. Use Dart MCP to validate diagnostics and apply safe fixes.
6. If Figma source exists, follow `figma-to-flutter.md`.
7. Add/update tests using `../write-flutter-tests/SKILL.md`.

## Architecture defaults

- Keep widgets focused on rendering and interaction.
- Choose state management based on existing project conventions first.
- If the project already uses Riverpod/Bloc/Cubit/GetX, stay consistent with that choice.
- If no convention exists, choose the simplest viable option and document why.
- Keep business logic in dedicated controllers/cubit/bloc/use-cases/services (not widgets).
- Avoid hidden global state/singletons when DI can be used.
- Keep models immutable where practical.

## Scope guardrails

- Restrict changes to the requested feature/module unless explicitly expanded.
- Do not mix unrelated refactors with feature delivery.
- Do not claim implementation is complete unless concrete file changes or command outputs are provided.

## Required output

1. Goal + scope summary.
2. Files changed by layer (presentation/domain/data).
3. Validation commands run and results.
4. Residual risks or follow-up TODOs.
5. Missing inputs/assumptions (if context is incomplete).

## Required references

- `../../rules/flutter-development-best-practices.mdc`
- `../../rules/dart-effective-dart.mdc`
- `../../rules/flutter-test-best-practices.mdc`
