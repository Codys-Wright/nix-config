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
  cfg = config.${namespace}.app.files.dolphin;
in
{
  options.${namespace}.app.files.dolphin = with types; {
    enable = mkBoolOpt false "Enable Dolphin file manager";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs.kdePackages; [
      ark
      dolphin
      dolphin-plugins
    ];
  };
}
