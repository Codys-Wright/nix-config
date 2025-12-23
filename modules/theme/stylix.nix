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
        fonts = lib.mkDefault {
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
            package = pkgs.noto-fonts-emoji;
            name = "Noto Color Emoji";
          };
        };
      };
      # Default image for wallpaper/backgrounds (can be overridden)
      # stylix.image = lib.mkDefault ./path/to/wallpaper.jpg;
    };
  };
}
