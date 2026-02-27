---
name: review-flutter-code
description: Perform risk-focused Flutter code review for correctness, architecture, testing, and maintainability.
---

# Review Flutter Code

Use for PR/diff/code review requests.

## Workflow

1. Review for correctness and behavioral regressions first.
2. Require explicit review scope (PR diff, commit range, or file list) before deep review.
3. Check architecture boundaries and dependency direction.
4. Check state-management misuse and async hazards.
5. Check tests for missing cases and flakiness.
6. Run security audit checks from `../security-audit/SKILL.md` for every review.
7. Include OWASP MASVS-focused checks for mobile risk areas.
8. Check accessibility/localization/performance basics.

## Mandatory security scope (OWASP MASVS-oriented)

- MASVS-ARCH: architecture and trust boundaries.
- MASVS-STORAGE/CRYPTO: sensitive data storage and crypto usage.
- MASVS-AUTH: authentication/session handling weaknesses.
- MASVS-NETWORK: transport security and certificate validation.
- MASVS-PLATFORM: Android/iOS platform integration risks and exported surfaces.
- MASVS-CODE: unsafe code patterns and hardcoded secrets.

## Guardrails

- Do not provide a deep review without explicit target scope (PR diff, range, or file list).
- Tie each finding to concrete code evidence and expected behavioral impact.
- Keep findings prioritized by severity and user risk, not by style preference.
- Distinguish confirmed findings from inferred risks when evidence is partial.
- Do not claim scans/commands were run without output evidence.

## Output format

- Findings first, ordered by severity.
- File references for each finding.
- Brief residual risk/testing gap summary.
- Confidence/assumption note when applicable.

## Required references

- `../security-audit/SKILL.md`
- https://mas.owasp.org/MASVS/
