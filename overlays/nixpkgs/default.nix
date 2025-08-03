{
  channels,
  namespace,
  inputs,
  ...
}:

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

  # You can add more versions here as needed
  # "23.11" = import inputs.nixpkgs-23.11 {
  #   inherit (final) system;
  #   config.allowUnfree = true;
  # };
} 