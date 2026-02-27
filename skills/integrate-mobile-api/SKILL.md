---
name: integrate-mobile-api
description: Integrate external REST/GraphQL APIs into Flutter apps with production-safe networking, auth, error handling, and test coverage.
---

# Integrate Mobile API

Use this skill for integrating backend APIs into Flutter applications.

## Workflow

1. Confirm API scope and constraints:
   - protocol (`REST` or `GraphQL`)
   - authentication model (JWT, OAuth, API key, session)
   - required endpoints/operations
2. Define architecture boundaries:
   - data layer for client/datasource
   - domain layer for repository contracts and use cases
   - presentation layer for state updates
3. Implement API client with safe defaults:
   - timeouts
   - retry/backoff policy where appropriate
   - request/response logging with redaction
4. Add auth handling:
   - token attach/refresh strategy
   - unauthorized flow (`401/403`) and sign-out fallback
5. Add DTO mapping and error normalization:
   - map API payloads to domain entities
   - map transport/server failures to typed domain failures
6. Add tests:
   - unit tests for mapping and repository behavior
   - integration tests for happy/error paths (mock server/client)
7. Validate with analysis and impacted tests.

## Guardrails

- Do not expose secrets/tokens in logs or source files.
- Keep API client concerns in data layer; avoid direct networking in widgets.
- Do not claim API integration is complete without naming changed files and validation evidence.
- In simulation/planning mode, use `planned/not executed` wording.

## Required output

1. API scope and auth model selected.
2. Files changed by layer (presentation/domain/data).
3. Validation commands and results.
4. Error handling and retry strategy summary.
5. Remaining risks/follow-up tasks.

## Required references

- `../../rules/flutter-development-best-practices.mdc`
- `../../rules/dart-effective-dart.mdc`
- `../../rules/flutter-test-best-practices.mdc`
