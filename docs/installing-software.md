# Installing software

Everything on this fleet is installed declaratively through den aspects.
Ad-hoc installs (`nix profile install`, `nix-env -i`, `npm i -g`, `pipx`,
`cargo install`) are always wrong here — they bypass the flake and vanish on
the next rebuild.

## Decision tree

### 1. Package exists in nixpkgs

Write (or extend) an aspect that adds `pkgs.<name>`:

- host-wide tool → `environment.systemPackages` in a `nixos`/`os` block
- user tool → `home.packages` in a `homeManager` block

```nix
# modules/coding/cli/<name>.nix
{ fleet, ... }:
{
  fleet.coding._.cli._.<name> = {
    description = "<one factual line>";
    homeManager = { pkgs, ... }: { home.packages = [ pkgs.<name> ]; };
  };
}
```

### 2. Upstream ships its own flake

Declare the input **inline in the aspect module** — this is the blessed
dendritic idiom. `modules/flake/dendritic.nix` holds only core inputs
(nixpkgs, den, home-manager, …); feature inputs live next to the feature.
See `modules/coding/cli/herdr.nix` for the canonical example:

```nix
{ fleet, inputs, lib, ... }:
{
  flake-file.inputs.<name>.url = lib.mkDefault "github:owner/repo/vX.Y.Z";
  flake-file.inputs.<name>.inputs.nixpkgs.follows = "nixpkgs";

  fleet.<category>._.<name> = {
    description = "...";
    homeManager = { pkgs, ... }: {
      home.packages = [
        inputs.<name>.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };
  };
}
```

- Pin a release tag, not a branch.
- After adding/changing an input: `nix run .#write-flake` to regenerate
  `flake.nix`, then `git add flake.nix flake.lock` alongside the module.
- If the tool ships an agent skill (SKILL.md), install it pinned to the
  same input so it always describes the installed binary:

```nix
home.file.".claude/skills/<skill>/SKILL.md".source = "${inputs.<name>}/SKILL.md";
```

(see herdr.nix and hunk.nix for the full pattern).

### 3. Needs a custom derivation

Create `packages/<name>/package.nix` in callPackage style. The
`fleet-packages` overlay (`modules/nix/fleet-packages.nix`) auto-discovers
it — no wiring needed for the common case:

- becomes `pkgs.<name>` in all three classes (nixos, darwin, homeManager)
- becomes a flake output `packages.x86_64-linux.<name>` (Linux only —
  forcing linux-only packages on darwin aborts in callPackage)

Rules:

- Set `meta.platforms`.
- **Name collides with a nixpkgs attr?** Add it to the `collides` list in
  fleet-packages.nix → exposed as `pkgs.fleet-<name>`. Never shadow nixpkgs
  — that silently changes module defaults like `services.sunshine.package`.
  Current collisions: davinci-resolve, inferno, melonloader-installer,
  sunshine, vcv-rack.
- **Needs args from a flake input** (custom toolchain, mkWindowsApp, …)?
  Add them to `extraArgs` in fleet-packages.nix, guarded with
  `lib.optionalAttrs (input ? ${system})` (see the floe / axe-edit-iii
  entries).
- **Multiple packages in one dir** (no single package.nix): wire them
  explicitly in the overlay with flattened names, like `mactahoe-gtk-theme`
  and `tiagolr-time12`.

Then write a normal aspect (form 1) referencing `pkgs.<name>` (or
`pkgs.fleet-<name>`).

## Wire it in

1. Add the leaf to its category **facet**'s `includes`
   (e.g. `modules/coding/cli/cli.nix`) and update the facet description's
   tool list. The facet is what hosts/users include; direct leaf references
   from hosts are a smell.
2. Cody-only tools skip the shared facet and are included directly in
   `users/cody/cody.nix` (see modules/apps/misc/misc.nix header).
3. Host-specific config goes in `hosts/<host>/<concern>.nix` as
   `den.aspects.<HOST>-<concern>`, added to the host's `includes` — never
   grow the host file's inline `nixos` block.

## The non-negotiable loop

```bash
git add <every new .nix file>   # FIRST — import-tree ignores untracked files
nix run .#write-flake           # only if you added/changed a flake input
just fmt
just build                      # or: just build-host <host>
```

- NEVER edit `flake.nix` by hand — it is generated.
- After `just edit-secrets`: `just update-secrets`, or hosts keep building
  with the old values.
