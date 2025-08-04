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
  cfg = config.${namespace}.desktop.primatives.gtk;
in
{
  options.${namespace}.desktop.primatives.gtk = with types; {
    enable = mkBoolOpt false "Enable GTK theming";
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
