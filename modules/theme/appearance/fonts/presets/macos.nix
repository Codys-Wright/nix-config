# macOS-style Font Preset
# San Francisco font family with appropriate fallbacks
{
  FTS,
  pkgs,
  lib,
  ...
}:
{
  FTS.theme._.fonts._.presets._.macos = {
    description = "macOS-style fonts (San Francisco family)";

    nixos = {
      fonts = {
        packages = with pkgs; [
          (nerdfonts.override { fonts = [ "FiraCode" "JetBrainsMono" ]; })
          noto-fonts
          noto-fonts-emoji
          inter
          # San Francisco fonts would go here if available
        ];

        fontconfig = {
          enable = true;
          defaultFonts = {
            serif = [ "SF Pro Text" "Inter" "Noto Serif" ];
            sansSerif = [ "SF Pro Text" "Inter" "Noto Sans" ];
            monospace = [ "SF Mono" "JetBrainsMono Nerd Font" "FiraCode Nerd Font" ];
            emoji = [ "Noto Color Emoji" ];
          };
        };
      };
    };

    homeManager = {
      # User-level font configuration
      fonts.fontconfig.enable = true;
    };
  };
}

