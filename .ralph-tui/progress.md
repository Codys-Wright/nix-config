## Codebase Patterns
- Use small `FTS.*` config aspects for cross-class defaults, then wire them through `den.default.includes` in `modules/aspects/defaults.nix` so behavior is centralized and reusable.

## 2026-02-09 - .flake-c1t.8
- Implemented dedicated `FTS.state-version` and `FTS.hostname` aspects in `modules/config` following the requested vix-style pattern.
- Updated `den.default.includes` to include `<FTS/hostname>` and `<FTS/state-version>`.
- Removed prior stateVersion settings from `modules/defaults.nix` and `modules/dendritic/home.nix` to eliminate duplication.
- Simplified `modules/dendritic/host.nix` by removing old hostname provider logic and leaving it as a placeholder; updated dendritic docs accordingly.
- Files changed: `modules/config/state-version.nix`, `modules/config/hostname.nix`, `modules/aspects/defaults.nix`, `modules/defaults.nix`, `modules/dendritic/home.nix`, `modules/dendritic/host.nix`, `modules/dendritic/README.md`, `.ralph-tui/progress.md`.
- **Learnings:**
  - `den.default.includes` in `modules/aspects/defaults.nix` is the right integration point for global cross-cutting aspects.
  - Dynamic class dispatch via `${host.class}` cleanly avoids duplicated nixos/darwin hostname blocks.
  - State version values were duplicated in both global defaults and dendritic home wiring; centralizing into one aspect prevents drift.
---
