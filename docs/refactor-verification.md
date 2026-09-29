# Verifying a pure refactor

"Pure refactor" = a source reorganization that must not change what any host
builds. drvPath comparison + nix-diff proves it. Two wrinkles make naive
comparison misleading: the registry pin and list ordering.

## Why drvPaths always change on Linux

`modules/nix/nix-registry.nix` pins **all** flake inputs — including `self` —
into home-manager's `nix.registry` (Linux only). Any source change, however
trivial, changes `self`, which ripples `registry.json` into every Linux
config. So Linux drvPaths are never stable across commits; equality is not
the test.

**The test:** nix-diff between old and new toplevel drvs must show *only*
the registry.json cascade:

```
activate → etc → system-units → unit-home-manager-<user>
  → home-manager-generation → home-manager-files → registry.json → source
```

Anything outside that chain means the refactor was not pure.

## Workflow

Capture baseline drvPaths on the old rev:

```bash
for h in $(nix eval .#nixosConfigurations --apply builtins.attrNames --json | jq -r '.[]'); do
  printf '%s ' "$h"; nix eval --raw ".#nixosConfigurations.\"$h\".config.system.build.toplevel.drvPath"; echo
done
```

Apply the refactor (git add everything — import-tree), re-run the loop, then
for each host:

```bash
nix run nixpkgs#nix-diff -- <old.drv> <new.drv>
```

Pass = every diff is exactly the registry.json cascade above.

## Darwin configs

Darwin skips the registry (the pin is `lib.mkIf pkgs.stdenv.isLinux`), so
darwin drvPaths must be **byte-identical** across a pure refactor — with one
known exception: `HOME_MANAGER_BACKUP_EXT=bak-<self.lastModified>` from
`modules/den/hm-backup.nix` shifts at each commit. If that variable is
the only diff, the refactor is pure. Compare uncommitted working-tree state
against the old rev to sidestep it entirely.

## The list-reorder caveat

Splitting a **list-typed option** across modules — `environment.systemPackages`,
`home.packages`, `systemd.tmpfiles.rules`, … — reorders the merged list.
Same contents, different order → different drv hash, and nix-diff shows a
scary-looking package diff that is actually just permutation.

Verify those with a sorted-set comparison instead:

```bash
nix eval .#nixosConfigurations.<h>.config.environment.systemPackages \
  --apply 'ps: builtins.sort builtins.lessThan (map (p: p.name or "?") ps)'
```

Run against old and new and diff the output. Reference the old rev without
checking it out:

```bash
nix eval "git+file:///home/cody/.flake?rev=<old>#nixosConfigurations.<h>.config.environment.systemPackages" \
  --apply 'ps: builtins.sort builtins.lessThan (map (p: p.name or "?") ps)'
```

Equal sorted sets + otherwise-clean nix-diff (registry cascade plus the
reordered list's file) = pure.

## Cover every output

Linux hosts aren't the only configs a refactor touches:

- **Darwin** (`darwinConfigurations.*`) — byte-identical modulo
  `HOME_MANAGER_BACKUP_EXT` (from `modules/den/hm-backup.nix`).
- **Standalone homes** (`homeConfigurations.*.activationPackage`) — these see
  `den.default` in a scope with no host, so a guard or include that assumes
  `host` can break only here.
- **outrider** (WSL) is a normal `nixosConfigurations` entry.

Capture all of them in one pass with `tryEval` per entry so one failure
doesn't hide the rest:

```bash
nix eval --json .#nixosConfigurations --apply 'cs: builtins.mapAttrs (n: c:
  let r = builtins.tryEval c.config.system.build.toplevel.drvPath;
  in if r.success then r.value else "EVAL-FAIL") cs'
# same for darwinConfigurations (…toplevel.drvPath) and
# homeConfigurations (c.activationPackage.drvPath)
```

Condense nix-diff to the names of differing input derivations and drop the
known cascade (`registry.json`, `home-manager-files`,
`home-manager-generation`, `unit-home-manager-*.service`, `system-units`,
`etc`, `activate`, `user-units`, `home-manager-path`, `source`); anything
left, or a "set of input derivation names do not match", needs a look.
`activation-script` / `*-fish-completions` / `system-path` changes with equal
sorted package sets are list reorders.

## `user`-class and platform gotchas

- The den `user` class routes into the host's OS class — including
  nix-darwin, which has no `extraGroups` / `hashedPassword`. Writes of
  NixOS-only fields are gated on `host.class == "nixos"`; a darwin config
  that suddenly fails eval usually means an ungated write.
- The `user` class forwards an evaluated value, so `mkForce` inside it loses
  its priority — compare `users.users.<u>.extraGroups` explicitly after
  touching group wiring.

## Checklist

1. `git add` all new files (untracked = invisible to import-tree — a "pure"
   diff may just mean the new module never evaluated).
2. Baseline drvPath loop on the old rev.
3. Refactor; re-run loop.
4. nix-diff each changed host: registry.json cascade only.
5. Darwin: byte-identical (modulo HOME_MANAGER_BACKUP_EXT); standalone
   homes: registry cascade only.
6. Split a list option? Sorted-set eval comparison old vs new.
