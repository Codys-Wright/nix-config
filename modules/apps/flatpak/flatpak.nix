# Flatpak support module - Enables flatpak with Flathub
{ FTS, ... }:
{
  FTS.apps._.flatpaks = {
    description = "Flatpak runtime with Flathub";

    nixos = _: {
      services.flatpak.enable = true;
    };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.flatpak ];
      };
  };
}
