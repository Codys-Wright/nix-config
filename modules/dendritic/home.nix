# Parametric provider for home configuration
# Sets home directory and username for home-manager
{
  lib,
  ...
}:
{
  den.aspects.dendritic.provides.home =
    { home, ... }:
    { class, ... }:
    let
      homeDir = if lib.hasSuffix "darwin" home.system then "/Users" else "/home";
    in
    {
      ${class}.home = {
        username = lib.mkDefault home.userName;
        homeDirectory = lib.mkDefault "${homeDir}/${home.userName}";
      };
    };
}
