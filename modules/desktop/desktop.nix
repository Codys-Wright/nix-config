# Desktop facet: niri, GNOME and KDE environments behind SDDM.
#
# The default session is a per-host setting; under niri the shell is Loft:
#   den.hosts.x86_64-linux.<host>.settings.desktop.session = "gnome";
# "loft" is KDE Plasma with Loft's shell in place of plasmashell (Loft's
# programs.loft.plasma); the plain "Plasma" and "niri" entries stay.
{
  lib,
  fleet,
  __findFile,
  ...
}:
let
  sessionNames = {
    niri = "niri";
    gnome = "gnome";
    kde = "plasma";
    loft = "loft";
  };
in
{
  fleet.desktop = {
    description = "Desktop environment with SDDM display manager";

    settings.session = lib.mkOption {
      type = lib.types.enum (lib.attrNames sessionNames);
      default = "niri";
      description = "Default display-manager session";
    };

    includes = [
      <fleet.desktop._.environment/niri>
      <fleet.desktop._.environment/gnome>
      <fleet.desktop._.environment/kde>
      <fleet.desktop._.display-manager/sddm>
      <fleet.desktop/loft>
    ];

    nixos =
      { host, ... }:
      {
        services.displayManager.defaultSession = lib.mkForce sessionNames.${host.settings.desktop.session};
      };
  };
}
