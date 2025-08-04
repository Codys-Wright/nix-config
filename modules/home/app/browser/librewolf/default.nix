{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.app.browser.librewolf;
in
{
  options.${namespace}.app.browser.librewolf = {
    enable = mkBoolOpt false "Enable LibreWolf browser";
  };

  config = mkIf cfg.enable {
    programs.librewolf = {
      enable = true;
    };
  };
}
