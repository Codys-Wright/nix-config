{
  channels,
  namespace,
  inputs,
  ...
}:

final: prev: {
  # Add stable packages channel
  stable = import inputs.nixpkgs-stable {
    inherit (final) system;
    config.allowUnfree = true;
  };
} 