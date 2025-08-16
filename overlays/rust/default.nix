{ inputs, channels, namespace, ... }:

final: prev: {
  # Expose the Fenix package set for this system
  fenix = inputs.fenix.packages.${prev.system};

  # Convenient toolchain providing common components from Fenix
  rust-toolchain = inputs.fenix.packages.${prev.system}.complete.withComponents [
    "cargo"
    "clippy"
    "rust-src"
    "rustc"
    "rustfmt"
  ];

  # Nightly rust-analyzer from Fenix
  rust-analyzer = inputs.fenix.packages.${prev.system}.rust-analyzer;
  rust-analyzer-nightly = inputs.fenix.packages.${prev.system}.rust-analyzer;
} 