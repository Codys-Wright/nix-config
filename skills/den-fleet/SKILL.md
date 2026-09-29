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
    nixos = { pkgs, ... }: { ... };        # or homeManager / darwin / os / user
  };
}
```

## Which class key? (host scope DROPS homeManager and user)

- **Host picks it** (service, hardware, desktop, gaming) → `nixos`/`os` for the
  system half; per-user half in `provides.to-users.homeManager` (or
  `provides.to-users.includes = [ (<fleet.user/unless-restricted> <…/user-half>) ]`
  so restricted accounts skip it).
- **User picks it** (app, CLI, editor) → `homeManager`; any OS bits in
  `provides.to-hosts.nixos` / `.os`. Never an untargeted `nixos` block on a
  user-included aspect (den bug #694).
- **Account field** (shell, password, description) → `user` class. NixOS-only
  fields (`extraGroups`, `hashedPassword`) must be gated on
  `host.class == "nixos"` — the user class also routes into nix-darwin.
- **Groups** → `(<fleet.user/groups> [ … ])`; root-equivalent ones (docker,
  libvirtd, podman) → `(<fleet.user/admin-groups> [ … ])`.
- **One user on one host** → `den.aspects."cody@THEBATTLESHIP".homeManager`.
- **Linux-only package in a home** → `homeManager = { lib, pkgs, ... }: lib.mkIf pkgs.stdenv.isLinux { … }`
  (mkIf, never optionalAttrs).

## Per-host values

- **Varies per host?** → aspect `settings` (modules/den/settings.nix):
  `settings.foo = lib.mkOption { … }` on the static aspect, read
  `host.settings.<path without _>.foo` in `nixos = { host, ... }: …`, set
  `den.hosts.<sys>.<host>.settings.<path>.foo = …`.
- **Fact about the host** (deploy IP, timezone) → den.hosts entry
  (`deployment.ip`, `timeZone`); new keys are declared in modules/den/schema.nix.
- **Domain / LAN IP** → `inputs.nix-secrets.networking.*`, never a literal.
- **Include X only if the host has/lacks Y** → `den.lib.policy.when ({ host ? null, ... }: host != null && host.hasAspect …) { includes = [ X ]; }`.
- Callable aspects (`__functor = _self: args: { name = "x(${…})"; … }`) only
  for real multi-instance args (e.g. CI runners); never den.lib.parametric.

## Wire it in

1. Add the aspect to its category facet's `includes` (e.g. modules/coding/cli/cli.nix).
   The facet is what hosts/users include.
2. Machines of one kind share a role (`modules/roles/`, e.g. `<fleet.roles/t2-laptop>`).
   Host-specific config goes in `hosts/<host>/<concern>.nix` as
   `den.aspects.<HOST>-<concern>`; plain data in `hosts/<host>/_data/`.
3. Angle brackets for references: `<fleet.coding/cli>`; dotted `den.aspects.*` for
   hosts/users. `_`-prefixed files/dirs are invisible to import-tree.

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

Darwin configs skip the registry and must stay byte-identical (modulo
HOME_MANAGER_BACKUP_EXT); check standalone homeConfigurations too.
See docs/refactor-verification.md for the full workflow and script.
