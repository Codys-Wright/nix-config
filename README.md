# .flake — den-based NixOS/darwin fleet

Declarative configuration for every machine in the fleet: multi-host NixOS,
nix-darwin, and home-manager, composed from reusable **aspects**.

Three frameworks do the heavy lifting. **den** provides the aspect system:
features are declared once under the `fleet` namespace and composed into
complete host/home configs via `includes`. **import-tree** auto-imports every
git-tracked `.nix` file under `modules/`, `hosts/`, and `users/` — there are no
manual import lists. **flake-file** generates `flake.nix` from input
declarations scattered across the modules themselves.

## Critical rules

> - **Never edit `flake.nix`** — it is generated. Edit the owning module and
>   run `nix run .#write-flake` (or `just write-flake`).
> - **`git add` new `.nix` files before building** — import-tree silently
>   ignores untracked files.
> - **No plaintext secrets** — this repo is public. Secrets live in the
>   private nix-secrets repo (sops); see `docs/managing-secrets.md`.
> - **Format before committing** — `just fmt`.

## Quickstart

```bash
git clone <this repo> ~/.flake
cd ~/.flake
just switch          # build + activate the current host (auto-detects hostname)
```

Other everyday commands (full list: `just --list` or the justfile):

```bash
just build            # build current host without activating
just build-host <h>   # build a specific host
just test             # nix flake check
just fmt              # nixfmt-rfc-style everything
just deploy <h>       # remote deploy via deploy-rs
just hosts            # list configured hosts
```

## Layout

| Path | Contents |
|---|---|
| `flake.nix` | **Generated** — never edit |
| `justfile` | Command surface (build/deploy/secrets) |
| `modules/` | All feature aspects, grouped by category (`apps/`, `coding/`, `desktop/`, `hardware/`, `music/`, `nix/`, `selfhost/`, `system/`, …) |
| `hosts/<name>/` | Host declaration, host-specific aspects, `facter.json`, sops config |
| `users/<name>/` | Home declaration, dotfiles, private user aspects |
| `packages/<name>/` | Custom derivations, auto-exposed as `pkgs.<name>` (see `modules/nix/fleet-packages.nix`) |
| `docs/` | Guides and design docs — start at `docs/README.md` |
| `k8s/` | Cluster GitOps (nixidy) |
| `skills/` | Agent skills shipped by this repo |
| `tests/`, `scripts/` | Checks and helper scripts |

## Documentation

- `docs/README.md` — index of all guides
- `docs/den-conventions.md` — how aspects are written in this repo
- `docs/installing-software.md` — the decision tree for adding anything
- `docs/refactor-verification.md` — proving a refactor changed nothing
- `CLAUDE.md` — architecture deep dive (den concepts, context pipeline, angle brackets)
