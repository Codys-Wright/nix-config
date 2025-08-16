{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.coding.lang.rust;
in
{
  options.${namespace}.coding.lang.rust = with types; {
    enable = mkBoolOpt false "Enable Rust development environment";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Fenix-provided toolchain and language server
      (pkgs."rust-toolchain")
      (pkgs."rust-analyzer")

      # Toolchain manager
      rustup

      # Common cargo utilities
      cargo-watch
      cargo-edit
      cargo-audit
      cargo-nextest
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

    # Configure rustup/cargo paths
    home.sessionVariables = {
      CARGO_HOME = "$HOME/.cargo";
      RUSTUP_HOME = "$HOME/.rustup";
      RUSTFLAGS = mkDefault "-C target-cpu=native";
    };

    home.sessionPath = [
      "$HOME/.cargo/bin"
    ];
  };
}
