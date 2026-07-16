---
name: den-fleet
description: The only correct way to install, package, or configure software in the ~/.flake den-based NixOS fleet. Use whenever adding a tool/app/service to a host or user, packaging something not in nixpkgs, adding a flake input, or editing this repo's modules — before running any ad-hoc install command (nix profile install, npm i -g, cargo install are all wrong here).
---

# den-fleet

Everything on this fleet is installed declaratively through den aspects in ~/.flake.
Ad-hoc installs (`nix profile install`, `nix-env -i`, `npm i -g`, `pipx`, `cargo install`)
are always wrong — they bypass the flake and vanish on the next rebuild.

## The decision tree

1. **Package exists in nixpkgs?** → write/extend an aspect that adds `pkgs.<name>`
   to `environment.systemPackages` (host tool) or `home.packages` (user tool).
2. **Upstream ships its own flake?** → add a flake input INLINE in the aspect module
   (the dendritic idiom — NOT in modules/flake/dendritic.nix, which is core inputs only):
   ```nix
   flake-file.inputs.<name>.url = lib.mkDefault "github:owner/repo/vX.Y.Z";
   flake-file.inputs.<name>.inputs.nixpkgs.follows = "nixpkgs";
   ```
   Consume via `inputs.<name>.packages.${pkgs.stdenv.hostPlatform.system}.default`.
   Pin a release tag, not a branch. If the tool ships an agent skill (SKILL.md),
   install it alongside the binary:
   ```nix
   home.file.".claude/skills/<skill>/SKILL.md".source = "${inputs.<name>}/path/to/SKILL.md";
   ```
   (see modules/coding/cli/herdr.nix and hunk.nix for the full pattern).
3. **Needs a custom derivation?** → create `packages/<name>/package.nix`
   (callPackage-style). The `fleet-packages` overlay (modules/nix/fleet-packages.nix)
   auto-discovers it: it becomes `pkgs.<name>` everywhere AND a flake output.
   - Set `meta.platforms`.
   - If the name collides with a nixpkgs attr, add it to the `collides` list in
     fleet-packages.nix → exposed as `pkgs.fleet-<name>` (never shadow nixpkgs).
   - Needs args from a flake input? Add them to `extraArgs` in fleet-packages.nix,
     guarded with `lib.optionalAttrs (input ? ${system})`.

## Writing the aspect

One aspect per file: `modules/<category>/<name>.nix`

```nix
{ fleet, ... }:
{
  fleet.<category>._.<name> = {
    description = "One factual line — REQUIRED";
    nixos = { pkgs, ... }: { ... };        # or homeManager / darwin / os
  };
}
```

- `os` = nixos+darwin shorthand; `user` = users.users.<name> shorthand.
- `lib.mkDefault` on values hosts may override; `lib.mkForce` only for invariants.
- Parametric aspect (caller args): `fleet.x._.y.__functor = _self: { args... }: { ... };`
  with a sibling `.description`. Do NOT add a `{ class, aspect-chain }:` layer
  unless the body actually uses those args.
- Context aspect: a bare function `{ host, ... }: { ... }` or
  `{ description; includes = [ ({ user, ... }: ...) ]; }`. Never den.lib.parametric
  (deprecated upstream).

## Wire it in

1. Add the aspect to its category facet's `includes` (e.g. modules/coding/cli/cli.nix).
   The facet is what hosts/users include; leaves referenced directly are a smell.
2. Host-specific config goes in `hosts/<host>/<concern>.nix` as
   `den.aspects.<HOST>-<concern>` added to the host's includes — never grow the
   host file's inline nixos block.
3. Angle brackets for references: `<fleet.coding/cli>`; dotted `den.aspects.*` for
   named aspects. Underscore-prefixed files/dirs (`_data/`, `_lib/`) are invisible
   to import-tree — use them for plain-Nix data and helpers.

## The non-negotiable loop

```bash
git add <every new .nix file>   # FIRST — import-tree ignores untracked files
nix run .#write-flake           # only if you added/changed a flake input
just fmt
just build                      # or: just build-host <host>
```

- NEVER edit flake.nix by hand (generated).
- After `just edit-secrets`: `just update-secrets` or hosts keep the old values.

## Verifying a pure refactor

Registry pins self into every Linux config, so drvPaths always change with any
source edit. Proof of purity = nix-diff shows only the registry.json cascade:

```bash
nix eval --raw .#nixosConfigurations.<h>.config.system.build.toplevel.drvPath  # before + after
nix run nixpkgs#nix-diff -- <old.drv> <new.drv>   # only registry.json may differ
```

Darwin configs skip the registry and must stay byte-identical.
See docs/refactor-verification.md for the full workflow and script.
