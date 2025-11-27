# parametric providers for home
{
  den,
  lib,
  ...
}:
{
  den.aspects.example.provides.home =
    { home }:
    { class, ... }:
    let
      homeDir = if lib.hasSuffix "darwin" home.system then "/Users" else "/home";
    in
    {
      ${class}.home = {
        username = lib.mkDefault home.userName;
        homeDirectory = lib.mkDefault "${homeDir}/${home.userName}";
      };
      # Set stateVersion for NixOS home-manager users
      nixos.home-manager.users.${home.userName}.home.stateVersion = lib.mkDefault "25.11";
    };
}

