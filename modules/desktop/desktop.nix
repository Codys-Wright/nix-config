# Desktop parametric aspect
# Includes the default environment, SDDM, and sets the default session.
# Add other environments directly: <fleet.desktop._.environment/kde>
#
# Usage: (fleet.desktop { default = "niri"; })
{
  lib,
  den,
  fleet,
  __findFile,
  ...
}:
{
  fleet.desktop.description = "Desktop environment with SDDM display manager";

  fleet.desktop.__functor =
    _self:
    { default, ... }:
    let
      sessionNames = {
        niri = "niri";
        gnome = "gnome";
        kde = "plasma";
      };
    in
    den.lib.parametric {
      includes = [
        <fleet.desktop._.environment/niri>
        <fleet.desktop._.environment/gnome>
        <fleet.desktop._.environment/kde>
        <fleet.desktop._.display-manager/sddm>
      ];

      # Forward desktop homeManager blocks to all users on this host.
      # Without this, homeManager config (niri config.kdl, noctalia colors,
      # GTK themes, etc.) is silently dropped in the host-only context.
      provides.to-users.includes = [
        <fleet.desktop._.environment/niri>
        <fleet.desktop._.environment/gnome>
        <fleet.desktop._.environment/kde>
      ];

      nixos.services.displayManager.defaultSession = lib.mkForce sessionNames.${default};
    };
}
