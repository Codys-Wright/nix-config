{
  inputs,
  den,
  lib,
  ...
}:
{
  flake-file.inputs.den.url = lib.mkDefault "github:vic/den";

  imports = [ inputs.den.flakeModule ];

  den.default.host.includes = [ den._.home-manager ];
}
