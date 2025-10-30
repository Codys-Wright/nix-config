# Rust development environment aspect
{ ... }:
{
  den.aspects.rust = {
    description = "Rust development environment with cargo tools and toolchain";

    homeManager =
      { pkgs, lib, ... }:
      lib.mkIf pkgs.stdenvNoCC.isDarwin {
        home.packages = with pkgs; [
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

          # Rust toolchain (using rustup by default, can be overridden with fenix)
          rustup
          # Note: To use fenix, add fenix input to flake and use:
          # rust-toolchain = fenix.packages.${pkgs.system}.complete.withComponents [...];
          # rust-analyzer = fenix.packages.${pkgs.system}.rust-analyzer;
        ];

        # Configure rustup/cargo paths
        home.sessionVariables = {
          CARGO_HOME = "$HOME/.cargo";
          RUSTUP_HOME = "$HOME/.rustup";
          RUSTFLAGS = lib.mkDefault "-C target-cpu=native";
        };

        home.sessionPath = [
          "$HOME/.cargo/bin"
        ];
      };
  };
}

