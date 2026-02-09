## Codebase Patterns
- Colocate flake input declarations with the module that consumes them (for example, declare `flake-file.inputs.home-manager` in `modules/flake/home-manager.nix` when a `homeManager` aspect reads from `inputs'.home-manager`).
- When a home-manager class aspect needs flake inputs, include `den._.inputs'` (and usually `den._.self'`) in `den.default.includes` so `inputs'` is available in `homeManager = { ... }` arguments.

## 2026-02-09 - .flake-c1t.10
- Implemented vix-style home-manager colocation by moving `flake-file.inputs.home-manager` into `modules/flake/home-manager.nix` and removing the standalone `modules/nix/home-manager.nix` declaration.
- Added `den.aspects.hm.homeManager` to install the home-manager CLI in `home.packages` via `inputs'.home-manager.packages.${pkgs.stdenv.hostPlatform.system}.default`.
- Updated defaults to include `den.aspects.hm`, `den._.inputs'`, and `den._.self'`, and switched home-manager includes to `den._.home-manager` shorthand.
- Files changed: `modules/flake/home-manager.nix`, `modules/aspects/defaults.nix`, `modules/flake/den.nix`, `modules/nix/home-manager.nix` (deleted)
- **Learnings:**
  - The repo’s default den include chain is defined in `modules/aspects/defaults.nix`; adding globally-required aspects there is the lowest-friction way to mirror vix patterns.
  - `den._.inputs'` is needed when aspects consume flake inputs inside class modules (like `homeManager`).
---
