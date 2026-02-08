## Codebase Patterns

### let...in Pattern for Shared Class Handlers
When nixos/darwin/homeManager blocks share identical logic, extract the handler into a `let` binding and reference it:
```nix
let
  my.category._.aspect = {
    nixos = shared-handler;
    darwin = shared-handler;
    inherit homeManager;
  };
  shared-handler = { pkgs, ... }: { environment.systemPackages = [ ... ]; };
in
{
  FTS.category._.aspect = { description = "..."; } // my.category._.aspect;
}
```

### Drop Module Args When Not Needed
Files that don't reference FTS, inputs, or other module args at the top level can be plain attrsets (`let...in { }`) instead of functions (`{ FTS, ... }: { }`). Class handlers like `nixos = { pkgs, ... }: { ... }` receive their own args.

### inherit vs dotted-path
When using `den.default`, dotted paths like `nixos.nixpkgs.config.allowUnfree = true` conflict with direct assignment `nixos = { ... }`. Use `inherit` to inject shared let-bindings: `nixos.nixpkgs.config = { inherit allowUnfree; };`.

---

## 2026-02-08 - .flake-c1t.6
- Adopted let...in pattern for config-heavy aspects with shared nixos/darwin logic
- Files changed:
  - `modules/nix/search.nix` - Extracted shared nixos/darwin systemPackages + deduplicated shell alias string
  - `modules/nix/npins.nix` - Extracted shared nixos/darwin systemPackages, dropped unused module args
  - `modules/nix/nixpkgs.nix` - Extracted triplicated overlay list into single `overlays` binding
  - `modules/defaults.nix` - Extracted `allowUnfree` and `permittedInsecurePackages` into let bindings with inherit
- **Learnings:**
  - The `{ description = "..."; } // my.namespace` merge pattern keeps FTS namespace clean while logic lives in let bindings
  - `just build voyager` and `just fmt` both fail with a pre-existing selfhostblocks cross-platform error (x86_64-linux on aarch64-darwin), not related to these changes
  - Files parsed and formatted successfully with `nix-instantiate --parse` and `nixfmt` individually
  - Be careful with `git stash` during testing — stash pop can silently fail and revert changes
---
