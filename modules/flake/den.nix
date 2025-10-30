{
  inputs,
  den,
  lib,
  ...
}:
{
  den.default.host.includes = [ den.home-manager ];
}