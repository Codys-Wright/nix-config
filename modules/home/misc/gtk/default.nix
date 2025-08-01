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
  cfg = config.${namespace}.misc.gtk;
in
{
  options.${namespace}.misc.gtk = with types; {
    enable = mkBoolOpt false "Enable gtk";
  };

  config = mkIf cfg.enable {
    gtk = {
      enable = mkDefault true;

      cursorTheme = {
        name = mkDefault "macOS-BigSur";
        package = mkDefault pkgs.apple-cursor;
        size = mkDefault 32; # Affects gtk applications as the name suggests
      };

      iconTheme = {
        name = mkDefault "Papirus-Dark";
        package = mkDefault pkgs.papirus-icon-theme;
      };

      theme = {
        name = mkDefault "Catppuccin-Mocha-Compact-Teal-Dark";
        package = mkDefault (pkgs.catppuccin-gtk.override {
          accents = [ "teal" ];
          size = "compact";
          tweaks = [ "rimless" ];
          variant = "mocha";
        });
      };
    };
  };
}
