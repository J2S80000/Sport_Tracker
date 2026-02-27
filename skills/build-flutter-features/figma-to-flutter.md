# Figma to Flutter

Use when the task includes Figma URLs/node IDs or explicit visual-fidelity requirements.

## Steps

1. Pull design context via Figma MCP (frames, constraints, typography, color styles, spacing, assets).
2. Build Flutter layout hierarchy to match structure, not pixel hacks.
3. Extract reusable widgets for repeated design blocks.
4. Preserve spacing, typography scale, and interaction states.
5. Keep responsive behavior for common breakpoints.
6. Run Dart MCP analysis after implementation.
7. Add widget tests for key states and actions.

## Quality bar

- Prefer semantic widgets and accessible structure.
- Keep hardcoded magic values minimal.
- Centralize styles in theme/tokens when possible.
- Ensure UI remains maintainable after first implementation.
