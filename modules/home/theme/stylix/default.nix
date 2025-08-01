{
  options,
  config,
  lib,
  pkgs,
  inputs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.theme.stylix;
in
{
  options.${namespace}.theme.stylix = with types; {
    enable = mkBoolOpt false "Enable stylix";
    autoEnable = mkBoolOpt true "Auto-enable stylix targets";
          base16Scheme = mkOption {
        description = "Base16 scheme path";
        type = types.path;
        default = ../../base16/catppuccin/custom.yaml;
      };
      image = mkOption {
        description = "Wallpaper image path";
        type = types.path;
        default = ../../wallpapers/sports.png;
      };
  };

  imports = [ inputs.stylix.homeModules.stylix ];

  config = mkIf cfg.enable {
    stylix = {
      enable = true;
      autoEnable = cfg.autoEnable;
      base16Scheme = cfg.base16Scheme;
      image = cfg.image;
      
      cursor = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Original-Ice";
        size = 24;
      };

      fonts = {
        monospace = {
          package = pkgs.nerd-fonts.jetbrains-mono;
          name = "JetBrainsMono Nerd Font Mono";
        };
        sansSerif = {
          package = inputs.apple-fonts.packages.${pkgs.system}.sf-pro-nerd;
          name = "SFProDisplay Nerd Font";
        };
        serif = {
          package = inputs.apple-fonts.packages.${pkgs.system}.sf-pro-nerd;
          name = "SFProDisplay Nerd Font";
        };
        emoji = {
          package = pkgs.noto-fonts-emoji;
          name = "Noto Color Emoji";
        };
        sizes = {
          applications = 13;
          desktop = 13;
          popups = 13;
          terminal = 13;
        };
      };

      iconTheme = {
        enable = true;
        package = pkgs.papirus-icon-theme;
        light = "Papirus-Light";
        dark = "Papirus-Dark";
      };

      polarity = "dark";
      targets = {
        kitty.enable = false;
        waybar.enable = false;
        hyprlock.enable = false;
        neovim.enable = false;
        librewolf = {
          enable = true;
          profileNames = [ "default" ];
        };
        zen-browser = {
          enable = true;
          profileNames = [ "default" ];
        };
      };
    };
  };
}
