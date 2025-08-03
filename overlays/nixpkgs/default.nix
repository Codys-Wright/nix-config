{ inputs, ... }:

final: prev: {
  # Add stable packages (25.05)
  stable = import inputs.nixpkgs-stable {
    inherit (final) system;
    config.allowUnfree = true;
  };

  # Add unstable packages
  unstable = import inputs.nixpkgs-unstable {
    inherit (final) system;
    config.allowUnfree = true;
  };
} 