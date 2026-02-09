## Codebase Patterns
- Prefer den batteries for foundational user wiring: use `<den/define-user>` in `den.default.includes`, and compose user-level behavior with `<den/primary-user>` plus `(<den/user-shell> "fish")` directly in user aspects.

## 2026-02-09 - .flake-c1t.1
- Replaced dendritic default wiring with den batteries by switching `modules/aspects/defaults.nix` includes from custom dendritic user/home/host/routes providers to `<den/define-user>` and a minimal `<FTS/hostname>` aspect.
- Added `modules/aspects/hostname.nix` to provide a simple host-name mapping from den host context (vix-style hostname aspect).
- Migrated user aspects to den batteries: replaced `<FTS.user/admin>` with `<den/primary-user>` and replaced `(<FTS.user/shell> { ... })` with `(<den/user-shell> "fish")` in `users/cody/cody.nix`, `users/starcommand/starcommand.nix`, `users/guest/guest.nix`, and the aggregate user facet in `modules/user/user.nix`.
- Updated `modules/dendritic/routes.nix` to a legacy compatibility no-op since default dependency routing for user/home is now handled by den batteries.
- Updated `modules/dendritic/README.md` to reflect the migration and current defaults.
- Files changed:
  - modules/aspects/defaults.nix
  - modules/aspects/hostname.nix
  - modules/user/user.nix
  - users/cody/cody.nix
  - users/starcommand/starcommand.nix
  - users/guest/guest.nix
  - modules/dendritic/routes.nix
  - modules/dendritic/README.md
- **Learnings:**
  - The current codebase wires base host/user/home behavior from `modules/aspects/defaults.nix`; changing that include list is the cleanest migration point away from custom dendritic providers.
  - User aspects in `users/*/*.nix` are the effective integration point for admin and shell batteries, so replacing includes there avoids broad refactors.
  - In this environment, `just fmt`/`just build` can fail due Nix daemon sandbox restrictions; direct `nixfmt` on touched Nix files is still feasible for local formatting validation.
---
