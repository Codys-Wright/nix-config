# Flatpak support module - Enables flatpak with Flathub
{ FTS, ... }:
{
  FTS.apps._.flatpaks = {
    description = "Flatpak runtime with Flathub";

    nixos =
      { pkgs, ... }:
      {
        services.flatpak.enable = true;

        environment.systemPackages = with pkgs; [
          flatpak
        ];
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.flatpak ];
      };
  };
}
