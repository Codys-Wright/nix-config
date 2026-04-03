{
  inputs,
  den,
  lib,
  ...
}:
{
  flake-file.inputs.den.url = lib.mkDefault "github:vic/den";

  imports = [ inputs.den.flakeModule ];

  # den's built-in ctx pipeline handles home-manager integration.
  # hm-host-forward (in home-manager.nix) forwards host homeManager blocks to users.
}
