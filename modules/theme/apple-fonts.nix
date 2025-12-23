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
        # San Francisco Pro (Display and Text)
        sf-pro
        sf-pro-nerd # With Nerd Font symbols for terminal use

        # San Francisco Mono (Monospaced for code)
        sf-mono
        sf-mono-nerd # With Nerd Font symbols

        # San Francisco Compact (Compact variant)
        sf-compact
        sf-compact-nerd # With Nerd Font symbols
      ];
    };

    nixos = {pkgs, ...}: {
      fonts.packages = with inputs.apple-fonts.packages.${pkgs.system}; [
        sf-pro
        sf-pro-nerd
        sf-mono
        sf-mono-nerd
        sf-compact
        sf-compact-nerd
      ];
    };
  };
}
