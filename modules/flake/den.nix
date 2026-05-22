{
  inputs,
  den,
  lib,
  ...
}:
{
  # mkForce: flake-file's bundled dendritic.nix defaults to github:denful/den
  # at the same priority, causing a conflict. We want the vic/den fork.
  flake-file.inputs.den.url = lib.mkForce "github:vic/den";

  imports = [ inputs.den.flakeModule ];

  flake.den = den;
}
