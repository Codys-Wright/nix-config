# Apple Fonts (San Francisco) from apple.com
# Provides SF Pro, SF Mono, and SF Compact fonts with optional Nerd Font patches
{inputs, ...}: {
  flake-file.inputs = {
    apple-fonts.url = "github:Lyndeno/apple-fonts.nix";
    apple-fonts.inputs.nixpkgs.follows = "nixpkgs";
  };

  FTS.apple-fonts = {
    description = "Apple San Francisco fonts - SF Pro, SF Mono, SF Compact with optional Nerd Font patches";

    homeManager = {pkgs, ...}: {
      home.packages = with inputs.apple-fonts.packages.${pkgs.system}; [
        sf-pro
        sf-mono
        sf-compact
      ];
    };

    nixos = {pkgs, ...}: {
      fonts.packages = with inputs.apple-fonts.packages.${pkgs.system}; [
        sf-pro
        sf-mono
        sf-compact
      ];
    };
  };
}
