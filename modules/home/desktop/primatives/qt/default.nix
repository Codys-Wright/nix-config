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
  cfg = config.${namespace}.desktop.primatives.qt;
in
{
  options.${namespace}.desktop.primatives.qt = with types; {
    enable = mkBoolOpt false "Enable Qt theming";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      libsForQt5.qt5ct
      libsForQt5.qtstyleplugin-kvantum
      kdePackages.qtstyleplugin-kvantum
      catppuccin-kvantum
    ];
    qt = {
      enable = mkDefault true;
      platformTheme.name = mkDefault "qtct";
      style = {
        name = mkDefault "Catppuccin-Mocha-Teal";
        package = mkForce (pkgs.catppuccin-kvantum.override {
          accent = "teal";
          variant = "mocha";
        });
      };
    };
    #xdg.configFile = {
    #  "Kvantum/Catppuccin-Mocha-Teal/Catppuccin-Mocha-Teal/Catppuccin-Mocha-Teal.kvconfig".source =
    #    "${pkgs.catppuccin-kvantum}/share/Kvantum/Catppuccin-Mocha-Teal/Catppuccin-Mocha-Teal.kvconfig";
    #  "Kvantum/Catppuccin-Mocha-Teal/Catppuccin-Mocha-Teal/Catppuccin-Mocha-Teal.svg".source =
    #    "${pkgs.catppuccin-kvantum}/share/Kvantum/Catppuccin-Mocha-Teal/Catpuccin-Mocha-Teal.svg";
    #};
  };
}
