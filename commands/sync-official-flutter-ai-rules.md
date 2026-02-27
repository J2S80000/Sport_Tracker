---
name: sync-official-flutter-ai-rules
description: Sync official Flutter AI rules from Flutter upstream and select active profile (10k, 4k, 1k).
---

Sync official Flutter AI rules into the plugin repository.

1. Follow `../skills/sync-official-flutter-ai-rules/SKILL.md`.
2. Pick profile by context size:
   - `10k` for maximum guidance depth.
   - `4k` for balanced detail and token usage.
   - `1k` for minimal and fast context.
3. Run `scripts/sync_official_flutter_ai_rules.sh <10k|4k|1k>`.
4. Commit synced files under `rules/official/` and active file `rules/flutter-official-ai-rules.mdc`.
5. Keep plugin policy in `rules/flutter-plugin-policy-priority.mdc` (do not patch synced official content).

