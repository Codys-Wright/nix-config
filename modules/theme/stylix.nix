# Stylix - System-wide styling using base16
# Automatically styles GTK, Qt, terminals, editors, and more
# NOTE: Only configure in nixos, home-manager integration is automatic via nixos
{inputs, ...}: {
  flake-file.inputs = {
    stylix.url = "github:danth/stylix";
    stylix.inputs.nixpkgs.follows = "nixpkgs";
  };

  FTS.stylix = {
    description = "Stylix - System-wide theming using base16 color schemes";

    nixos = {
      config,
      pkgs,
      lib,
      ...
    }: {
      imports = [
        inputs.stylix.nixosModules.stylix
      ];

      # Use Apple San Francisco fonts if available
      stylix = {
        enable = true;
        autoEnable = false;
        base16Scheme = import ./_assets/stylix/ayu-dark/default.nix;
        image = null;
        polarity = "dark";

        cursor = {
          name = "MacTahoe-dark-cursors";
          package = pkgs.callPackage ../../packages/mactahoe/cursor-theme.nix {};
          size = 24;
        };

        icons = {
          enable = true;
          dark = "MacTahoe";
          light = "MacTahoe";
          package = pkgs.callPackage ../../packages/mactahoe/icon-theme.nix {};
        };

        fonts = {
          serif = {
            package = inputs.apple-fonts.packages.${pkgs.system}.sf-pro-nerd;
            name = "SFProDisplay Nerd Font";
          };
          sansSerif = {
            package = inputs.apple-fonts.packages.${pkgs.system}.sf-pro-nerd;
            name = "SFProDisplay Nerd Font";
          };
          monospace = {
            package = inputs.apple-fonts.packages.${pkgs.system}.sf-mono-nerd;
            name = "SFMono Nerd Font";
          };
          emoji = {
            package = pkgs.noto-fonts-color-emoji;
            name = "Noto Color Emoji";
          };
        };
      };
      # Enable Qt theming via Stylix (NixOS level)
      stylix.targets.qt.enable = true;
    };

    homeManager = { pkgs, lib, ... }: {
      # KDE theming is handled by the MacTahoe KDE theme aspect (whitesur.nix)
      # Stylix KDE target is disabled because it creates its own look-and-feel
      # that conflicts with the MacTahoe look-and-feel package
      stylix.targets.kde.enable = false;

      # Enable Qt app theming via Stylix (HM level)
      stylix.targets.qt.enable = true;
    };
  };
}
