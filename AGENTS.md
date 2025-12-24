# AGENTS.md - Coding Agent Guidelines

## Build/Lint/Test Commands

- `just test` - Run `nix flake check` to verify all configurations
- `just fmt` - Format code with nixfmt-rfc-style
- `just build <host>` - Build a specific host configuration
- `just switch <host>` - Switch to a host configuration
- `just dev` - Enter development shell with all tools

## Code Style

- **Formatter**: nixfmt-rfc-style (2-space indent, braces on same line)
- **Module pattern**: `{ inputs, den, pkgs, FTS, __findFile, ... }:` for imports
- **Aspect syntax**: Use `<FTS/category/subcategory>` angle brackets for aspect
  references
- **Parametric aspects**: `(FTS.module { option = "value"; })` or
  `(<FTS/path> { opt = val; })`

## Naming Conventions

- Hosts: `hosts/<hostname>/<hostname>.nix`
- Users: `users/<username>/<username>.nix`
- Modules: `modules/<category>/<subcategory>/<module>.nix`
- Facets (routers): `modules/<category>/<category>.nix`

## Secrets (SOPS)

- Host secrets: `hosts/<hostname>/secrets.yaml`, User secrets:
  `users/<username>/secrets.yaml`
- Edit with `just edit-secrets <name>`, never commit `sops.key` or `keys.txt`

## btca

When the user says "use btca", use btca before you answer the question. It will
give you up to date information about the technology. Run:

- btca ask -t <tech> -q "<question>"

Available <tech>:

- `deploy-rs` - NixOS deployment tool
- `flake-aspects` - How aspects are structured
- `import-tree` - How files are imported
- `flake-file` - How the flake file is generated
- `den` - How hosts are defined
- `selfhostblocks` - All selfhosting related services
- `skarabox` - Example system deployment for secrets management and deployments
