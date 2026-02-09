## Codebase Patterns
- `den.default.includes` should stay minimal and delegate behavior to reusable aspects (for example, `FTS.base-host`, `FTS.base-home`, `FTS.nix-settings`) instead of using nested `host.includes`/`home.includes` blocks.

## 2026-02-09 - .flake-c1t.2
- Implemented a vix-style minimal `modules/aspects/defaults.nix` using den provides and small shared aspects.
- Created new shared aspects for host/home defaults and foundational config: `FTS.base-host`, `FTS.base-home`, `FTS.nix-settings`, `FTS.state-version`, and `FTS.hostname`.
- Moved state-version and package-policy defaults out of `modules/defaults.nix` into aspects to keep defaults wiring minimal.
- Files changed:
  - modules/aspects/defaults.nix
  - modules/aspects/base-host.nix
  - modules/aspects/base-home.nix
  - modules/aspects/nix-settings.nix
  - modules/aspects/state-version.nix
  - modules/aspects/hostname.nix
  - modules/defaults.nix
- **Learnings:**
  - The repo has two defaults entry points (`modules/aspects/defaults.nix` and `modules/defaults.nix`), so shared defaults should live in explicit aspects to avoid split configuration.
  - `FTS.<name>` root aspects can be introduced via new files in `modules/aspects/` and referenced immediately via angle brackets.
  - Dynamic host-class wiring works with the `${host.class}` attribute pattern inside parametric aspects.
---
