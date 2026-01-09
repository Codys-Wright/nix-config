# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build/Lint/Test Commands

- `just test` - Run `nix flake check` to verify all configurations
- `just fmt` - Format code with nixfmt-rfc-style
- `just build <host>` - Build a specific host configuration
- `just switch <host>` - Build and activate a host configuration
- `just dev` - Enter development shell with all tools

## Code Style

- **Formatter**: nixfmt-rfc-style (2-space indent, braces on same line)
- **Module pattern**: `{ inputs, den, pkgs, FTS, __findFile, ... }:` for imports
- **Aspect syntax**: Use `<FTS/category/subcategory>` angle brackets for aspect references
- **Parametric aspects**: `(FTS.module { option = "value"; })` or `(<FTS/path> { opt = val; })`

## Architecture Overview

This is a modular NixOS flake configuration using **den** (declarative aspect-based system), **flake-parts**, and **import-tree** for automatic module discovery.

### Core Frameworks

1. **den**: Aspect-based configuration where features (aspects) compose into complete systems
2. **import-tree**: Automatically imports all `.nix` files in directories - no manual imports needed
3. **flake-file**: Auto-generates `flake.nix` - edit via `nix run .#write-flake`, not directly

### Directory Structure

- `hosts/<hostname>/` - Host configs with `<hostname>.nix`, `secrets.yaml`, `facter.json`
- `users/<username>/` - User configs with `<username>.nix`, `secrets.yaml`, `dots/` (dotfiles)
- `modules/<category>/` - Reusable aspects organized by category (desktop, system, coding, etc.)
- `packages/` - Custom package definitions
- `scripts/` - Helper bash scripts

### Key Module Categories

| Directory | Purpose |
|-----------|---------|
| `modules/desktop/` | Desktop environments (Hyprland, GNOME, KDE) + bootloaders |
| `modules/system/` | Core system (networking, SSH, disk, fonts) |
| `modules/coding/` | Development tools (editors, shells, terminals, languages) |
| `modules/selfhost/` | Self-hosting services via selfhostblocks |
| `modules/deployment/` | Remote deployment (nixos-anywhere, disko, beacon ISO) |

### Aspect Definition Pattern

```nix
{
  FTS.category._.subcategory = {
    description = "...";
    nixos = { pkgs, ... }: { /* NixOS config */ };
    homeManager = { pkgs, ... }: { /* home-manager config */ };
    includes = [ <FTS/other/aspect> ];
  };
}
```

### Angle Bracket Syntax

- `<FTS/gdm>` resolves to `den.ful.FTS.gdm`
- `(<FTS/disk> { type = "btrfs"; })` for parametric aspects
- `<den/home-manager>` resolves to `den.provides.home-manager`
- Use original syntax for `den.aspects.*` (not angle brackets)

## Secrets Management (SOPS)

- Host secrets: `hosts/<hostname>/secrets.yaml`
- User secrets: `users/<username>/secrets.yaml`
- Edit with `just edit-secrets <name>`
- Never commit `sops.key` or `keys.txt`

## btca Tool

When you need up-to-date information about specific technologies, run:
```bash
btca ask -t <tech> -q "<question>"
```

Available tech: `deploy-rs`, `flake-aspects`, `import-tree`, `flake-file`, `den`, `selfhostblocks`, `skarabox`

## Deployment Commands

- `just deploy <host>` - Deploy via deploy-rs
- `just install <hostname> -i <ip>` - nixos-anywhere installation
- `just beacon` - Build universal bootable ISO
- `just vm <host>` - Test host in QEMU VM

## Naming Conventions

- Hosts: `hosts/<hostname>/<hostname>.nix`
- Users: `users/<username>/<username>.nix`
- Modules: `modules/<category>/<subcategory>/<module>.nix`
- Facets (routers): `modules/<category>/<category>.nix`
