# NixOS Flake Structure

This document outlines the structure of this NixOS flake configuration.

## Top-Level Files

- `flake.nix`: The main entry point for the flake. It defines the outputs, such as NixOS configurations, home-manager configurations, and packages.
- `flake.lock`: The lock file that pins the versions of all the inputs to the flake.
- `README.md`: The main README file for the project.
- `justfile`: Contains `just` commands for common tasks.

## Directories

- `deployments/`: Contains Terraform deployments for NixOS.
- `homes/`: Contains home-manager configurations for different users and hosts.
- `lib/`: Contains custom Nix libraries and helper functions.
- `modules/`: Contains NixOS and home-manager modules.
  - `modules/nixos/`: Modules specific to NixOS configurations.
  - `modules/home/`: Modules specific to home-manager configurations.
  - `modules/darwin/`: Modules specific to macOS (darwin) systems.
- `packages/`: Contains custom packages that are not in nixpkgs.
- `scripts/`: Contains shell scripts for various tasks.
- `shells/`: Contains development shells.
- `systems/`: Contains the main NixOS configurations for each host.
- `templates/`: Contains templates for new modules, packages, etc.

## Usage

To build and switch to a new generation of a system, run the following command:

```bash
nixos-rebuild switch --flake .#<hostname>
```

Where `<hostname>` is the name of the host you want to build (e.g., `THEBATTLESHIP`).

To build a home-manager configuration, run the following command:

```bash
home-manager switch --flake .#<user>@<hostname>
```
