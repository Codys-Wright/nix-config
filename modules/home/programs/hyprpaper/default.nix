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
  cfg = config.${namespace}.programs.hyprpaper;
in
{
  options.${namespace}.programs.hyprpaper = with types; {
    enable = mkBoolOpt false "Enable programs.hyprpaper";
  };

  config = mkIf cfg.enable {
    services.hyprpaper = {
      enable = true;
      settings = {
        ipc = "on";
        splash = false;
        splash_offset = 2.0;
      };
    };
  };
}
