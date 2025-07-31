{
  config,
  lib,
  pkgs,
  namespace,
  inputs,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.system.fonts;
in
{
  options.${namespace}.system.fonts = {
    enable = mkBoolOpt false "${namespace}.config.fonts.enable";
    enableAppleEmoji = mkBoolOpt false "Enable Apple Color Emoji font";
  };

  config = mkIf cfg.enable {
    fonts = {
      enableDefaultPackages = true;
      packages = with pkgs; [
        jetbrains-mono
        meslo-lgs-nf
        noto-fonts
        roboto
        corefonts
      ] ++ lib.optional cfg.enableAppleEmoji inputs.apple-emoji-linux.packages.x86_64-linux.default;
      
      # Configure Apple Color Emoji as the emoji font
      fontconfig = mkIf cfg.enableAppleEmoji {
        localConf = ''
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
        '';
      };
    };
  };
}
