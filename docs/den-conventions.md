# den conventions in this repo

How aspects are written here. For den's own concepts (classes, context
pipeline, batteries) see CLAUDE.md and the den docs (den.denful.dev);
the den source's `docs/src/content/docs/explanation/where-config-lands.mdx`
is the key reference.

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

### Where each class key lands

Host scope delivers only `nixos`/`darwin`/`os`; a `homeManager` or `user` key
reached from a host is dropped silently (den `where-config-lands.mdx`).

| Feature picked by | System half | Per-user half |
|---|---|---|
| host (gaming, desktop, hardware) | `nixos` / `os` | `provides.to-users.homeManager` or `provides.to-users.includes` |
| user (apps, coding) | `provides.to-hosts.nixos` / `.os` | `homeManager` |
| one user on one host | — | `den.aspects."cody@THEBATTLESHIP".homeManager` |

Never put an untargeted `nixos` block on an aspect users include — it only
reaches the host through den bug #694. Account fields use the `user` class;
gate NixOS-only fields on `host.class == "nixos"` (the `user` class also routes
into nix-darwin). See `modules/gaming/gaming.nix` (host-picked with
`fleet.gaming._.player` as the user half) and `modules/apps/notes/obsidian.nix`
(user-picked).

Groups: `(<fleet.user/groups> [ "video" ])`; root-equivalent groups through
`(<fleet.user/admin-groups> [ "docker" ])` (only `<fleet.user/admin>` users).
Restricted accounts include `<fleet.user/restricted>`; host features wrap
their per-user half in `(<fleet.user/unless-restricted> …)`.

### Per-host values: settings, not call args

A value that varies per host is an aspect **setting** (modules/den/settings.nix):

```nix
fleet.grub = {
  description = "GRUB boot loader configuration for NixOS";
  settings.theme = lib.mkOption { type = lib.types.nullOr (lib.types.enum [ "minegrub" ]); default = null; };
  includes = [ ({ host, ... }: grubFor host.settings.grub) ];
};
# host entry: den.hosts.x86_64-linux.<h>.settings.grub.theme = "minegrub";
```

The settings path is the fleet path without `_` (`fleet.audio._.pipewire` →
`settings.audio.pipewire`). Declare `settings` on the static attrset, once.
Facts about the host itself (deploy IP, timezone) are den.hosts entry fields
declared in modules/den/schema.nix. Domains/IPs come from
`inputs.nix-secrets.networking.*`.

### Callable aspect (`__functor`)

Only for genuinely multi-instance arguments (a host running several CI
runners). Return a unique `name` so instances stay distinct:

```nix
fleet.ci._.forgejo-runner.__functor = _self: { name ? "battleship", ... }: {
  name = "forgejo-runner(${name})";
  nixos = { ... };
};
```

Do **not** add a `{ class, aspect-chain }:` layer unless the body uses them.

### Context functions and guards

`{ host, ... }:` / `{ user, ... }:` include entries get entity context; den
silently skips them where the key is absent. "Only if the host has/lacks Y"
is a `den.lib.policy.when` guard over `host.hasAspect` (modules/networking/
networking.nix) — never compute `includes` from `hasAspect` (recursion).
Guards reachable from `den.default` must accept `{ host ? null, ... }`
(standalone homes have no host).

Prefer **named** aspects over anonymous lambdas in includes lists.

## Deprecated — do not copy

- `den.lib.parametric`, `den.lib.take.*`, `perHost` — deprecated upstream.
- `mutual-provider` battery — inert; routing is built-in.
- `den.lib.groups`, `fleet.deploy`, `(<fleet.system/disk> { type = …; })`,
  flag-style `(fleet.hardware { nvidia = true; })` — removed from this repo.

## References: angle brackets vs dotted

- `<fleet.coding/cli>` → `fleet.coding._.cli` — preferred in `includes`
  lists. Requires `__findFile` in the module args.
- `<den/define-user>` → `den.batteries.define-user` (canonical battery names
  are `den.batteries.*`; there is no home-manager battery).
- Dotted paths for hosts/users: `den.aspects.cody`, `den.aspects.THEBATTLESHIP`.
- Private namespace aspects by dotted path: `cody.dots`, `cody.fish`.

## Naming & placement

- Namespaces: `fleet` (shared, exported), `cody` (personal, not exported).
  Declared in `modules/den/namespace.nix`. `den.aspects` is only for hosts,
  users and `"user@host"` aspects.
- Den plumbing (defaults, schema, strict, settings) lives in `modules/den/`.
- Machines of one kind share a role: `modules/roles/` (`fleet.roles._.t2-laptop`).
- Host-specific config: `hosts/<host>/<concern>.nix` defining
  `den.aspects.<HOST>-<concern>`, added to the host aspect's `includes`;
  plain data in `hosts/<host>/_data/`. Do not grow the host file's inline
  `nixos` block.
- Underscore-prefixed files and directories (`_data/`, `_lib/`,
  `_nvf_modules/`) are invisible to import-tree — use them for plain-Nix
  data, helper functions, and anything imported explicitly.
