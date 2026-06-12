{
  inputs,
  den,
  lib,
  ...
}:
{
  # den moved from vic/den to the denful org (vic/den is now just a redirect);
  # matches flake-file's bundled dendritic.nix default. mkForce kept so any
  # future bundled-default change can't silently repoint our den.
  flake-file.inputs.den.url = lib.mkForce "github:denful/den";

  imports = [ inputs.den.flakeModule ];

  flake.den = den;
}
