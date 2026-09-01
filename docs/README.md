# docs/ index

## Getting started

- [den-conventions.md](den-conventions.md) — the repo's den style guide: aspect forms, facets, naming, angle brackets, deprecations.
- [installing-software.md](installing-software.md) — decision tree for adding any tool/app/service: nixpkgs aspect, inline flake input, or `packages/` derivation.
- [angle-brackets-guide.md](angle-brackets-guide.md) — how `<fleet/...>` syntax resolves and when to use it vs dotted paths.
- [refactor-verification.md](refactor-verification.md) — proving a pure refactor via drvPath + nix-diff (registry.json cascade, darwin byte-identity, list-reorder caveat).

## Hosts & users

- [add-new-host.md](add-new-host.md) — adding a NixOS host to the flake.
- [add-new-user.md](add-new-user.md) — adding a user/home to NixOS or darwin.
- [add-a-cluster-node.md](add-a-cluster-node.md) — turning a NixOS machine into an opt-in k3s cluster node.
- [t2linux-macbook-install.md](t2linux-macbook-install.md) — installing NixOS on Intel MacBooks with the Apple T2 chip.

## Secrets & deployment

- [managing-secrets.md](managing-secrets.md) — SOPS secret management with the central nix-secrets repo.
- [editing-secrets.md](editing-secrets.md) — quick commands for editing sops files (`just edit-secrets`, then `just update-secrets`).
- [deployment.md](deployment.md) — VM testing, fresh installs (nixos-anywhere/beacon), and deploy-rs pushes.

## Design docs

- [cluster-design.md](cluster-design.md) — fleet k3s cluster architecture and phases.
- [desktop-design.md](desktop-design.md) — desktop workflow, workspace layout, keybind philosophy.
- [niri.md](niri.md) — niri scrollable-tiling compositor configuration.
- [migration-inventory.md](migration-inventory.md) — wave 3+4 migration inventory (operational facts).
- [jellyfin-setup.md](jellyfin-setup.md) — Jellyfin media library setup.
- [jellyfin-auth-setup.md](jellyfin-auth-setup.md) — Jellyfin authentication wiring.

## Audio studio

- [thebattleship-audio.md](thebattleship-audio.md) — the whole THEBATTLESHIP audio stack: PTP → Dante (Inferno) → ALSA → PipeWire → virtual sinks.
- [pipewire-per-user-migration.md](pipewire-per-user-migration.md) — migrating PipeWire from system-wide to per-user.

## Troubleshooting

- [audio-system-issues.md](audio-system-issues.md) — resolved Inferno/Dante issues on THEBATTLESHIP (kept as reference).
- [sddm-no-greeter-incident.md](sddm-no-greeter-incident.md) — SDDM wedges when its last DRM output vanishes; plus the statime-inferno SETSCHEDULER loop in SDDM sessions.
