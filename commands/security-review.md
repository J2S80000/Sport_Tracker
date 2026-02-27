---
name: security-review
description: Run security-focused review with secret scanning and prioritized findings for Flutter/Dart repositories.
---

Run a security audit and secrets scan (Claude-style `/security-review` workflow).

1. Follow `../skills/security-audit/SKILL.md`.
2. Analyze pending changes (diff-aware first, then expand to related context when needed).
3. Start with secrets scanning and credential leak checks.
4. Continue with code-level security review for risky patterns.
5. Apply false-positive filtering so output stays actionable.
6. Return findings first, prioritized by severity and exploitability.
7. Include concrete remediation steps and verification commands.
8. If target scope (diff/branch/files) is missing, stop and ask for explicit scope.
9. If scanners are unavailable, report that explicitly and continue with manual checks.

