{
  options,
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.programs.lazygit;
  transparentButtons = mkBoolOpt false "${namespace}.programs.lazygit.trasparentButtons";
  accent = "#${config.lib.stylix.colors.base0D}";
  muted = "#${config.lib.stylix.colors.base03}";
in
{
  options.${namespace}.programs.lazygit = with types; {
    enable = mkBoolOpt false "Enable programs.lazygit";
  };

  config = mkIf cfg.enable {
    programs.lazygit = {
      enable = true;
      settings = lib.mkForce {
        gui = {
          theme = {
            activeBorderColor = [
              accent
              "bold"
            ];
            inactiveBorderColor = [ muted ];
          };
          showListFooter = false;
          showRandomTip = false;
          showCommandLog = false;
          showBottomLine = false;
          nerdFontsVersion = "3";
        };
      };
    };
  };
}
