{ config, pkgs, inputs, ... }:

{
  imports = [
    inputs.stylix.homeManagerModules.stylix
  ];

  # Stylix theming for KDE
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml";
    
    image = ../Windows-11-PRO.png;
    
    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 24;
    };
    
    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font Mono";
      };
      sansSerif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans";
      };
      serif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };
      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };
    };
    
    polarity = "dark";

    targets = {
      kde = {
        enable = true;
        decorations = "org.kde.breeze";
        useWallpaper = true;
      };
    };
  };

  # Home Manager configuration
  home = {
    username = "cody";
    homeDirectory = "/home/cody";
    stateVersion = "24.05";
  };

  # Programs
  programs = {
    home-manager.enable = true;
  };
} 