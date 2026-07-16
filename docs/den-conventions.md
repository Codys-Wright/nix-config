# den conventions in this repo

How aspects are written here. For den's own concepts (classes, context
pipeline, batteries) see CLAUDE.md and the den docs (den.denful.dev).

## Ground rules

- One aspect per file: `modules/<category>/<name>.nix`. import-tree picks it
  up automatically — `git add` it first, or it is invisible.
- Every aspect has a `description`. One factual line. Required.
- Standard module header, listing only what the module uses:
  `{ inputs, den, fleet, __findFile, ... }:`
- `lib.mkDefault` on values hosts/users may override; `lib.mkForce` only for
  invariants. Forgetting `mkForce` on a genuine conflict is an eval error;
  reflexive `mkForce` makes overrides impossible.

## Aspect forms

### Simple aspect

```nix
{ fleet, ... }:
{
  fleet.coding._.cli._.just = {
    description = "Just command runner";
    os = { pkgs, ... }: {                 # os = nixos + darwin
      environment.systemPackages = [ pkgs.just ];
    };
  };
}
```

Class blocks: `nixos`, `darwin`, `homeManager`, plus two shorthands —
`os` (forwarded to nixos and darwin) and `user` (forwarded to
`users.users.<userName>` in user context).

### Facet (repo vocabulary, not den's)

A **facet** is this repo's aggregator convention: per category directory,
one file named after the directory, containing only `description` +
`includes` of the sibling leaves. Hosts/users include the facet; a host
reaching into a leaf directly is a smell.

```nix
# modules/apps/misc/misc.nix
fleet.apps._.misc = {
  description = "Miscellaneous apps - AppImage, Flameshot, LocalSend, Nextcloud";
  includes = [
    fleet.apps._.misc._.appimage
    fleet.apps._.misc._.flameshot
    # ...
  ];
};
```

Facet rules:
- Keep the description's tool list current when adding leaves.
- Cody-only apps stay **out** of shared facets and are included directly in
  `users/cody/cody.nix` (see the header comment in modules/apps/misc/misc.nix).
  Add a leaf to a facet only if every consumer should get it.

### Parametric aspect (`__functor`)

For caller-supplied parameters. The functor returns the result attrset
directly:

```nix
fleet.grub.description = "GRUB boot loader configuration";
fleet.grub.__functor = _self: { uefi ? true, theme ? null, ... }: {
  includes = lib.optional (theme == "minegrub") fleet.grub._.themes._.minegrub;
  nixos = { lib, ... }: {
    boot.loader.grub.enable = true;
    boot.loader.grub.efiSupport = lib.mkForce uefi;
  };
};
```

Call site: `(fleet.grub { uefi = true; })`.

Do **not** add a `{ class, aspect-chain }:` layer unless the body actually
references `class` or `aspect-chain` — the simple form is correct and
preferred.

### Context function

For host/user/home-aware config, use a bare context function — either the
aspect itself or an entry in `includes`:

```nix
fleet.hostname = {
  description = "Set hostname from den host context";
  includes = [
    ({ host, ... }: {
      ${host.class}.networking.hostName = lib.mkDefault (host.hostName or host.name);
    })
  ];
};
```

Context keys: `host`, `user`, `home`, `class`, `aspect-chain`. Den skips a
function silently when a required key is absent in the current stage — pick
the right key (`host` for machine config, `user` for per-user OS config,
`home` for home-manager).

Prefer **named** aspects over sprinkling anonymous lambdas through includes
lists — a named leaf is discoverable and reusable; an inline lambda is not.

## Deprecated — do not copy

- `den.lib.parametric` — deprecated upstream. Use bare context functions as
  above. (CLAUDE.md patterns 4 and 5 predate this and are stale.)
- `den.lib.take.*` / `perHost` — deprecated.
- `mutual-provider` battery — inert; routing is built-in now.

## References: angle brackets vs dotted

- `<fleet.coding/cli>` → `fleet.coding._.cli` — preferred in `includes`
  lists. Requires `__findFile` in the module args.
- `<den/home-manager>` → `den.provides.home-manager` (batteries).
- Dotted paths for named aspects: `den.aspects.cody`, `den.aspects.hm-backup`
  — these are not reachable via angle brackets.
- Private namespace aspects by dotted path: `cody.dots`, `cody.fish`.

## Naming & placement

- Namespaces: `fleet` (shared, exported), `cody` (personal, not exported).
  Declared in `modules/namespace.nix`.
- Host-specific config: `hosts/<host>/<concern>.nix` defining
  `den.aspects.<HOST>-<concern>`, added to the host aspect's `includes`
  (see hosts/THEBATTLESHIP/*.nix: `storage.nix`, `dante-net.nix`, …).
  Do not grow the host file's inline `nixos` block.
- Underscore-prefixed files and directories (`_data/`, `_lib/`,
  `_nvf_modules/`) are invisible to import-tree — use them for plain-Nix
  data, helper functions, and anything imported explicitly.
