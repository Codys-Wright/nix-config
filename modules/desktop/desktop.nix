# Desktop facet: niri, GNOME and KDE environments behind SDDM.
#
# The default session is a per-host setting:
#   den.hosts.x86_64-linux.<host>.settings.desktop.session = "gnome";
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
    ];

    nixos =
      { host, ... }:
      {
        services.displayManager.defaultSession = lib.mkForce sessionNames.${host.settings.desktop.session};
      };
  };
}
