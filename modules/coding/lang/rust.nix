# Rust development environment aspect
# Uses rust-overlay for pure and reproducible Rust toolchain packaging
{
  inputs,
  FTS,
  lib,
  ...
}:
{
  # Add rust-overlay as a flake input
  flake-file.inputs.rust-overlay.url = lib.mkDefault "github:oxalica/rust-overlay";
  flake-file.inputs.rust-overlay.inputs.nixpkgs.follows = "nixpkgs";

  FTS.rust = {
    description = "Rust development environment with cargo tools and toolchain using rust-overlay";

    

    homeManager = { pkgs, lib, ... }:
      {
        # Apply the rust-overlay to nixpkgs for this home-manager config
        # This makes rust-bin.* available in pkgs
        nixpkgs.overlays = [ inputs.rust-overlay.overlays.default ];

        home.packages = with pkgs; [
          # Rust toolchain from rust-overlay
          # Uses latest stable Rust with default profile (rustc, cargo, rustfmt, clippy, etc.)
          # This replaces rustup with a pure, reproducible Rust toolchain
          rust-bin.stable.latest.default
          rust-analyzer

          # Common cargo utilities
          cargo-watch
          cargo-edit
          cargo-audit
          # Note: cargo-nextest is currently broken in nixpkgs-unstable
          # cargo-nextest
          cargo-udeps

          # Useful native tooling for building and debugging
          pkg-config
          cmake
          ninja
          gdb
          lldb
          llvmPackages.bintools
          sccache
        ];


      };
  };
}

