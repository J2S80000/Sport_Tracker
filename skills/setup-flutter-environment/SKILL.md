---
name: setup-flutter-environment
description: Prepare a deterministic Flutter development environment with SDK/tooling verification, MCP readiness, and baseline validation commands.
---

# Setup Flutter Environment

Use this skill when a project needs a clean, reproducible Flutter setup before implementation, testing, or release work.

## Workflow

1. Check installed toolchain versions:
   - `flutter --version`
   - `dart --version`
2. Run environment diagnostics:
   - `flutter doctor -v`
3. Resolve blocking setup gaps:
   - Android licenses (`flutter doctor --android-licenses`) when Android is required.
   - Xcode CLI tools/simulator notes when iOS/macOS is required.
4. Verify MCP availability:
   - `dart mcp-server --help`
5. Ensure plugin-level setup files are present and valid:
   - `mcp.json`
   - `.cursor/settings.json` plugin enablement (if required by local workflow).
6. Run repository validation commands when available (for this plugin repo):
   - `./scripts/validate_agents_skills.sh`
   - `./scripts/validate_prompt_semantics.sh`

## Guardrails

- Do not claim setup is complete while `flutter doctor` still has unresolved blockers for requested target platforms.
- Keep setup changes minimal and reversible; avoid unrelated dependency upgrades.
- If a required platform is out of scope (for example iOS on a non-iOS task), report it explicitly instead of forcing changes.
- Do not say `done/completed` without command evidence.

## Required output

1. Detected Flutter/Dart versions.
2. `flutter doctor` summary with unresolved blockers.
3. MCP availability result.
4. Commands executed and pass/fail status.
5. Next actions required from the user (if any manual steps remain).
