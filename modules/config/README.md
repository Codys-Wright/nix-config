# modules/config — cross-cutting configuration aspects

Aspects many hosts/homes include that don't belong to one category:

| Aspect | File | What |
|---|---|---|
| `fleet.state-version` | `state-version.nix` | nixos / darwin / home-manager state versions (in `den.default`) |
| `fleet.nix-settings` | `nix-settings.nix` | nix daemon settings, substituters, gc (every host via `den.schema.host.includes`) |
| `fleet.user-secrets` | `user-secrets.nix` | per-user sops-nix for home-manager (in `den.default`) |
| `ssh-keys` | `ssh-keys.nix` | fleet SSH public keys as a module argument (`{ ssh-keys, ... }:`) |

Den plumbing (namespace, defaults, schema options, strict mode, aspect
settings, hm-backup, base-host) lives in `modules/den/`. Category-specific
behaviour belongs in its category directory (`modules/coding/`,
`modules/audio/`, …), not here.
