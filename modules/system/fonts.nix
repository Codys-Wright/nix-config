{ fleet, ... }:
let
  # Shared by NixOS and nix-darwin (fonts.packages exists on both).
  fontPackages =
    pkgs: with pkgs; [
      # Programming fonts
      jetbrains-mono
      fira-code
      fira-code-symbols

      # System fonts
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      roboto

      # Powerline fonts
      meslo-lgs-nf
    ];
in
{
  # Including the aspect is what enables it — no enable option.
  fleet.fonts = {
    description = "Fonts configuration for both NixOS and Darwin";

    os =
      { pkgs, ... }:
      {
        fonts.packages = fontPackages pkgs;
      };

    nixos =
      { pkgs, lib, ... }:
      {
        fonts = {
          enableDefaultPackages = true;
          # Microsoft fonts for compatibility (unfree; Linux documents only).
          packages = [ pkgs.corefonts ];

          # mkDefault: stylix, where present, owns the default families.
          fontconfig.defaultFonts = lib.mapAttrs (_: lib.mkDefault) {
            serif = [ "Noto Serif" ];
            sansSerif = [ "Noto Sans" ];
            monospace = [ "JetBrains Mono" ];
            emoji = [ "Noto Color Emoji" ];
          };
        };
      };
  };
}
