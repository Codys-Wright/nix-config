{
  options,
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.polkit-gnome;
in
{
  options.${namespace}.services.polkit-gnome = with types; {
    enable = mkBoolOpt false "Enable gnome polkit";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      polkit_gnome
      libsecret
    ];

    programs.seahorse.enable = true;

    security = {
      pam.services.gdm.enableGnomeKeyring = true;
      polkit.enable = true;
      #pam.services.ags = {};
    };

    services.gnome.gnome-keyring.enable = true;
  };
}
