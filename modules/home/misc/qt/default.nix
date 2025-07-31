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
  cfg = config.${namespace}.misc.qt;
in
{
  options.${namespace}.misc.qt = with types; {
    enable = mkBoolOpt false "Enable qt theme";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      libsForQt5.qt5ct
      libsForQt5.qtstyleplugin-kvantum
      kdePackages.qtstyleplugin-kvantum
      catppuccin-kvantum
    ];
    qt = {
      enable = true;
      platformTheme.name = "qtct";
      style = {
        name = "Catppuccin-Mocha-Teal";
        package = pkgs.catppuccin-kvantum.override {
          accent = "teal";
          variant = "mocha";
        };
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
