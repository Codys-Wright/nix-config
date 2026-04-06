# Desktop parametric aspect
# Includes the default environment, SDDM, and sets the default session.
# Add other environments directly: <FTS.desktop._.environment/kde>
#
# Usage: (FTS.desktop { default = "niri"; })
{
  lib,
  den,
  FTS,
  __findFile,
  ...
}:
{
  FTS.desktop.description = "Desktop environment with SDDM display manager";

  FTS.desktop.__functor =
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
        <FTS.desktop._.environment/niri>
        <FTS.desktop._.environment/gnome>
        <FTS.desktop._.environment/kde>
        <FTS.desktop._.display-manager/sddm>
      ];

      nixos.services.displayManager.defaultSession = lib.mkForce sessionNames.${default};
    };
}
