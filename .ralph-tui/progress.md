## Codebase Patterns
- User-level reusable parametric behavior should live in the `FTS.user._.*` namespace and use angle-bracket parametric construction: `<den.lib.parametric> { ... }`.
- Legacy `den.provides.*` user/password helpers should be replaced with namespace aspects and only kept as explicit aliases when compatibility is required.

## [2026-02-09] - .flake-c1t.7
- Migrated user shell/password/terminal parametric definitions to angle-bracket syntax with `<den.lib.parametric>`.
- Removed legacy custom `den.provides.user`, `den.provides.password`, and `den.provides.user-shell` implementations by moving logic to `FTS.user` namespace and a compatibility alias.
- Consolidated `users/carter/carter.nix` to a self-contained user aspect using shared `FTS.user/*` includes (admin/autologin/shell) and removed bespoke `provides.*` blocks.
- Files changed:
  - `modules/user/shell.nix`
  - `modules/system/password.nix`
  - `modules/system/user.nix`
  - `modules/system/config.nix`
  - `modules/coding/shell/user-shell.nix`
  - `modules/coding/terminal/user-terminal.nix`
  - `users/carter/carter.nix`
  - `.ralph-tui/progress.md`
- **Learnings:**
  - The repo already has `FTS.user` modules for user composition, so replacing duplicated per-user `provides.*` blocks keeps user files cleaner and more consistent.
  - Nix daemon-backed checks (`just fmt`, `just build`) can be blocked in this sandbox; direct parse checks (`nix-instantiate --parse`) and `nixfmt` are viable local validation fallbacks.
---
