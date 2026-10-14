# Desktop facet: niri, GNOME and KDE environments behind SDDM.
#
# The default session and, under niri, the desktop shell are per-host settings:
#   den.hosts.x86_64-linux.<host>.settings.desktop.session = "gnome";
#   den.hosts.x86_64-linux.<host>.settings.desktop.shell = "studio";
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

    settings.shell = lib.mkOption {
      type = lib.types.enum [
        "noctalia"
        "studio"
      ];
      default = "noctalia";
      description = "Desktop shell under niri: Noctalia, or studio-linux (github:Codys-Wright/studio-linux)";
    };

    includes = [
      <fleet.desktop._.environment/niri>
      <fleet.desktop._.environment/gnome>
      <fleet.desktop._.environment/kde>
      <fleet.desktop._.display-manager/sddm>
      <fleet.desktop/studio>
    ];

    nixos =
      { host, ... }:
      {
        services.displayManager.defaultSession = lib.mkForce sessionNames.${host.settings.desktop.session};
      };
  };
}
