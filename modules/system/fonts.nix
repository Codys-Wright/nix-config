{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption mkOption types;
  cfg = config.den.aspects.fonts;
in
{
  options.den.aspects.fonts = {
    enable = mkEnableOption "fonts configuration";

    enableAppleEmoji = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Apple Color Emoji font";
    };

    extraFonts = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "Additional fonts to install";
    };
  };

  config = mkIf cfg.enable {
    fonts = {
      enableDefaultPackages = true;
      packages = with pkgs; [
        # Programming fonts
        jetbrains-mono
        fira-code
        fira-code-symbols

        # System fonts
        noto-fonts
        noto-fonts-cjk
        noto-fonts-emoji
        roboto

        # Powerline fonts
        meslo-lgs-nf

        # Microsoft fonts for compatibility
        corefonts
      ]
      ++ lib.optionals cfg.enableAppleEmoji [
        inputs.apple-emoji-linux.packages.${pkgs.system}.default
      ]
      ++ cfg.extraFonts;

      # Font configuration
      fontconfig = {
        defaultFonts = {
          serif = [ "Noto Serif" ];
          sansSerif = [ "Noto Sans" ];
          monospace = [ "JetBrains Mono" ];
          emoji = if cfg.enableAppleEmoji then [ "Apple Color Emoji" ] else [ "Noto Color Emoji" ];
        };

        # Apple Color Emoji configuration
        localConf = mkIf cfg.enableAppleEmoji ''
          <?xml version="1.0"?>
          <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
          <fontconfig>
            <!-- Apple Color Emoji font configuration -->
            <match target="pattern">
              <test qual="any" name="family">
                <string>Apple Color Emoji</string>
              </test>
              <edit name="family" mode="assign" binding="same">
                <string>Apple Color Emoji</string>
              </edit>
            </match>

            <!-- Set Apple Color Emoji as the emoji font -->
            <match target="pattern">
              <test name="family">
                <string>emoji</string>
              </test>
              <edit name="family" mode="prepend" binding="same">
                <string>Apple Color Emoji</string>
              </edit>
            </match>

            <!-- Fallback for emoji characters -->
            <match target="pattern">
              <test name="lang">
                <string>und-zsye</string>
              </test>
              <edit name="family" mode="prepend" binding="same">
                <string>Apple Color Emoji</string>
              </edit>
            </match>
          </fontconfig>
        '';
      };
    };
  };
}
