{
  inputs,
  den,
  lib,
  ...
}:
{
  imports = [ inputs.den.flakeModule ];
  
  den.default.host.includes = [ den.home-manager ];
}