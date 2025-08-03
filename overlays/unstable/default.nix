{
  channels,
  namespace,
  inputs,
  ...
}:

final: prev: {
  # Add unstable packages channel
  unstable = import inputs.nixpkgs-unstable {
    inherit (final) system;
    config.allowUnfree = true;
  };
} 