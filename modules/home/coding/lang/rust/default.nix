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
    useFenix = mkBoolOpt true "Use the Fenix overlay toolchain instead of rustup";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; (
      [
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
      ]
      ++ lib.optionals cfg.useFenix [
        (pkgs."rust-toolchain")
        (pkgs."rust-analyzer")
      ]
      ++ lib.optionals (!cfg.useFenix) [
        rustup
      ]
    );

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
