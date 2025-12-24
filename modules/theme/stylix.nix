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
          name = "MacTahoe-dark Cursors";
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
      # Default image for wallpaper/backgrounds (can be overridden)
      # stylix.image = lib.mkDefault ./path/to/wallpaper.jpg;
    };
  };
}
