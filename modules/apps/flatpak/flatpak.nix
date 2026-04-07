# Flatpak support module - Enables flatpak with Flathub
{ fleet, ... }:
{
  fleet.apps._.flatpaks = {
    description = "Flatpak runtime with Flathub repository";

    nixos = _: {
      services.flatpak.enable = true;

      # Add Flathub remote on activation
      system.activationScripts.flathub = ''
        ${"/run/current-system/sw/bin/flatpak"} remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
      '';
    };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.flatpak ];
      };
  };
}
