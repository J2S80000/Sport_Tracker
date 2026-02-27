---
name: sync-official-flutter-ai-rules
description: Synchronize official Flutter AI rules profiles and set the active profile used by this plugin.
---

# Sync Official Flutter AI Rules

Use this workflow to keep plugin guidance aligned with upstream Flutter AI rules.

## Workflow

1. Choose target profile:
   - `10k`: full guidance, best for larger context windows.
   - `4k`: balanced default profile.
   - `1k`: minimal profile for constrained contexts.
2. Run:
   - `scripts/sync_official_flutter_ai_rules.sh <10k|4k|1k>`
3. Verify synced outputs:
   - `rules/official/flutter-ai-rules-10k.mdc`
   - `rules/official/flutter-ai-rules-4k.mdc`
   - `rules/official/flutter-ai-rules-1k.mdc`
   - `rules/flutter-official-ai-rules.mdc` (active profile copy)
4. Keep plugin-specific policy in `rules/flutter-plugin-policy-priority.mdc`.
5. Review diffs and ensure no local manual edits were mixed into official synced files.
6. Update changelog if behavior/guidance changed materially.

## Guardrails

- Do not hand-edit generated files under `rules/official/`.
- Keep active file `rules/flutter-official-ai-rules.mdc` aligned with chosen profile.
- Do not enforce plugin policy by patching official content after sync.
- Use `rules/flutter-plugin-policy-priority.mdc` for higher-priority policy and conflict resolution.
- Prefer `4k` unless there is a clear reason to switch to `10k` or `1k`.
- Do not claim sync completed unless command output is available.
- In simulation/planning mode, status must be `PENDING` and include `not executed` note.

## Required output

1. Selected profile and rationale.
2. Files synced/updated.
3. Diff summary for active rule + policy routing layer.
4. Follow-up actions (if manual review is needed).

## Official upstream sources

- `https://raw.githubusercontent.com/flutter/flutter/main/docs/rules/rules_10k.md`
- `https://raw.githubusercontent.com/flutter/flutter/main/docs/rules/rules_4k.md`
- `https://raw.githubusercontent.com/flutter/flutter/main/docs/rules/rules_1k.md`
