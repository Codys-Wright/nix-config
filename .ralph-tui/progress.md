## Codebase Patterns
- Cross-platform host config aspects can share one module function via `let` binding and assign it to both `nixos` and `darwin` to avoid duplicated nix settings.

## 2026-02-09 - .flake-c1t.9
- Implemented a consolidated `nix-settings` aspect in `modules/config/nix-settings.nix` using a `let...in` pattern with one shared function for both `nixos` and `darwin`.
- Folded experimental features into the new aspect and centralized `gc`, `optimise.automatic`, `trusted-users`, and `substituters` under one nix settings module.
- Updated default host aspect wiring to use `<FTS/nix-settings>` and removed the old standalone experimental-features aspect.
- Files changed: `modules/config/nix-settings.nix`, `modules/aspects/defaults.nix`, `modules/nix/experimental-features.nix`, `.ralph-tui/progress.md`.
- **Learnings:**
  - Shared platform behavior fits cleanly in a single function assigned to both `nixos` and `darwin` within an aspect.
  - The defaults router is the correct place to swap aspect references when consolidating cross-cutting config.
  - In this sandbox, Nix checks can fail due daemon socket restrictions, so verification may need to be rerun in a full local environment.
---
